#[macro_use]
extern crate diesel;

#[macro_use]
extern crate serde;

pub mod handler;
pub mod schema;
pub mod model;

use std::io;

use actix_web::{get, App, Error, HttpResponse, HttpServer, Responder, web};
use diesel::{r2d2::ConnectionManager, SqliteConnection, prelude::*};
use model::Email;

type DbPool = diesel::r2d2::Pool<ConnectionManager<SqliteConnection>>;

use crate::handler::*;

#[derive(Deserialize)]
struct QueryInfo {
    email: Option<String>,
}

#[get("/")]
async fn home() -> impl Responder {
    HttpResponse::Ok().body("OK!")
}

#[get("/{name}")]
async fn index(
    pool: web::Data<DbPool>,
    name: web::Path<String>,
    param: web::Query<QueryInfo>,
) -> impl Responder {
    let email =
        match &param.email {
            Some(email) => email.clone(),
            None => String::from("")
        };
    HttpResponse::Ok().body(format!("OK, {}, {}!", name, email))
}

#[actix_web::main]
async fn main() -> io::Result<()> {
    let manager = ConnectionManager::<SqliteConnection>::new("db.sqlite3");
    let pool = diesel::r2d2::Pool::builder()
        .max_size(1)
        .build(manager)
        .expect("Failed  to create pool.");

    
    let pool_clone = pool.clone();
    let pool_res = pool_clone.get();

    let emails =
        match pool_res {
            Ok(conn) => {
                use schema::emails::dsl::*;
                
                Some(emails.load::<Email>(&conn))
            },
            Err(_) => None 
        };

    HttpServer::new(move || {
        App::new()
            .data(pool.clone())
            .service(home)
            // .service(index)

            // Emails
            .service(get_emails)
            .service(get_email)
            .service(post_email)
            .service(get_email_subscriptions)

            // Subscriptions
            .service(get_subscriptions)
            .service(get_subscription)
            .service(post_subscription)


            // .route("/", web::get().to(home))
            // .route("/{name}", web::get().to(index))
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}
