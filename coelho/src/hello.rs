use actix_web::{Responder, get, HttpResponse};
use serde::{Serialize, Deserialize};


#[derive(Debug, Serialize, Deserialize)]
struct HelloResponse {
    ok: bool
}

#[get("/")]
async fn hello() -> impl Responder {
    HttpResponse::Ok().json(HelloResponse {
        ok: true
    })
}