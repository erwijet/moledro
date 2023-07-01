use std::{collections::HashMap, sync::Mutex};

use actix_web::{
    dev::RequestHead,
    get,
    web::{self, Query},
    HttpResponse, Responder,
};
use firestore_db_and_auth::documents;
use serde::{Deserialize, Serialize};
use serde_json::json;

use crate::AppState;

#[derive(Debug, Deserialize, Clone)]
struct NamedUrl {
    name: String,
    #[serde(rename = "url")]
    _url: String,
}

#[derive(Debug, Deserialize, Clone)]
struct OpenLibraryBookDataCovers {
    large: String,
}

#[derive(Debug, Deserialize, Clone)]
struct OpenLibraryBookDataIdentifiers {
    lccn: Option<Vec<String>>, // library of congress control number
}

#[derive(Debug, Deserialize, Clone)]
struct OpenLibraryBookDataResponse {
    title: String,
    authors: Vec<NamedUrl>,
    identifiers: Option<OpenLibraryBookDataIdentifiers>,
    cover: OpenLibraryBookDataCovers,
    subjects: Option<Vec<NamedUrl>>,
    #[serde(rename = "key")]
    _key: String,
    #[serde(rename = "url")]
    _url: String,
}

#[derive(Deserialize)]
struct IsbnSearchQuery {
    q: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct IsbnResolvedQuery {
    title: String,
    author: String,
    image: String,
    subjects: Vec<String>,
}

impl From<OpenLibraryBookDataResponse> for IsbnResolvedQuery {
    fn from(value: OpenLibraryBookDataResponse) -> Self {
        Self {
            title: value.title,
            author: value
                .authors
                .first()
                .map(|named_url| named_url.name.clone())
                .unwrap_or("unknown".into()),
            image: value.cover.large.into(),
            subjects: value
                .subjects
                .map(|vec| vec.iter().map(|named_url| named_url.name.clone()).collect())
                .unwrap_or(vec![]),
        }
    }
}

#[derive(Debug, Deserialize)]
struct LibraryOfCongressQueryResultItem {
    subject: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct LibraryOfCongressQueryResultSearch {
    hits: u16,
}

#[derive(Debug, Deserialize)]
struct LibraryOfCongressQueryResult {
    search: LibraryOfCongressQueryResultSearch,
    results: Vec<LibraryOfCongressQueryResultItem>,
}

#[derive(Debug, Serialize, Deserialize)]
struct IsbnQueryResult {
    cached: bool,
    result: IsbnResolvedQuery,
}

async fn query_openlibrary(isbn: &str) -> Option<OpenLibraryBookDataResponse> {
    let mut res: HashMap<String, OpenLibraryBookDataResponse> = reqwest::get(format!(
        "https://openlibrary.org/api/books?bibkeys=ISBN:{}&format=json&jscmd=data",
        isbn
    ))
    .await
    .ok()?
    .json()
    .await
    .ok()?;

    res.remove(&format!("ISBN:{}", isbn).to_owned())
}

async fn query_library_of_congress_by_lccn(lccn: &str) -> Option<LibraryOfCongressQueryResult> {
    reqwest::get(format!("https://www.loc.gov/search/?q={}&fo=json", lccn))
        .await
        .ok()?
        .json()
        .await
        .ok()?
}

#[derive(Serialize)]
struct NormalizeSubjectsOpenAiRequestBody {
    model: String,
    prompt: String,
    temperature: u32,
    max_tokens: u32,
    top_p: u32,
    frequency_penalty: u32,
    presence_penalty: u32,
}

impl From<String> for NormalizeSubjectsOpenAiRequestBody {
    fn from(value: String) -> Self {
        Self {
            model: "text-davinci-003".into(),
            prompt: value,
            temperature: 0,
            max_tokens: 100,
            top_p: 1,
            frequency_penalty: 0,
            presence_penalty: 0,
        }
    }
}

#[derive(Deserialize)]
struct NormalizeSubjectsOpenAiResponseChoice {
    text: String,
}

#[derive(Deserialize)]
struct NormalizeSubjectsOpenAiResponse {
    choices: Vec<NormalizeSubjectsOpenAiResponseChoice>,
}

// async fn normalize_subjects(subjects: &Vec<String>) -> Vec<String> {
//     let prompt = serde_json::to_string(&NormalizeSubjectsOpenAiRequestBody::from(format!("Normalize the given book subjects for an english audiance. If any subject is more than 4 words, summarize it. Seperate with semi-colons.\nBook Subjects: ```{}```\nNormalized Subjects:", subjects.join("\n")))).unwrap();

//     let res: NormalizeSubjectsOpenAiResponse = reqwest::Client::new()
//         .post("https://api.openai.com/v1/completions")
//         .bearer_auth(std::env::var("OPENAI_API_KEY").unwrap())
//         .header("Content-Type", "application/json")
//         .body(prompt)
//         .send()
//         .await
//         .unwrap()
//         .json()
//         .await
//         .unwrap();

//     println!("----------");
//     println!("input: {}", subjects.join("\n"));
//     println!("output: {}", res.choices.first().unwrap().text);

//     res.choices
//         .first()
//         .unwrap()
//         .text
//         .split(";")
//         .map(|kwd| {
//             kwd.chars()
//                 .filter(|c| c.is_alphanumeric() || c.is_whitespace())
//                 .collect::<String>()
//                 .to_lowercase()
//                 .trim()
//                 .into()
//         })
//         .filter(|s: &String| !s.is_empty())
//         .collect()
// }

#[get("/isbn/search")]
async fn search(query: Query<IsbnSearchQuery>, data: web::Data<AppState>) -> impl Responder {
    let IsbnSearchQuery { q } = &*query;
    let session = data.session.lock().unwrap();

    // check for cached result

    if let Ok(res) = documents::read::<IsbnResolvedQuery>(&*session, "isbn_query_cache", q) {
        return HttpResponse::Ok().json(json!({ "ok": true, "cached": true, "result": res }));
    }

    // attempt to query openlibrary

    if let Some(ol_res) = query_openlibrary(q).await {
        let mut res: IsbnResolvedQuery = ol_res.clone().into();

        // if an LCCN is present, then try to resolve subjects via loc.gov

        if let Some(lccn) = ol_res
            .identifiers
            .and_then(|x| x.lccn)
            .and_then(|lccns| lccns.first().cloned())
        {
            if let Some(loc_res) = query_library_of_congress_by_lccn(&lccn).await {
                if loc_res.search.hits != 0 && !loc_res.results.first().unwrap().subject.is_empty()
                {
                    res.subjects = loc_res.results.first().unwrap().subject.clone()
                }
            }
        }

        // cache the response

        if let Err(err) = documents::write(
            &*session,
            "isbn_query_cache",
            Some(q),
            &res,
            documents::WriteOptions::default(),
        ) {
            return HttpResponse::InternalServerError().json(json!({
                "ok": false,
                "result": format!("{:#?}", err),
                "when": "attempting a cache write for a successful openlibrary query"
            }));
        }

        return HttpResponse::Ok().json(json!({ "ok": true, "cached": false, "result": res }));
    }

    return HttpResponse::NotFound()
        .json(json!({ "ok": false, "cached": false, "result": "not found", "when": "attempting to query openlibrary" }));
}
