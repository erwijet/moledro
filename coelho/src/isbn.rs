use std::{borrow::Borrow, fmt::Debug};

use actix_web::{get, web, HttpResponse, HttpResponseBuilder, Responder};
use firestore_db_and_auth::documents;
use serde::{Deserialize, Serialize};
use serde_json::json;
use soup::{NodeExt, QueryBuilderExt, Soup};
use tap::{Pipe, Tap};

use crate::AppState;

macro_rules! try_option {
    ($e:expr) => {
        (|| -> Option<_> { Some($e) })()
    };
}

macro_rules! load_soup {
    ($($arg:tt)*) => {
        Soup::new(&reqwest::get(format!($($arg)*)).await?.text().await?)
    };
}

macro_rules! guard {
    (let $i:pat = try? $e:expr, else |$else_bound:ident| $handle:block $(; $($rest:tt)*)?) => {
        let $i = match $e {
            Ok(val) => val,
            Err($else_bound) => {
                $handle
            }
        };
        $(guard! { $($rest)* } )?
    };

    (let $i:pat = $e:expr, else $handle:block $(; $($rest:tt)*)?) => {
        let $i = match $e {
            Some(val) => val,
            None => {
                $handle
            }
        };
        $(guard! { $($rest)* } )?
    };
}

trait WithErr<T, E> {
    fn with_err(&mut self, err: E, when: &str) -> T;
}

impl<E: Debug> WithErr<HttpResponse, E> for HttpResponseBuilder {
    fn with_err(&mut self, err: E, when: &str) -> HttpResponse {
        self.json(json!({
            "ok": false,
            "result": format!("{:#?}", err),
            "when": when
        }))
    }
}

#[derive(Deserialize)]
struct IsbnSearchQuery {
    q: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct OclcClassification {
    ddc: String,
    fast_subjects: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
struct IsbnResolvedQuery {
    title: String,
    isbn: String,
    author: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    image: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    classification: Option<OclcClassification>,
}

fn scrape_oclc_classification(soup: &Soup) -> Option<OclcClassification> {
    let ddc = try_option!(soup
        .tag("tbody")
        .find()?
        .tag("tr")
        .find_all()
        .nth(1)?
        .tag("td")
        .find_all()
        .nth(1)?
        .text());

    let fast_subjects = try_option!(soup
        .attr("id", "subheadtbl")
        .find()?
        .tag("tbody")
        .find()?
        .tag("tr")
        .find_all()
        .map(|row| row.tag("td").find().unwrap().text())
        .collect::<Vec<_>>());

    if let (Some(ddc), Some(fast_subjects)) = (ddc, fast_subjects) {
        return Some(OclcClassification { ddc, fast_subjects });
    }

    None
}

async fn query_oclc(isbn: &str) -> Result<Option<OclcClassification>, reqwest::Error> {
    let soup = load_soup!(
        "http://classify.oclc.org/classify2/ClassifyDemo?search-standnum-txt={}&startRec=0",
        isbn
    );

    // if only one result is found, then we should be able to scrape it right away

    if let Some(classification) = scrape_oclc_classification(&soup) {
        return Ok(Some(classification));
    }

    // if we can't, try to navigate to the first link and try again

    guard! {
        let link = try_option!(soup
            .tag("tbody")
            .find()?
            .tag("tr")
            .find()?
            .class("title")
            .find()?
            .tag("a")
            .find()?
            .attrs()
            .get("href")?
            .clone()), else { return Ok(None) }
    }

    let soup = load_soup!("http://classify.oclc.org{}", link);

    Ok(scrape_oclc_classification(&soup))
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct GoogleBooksQueryResult {
    total_items: u8,
    #[serde(skip_serializing_if = "Option::is_none")]
    items: Option<Vec<GoogleBookQueryResultItem>>,
}

#[derive(Debug, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct GoogleBookQueryResultItem {
    volume_info: GoogleBookQueryResultItemVolumeInfo,
}

#[derive(Debug, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct GoogleBookQueryResultItemVolumeInfo {
    title: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    authors: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    preview_link: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    image_links: Option<GoogleBookQueryResultItemImageLinks>,
}

#[derive(Debug, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct GoogleBookQueryResultItemImageLinks {
    thumbnail: String,
}

