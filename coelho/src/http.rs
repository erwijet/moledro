// use actix_web::{http, HttpResponse, HttpResponseBuilder};
// use serde::Serialize;
// use serde_json::json;

// pub fn json_ok<T: Serialize>(with: T) -> HttpResponse {
//     HttpResponse::Ok().json(json! ({
//         "ok": true,
//         "result": with
//     }))
// }

// pub fn json_err<T: Serialize>(with: T, code: http::StatusCode, message: String) -> HttpResponse {
//     HttpResponseBuilder::new(code).json(json! ({
//         "ok": false,
//         "result": with,
//         "message": message
//     }))
// }