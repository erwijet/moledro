use actix_web::{web, App, HttpServer};
use firestore_db_and_auth::ServiceSession;

mod hello;
mod http;
mod isbn;

struct AppState {
    /// the firebase service session
    session: std::sync::Mutex<ServiceSession>,
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        // setup firestore session

        let cred = firestore_db_and_auth::Credentials::from_file(
            &*std::env::var("FIREBASE_CRED").expect("read environment variable 'FIREBASE_CRED'"),
        )
        .unwrap();

        // setup server

        App::new()
            .app_data(web::Data::new(AppState {
                session: std::sync::Mutex::new(
                    ServiceSession::new(cred).expect("create a service account session"),
                ),
            }))
            .service(hello::hello)
            .service(isbn::search)
    })
    .bind(("0.0.0.0", 8000))?
    .run()
    .await
}