#[derive(Debug, Deserialize)]
struct BasicBookInfo {
    title: String,
    author: String,
    image: Option<String>,
}

async fn query_googlebooks(isbn: &str) -> Result<Option<BasicBookInfo>, reqwest::Error> {
    let result: GoogleBooksQueryResult = reqwest::get(format!(
        "https://www.googleapis.com/books/v1/volumes?q=isbn:{}",
        isbn
    ))
    .await?
    .json()
    .await?;

    if result.total_items == 0 {
        return Ok(None);
    }

    let GoogleBookQueryResultItemVolumeInfo {
        title,
        authors,
        preview_link,
        image_links,
    } = result.items.unwrap().first().unwrap().volume_info.clone();

    Ok(Some(BasicBookInfo {
        title,
        author: authors
            .unwrap_or(vec!["Unknown".into()])
            .iter()
            .map(|raw| {
                if raw.contains(",") || !raw.contains(" ") {
                    return raw.to_owned(); // no change
                }

                raw.split(" ")
                    .map(Into::into)
                    .collect::<Vec<String>>()
                    .pipe_as_mut(|vec: &mut Vec<String>| {
                        vec.pop()
                            .unwrap()
                            .tap(|last| vec.insert(0, last.to_owned() + ","));
                        vec.join(" ")
                    })
            })
            .map(Into::into)
            .collect::<Vec<String>>()
            .join("; "),
        image: preview_link.and_then(|link| {
            if link.contains("frontcover") {
                Some(format!("{}&img=1", link))
            } else {
                image_links.map(|links| links.thumbnail)
            }
        }).map(|link| link.replace("http", "https")),
    }))
}

#[get("/isbn/search")]
async fn search(query: web::Query<IsbnSearchQuery>, data: web::Data<AppState>) -> impl Responder {
    let IsbnSearchQuery { q } = &*query;

    // note: we have to copy the memory here to avoid https://github.com/davidgraeff/firestore-db-and-auth-rs/issues/30
    let session = data.session.borrow().to_owned();

    // check for cached result

    if let Ok(res) = documents::read::<IsbnResolvedQuery>(&*session, "isbn_query_cache", q) {
        return HttpResponse::Ok().json(json!({ "ok": true, "cached": true, "result": res }));
    }

    let book_info = query_googlebooks(&q).await.unwrap();

    guard! {

        // let book_info = try? query_googlebooks(&q).await, else |err| {
        //     return HttpResponse::InternalServerError()
        //         .with_err(err, &*format!("attempting to query google books api for 'ISBN:{}'", q))
        // };

        let BasicBookInfo { title, author, image } = book_info, else {
            return HttpResponse::NotFound()
                .with_err("not found", &*format!("attempting to query google books api for 'ISBN:{}'", q))
        };

        // attempt to query classification information

        let classification = try? query_oclc(&q).await, else |err| {
            return HttpResponse::InternalServerError()
                .with_err(err, "attempting to query oclc.org for work classification information")
        }
    };

    let resolution = IsbnResolvedQuery {
        title,
        author,
        image,
        classification,
        isbn: q.to_owned(),
    };

    // write this resolution to the cache collection

    if let Err(err) = documents::write(
        &*session,
        "isbn_query_cache",
        Some(q),
        &resolution,
        documents::WriteOptions::default(),
    ) {
        return HttpResponse::InternalServerError()
            .with_err(err, "attempting to write resolution to query cache");
    }

    HttpResponse::Ok().json(json!({ "ok": true, "cached": false, "result": resolution }))
}
