use std::fmt::Debug;

use actix_web::{get, web, HttpResponse, HttpResponseBuilder, Responder};
use firestore_db_and_auth::documents;
use serde::{Deserialize, Serialize};
use serde_json::json;
use soup::{NodeExt, QueryBuilderExt, Soup};
use tap::Pipe;

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

#[derive(Debug)]
struct AddAllQueryResult {
    title: String,
    author: String,
    image: Option<String>,
}

async fn query_addall(isbn: &str) -> Result<Option<AddAllQueryResult>, reqwest::Error> {
    let soup = load_soup!(
        "https://www.addall.com/New/NewSearch.cgi?query={}&type=ISBN",
        isbn
    );

    let title = try_option!(soup.class("ntitle").find()?.text());
    let author = try_option!(soup
        .class("nauthor")
        .find()?
        .text()
        .split("by")
        .nth(1)?
        .trim()
        .to_owned());

    let image = try_option!(soup
        .class("nimg")
        .find()?
        .tag("img")
        .find()?
        .attrs()
        .get("src")?
        .to_owned()
        .pipe(|img| {
            if img.starts_with("https://m.media-amazon.com/") && img.contains("160") {
                img.replace("160", "512")
            } else {
                img
            }
        }));

    Ok(if let (Some(title), Some(author)) = (title, author) {
        Some(AddAllQueryResult {
            title,
            author,
            image,
        })
    } else {
        None
    })
}

#[get("/isbn/search")]
async fn search(query: web::Query<IsbnSearchQuery>, data: web::Data<AppState>) -> impl Responder {
    let IsbnSearchQuery { q } = &*query;
    let session = data.session.lock().unwrap();

    // check for cached result

    if let Ok(res) = documents::read::<IsbnResolvedQuery>(&*session, "isbn_query_cache", q) {
        return HttpResponse::Ok().json(json!({ "ok": true, "cached": true, "result": res }));
    }

    guard! {
        // attempt to query addall for basic book details

        let addall_result = try? query_addall(&q).await, else |err| {
            return HttpResponse::InternalServerError()
                .with_err(err, "attempting to query addall.com")
        };

        let AddAllQueryResult { title, author, image } = addall_result, else {
            return HttpResponse::NotFound()
                .with_err("not found", "attempting to query addall.com")
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
