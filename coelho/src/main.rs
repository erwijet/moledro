#![deny(warnings)]

use actix_web::{web, App, HttpServer};
use firestore_db_and_auth::Credentials;

mod hello;
mod isbn;

struct AppState {
    credentials: Credentials
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        // setup firestore session

        let credentials = firestore_db_and_auth::Credentials::from_file(
            &*std::env::var("FIREBASE_CRED").expect("read environment variable 'FIREBASE_CRED'"),
        )
        .unwrap();

        // setup server

        App::new()
            .app_data(web::Data::new(AppState { credentials }))
            .service(hello::hello)
            .service(isbn::search)
    })
    .bind(("0.0.0.0", 8000))?
    .run()
    .await
}
