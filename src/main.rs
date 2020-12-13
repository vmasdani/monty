#[macro_use]
extern crate diesel;

#[macro_use]
extern crate serde;

#[macro_use]
extern crate diesel_migrations;

pub mod handler;
pub mod model;
pub mod populate;
pub mod schema;
pub mod middleware;

use std::{io, pin::Pin, task::{Context, Poll}};

use actix_cors::Cors;
use actix_service::{Service, Transform};
use actix_web::{App, Error, HttpResponse, HttpServer, Responder, dev::{ServiceRequest, ServiceResponse}, get, http, web};
use diesel::{prelude::*, r2d2::ConnectionManager, SqliteConnection};
use diesel_migrations::embed_migrations;
use futures::{Future, future::{Either, FutureExt, Ready, ok}};
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
    let email = match &param.email {
        Some(email) => email.clone(),
        None => String::from(""),
    };
    HttpResponse::Ok().body(format!("OK, {}, {}!", name, email))
}

embed_migrations!();



#[actix_web::main]
async fn main() -> io::Result<()> {
    let manager = ConnectionManager::<SqliteConnection>::new("db.sqlite3");
    let pool = diesel::r2d2::Pool::builder()
        .max_size(1)
        .build(manager)
        .expect("Failed  to create pool.");

    let pool_clone = pool.clone();

    println!("Running embedded migration...");
    match pool_clone.get() {
        Ok(conn) => {
            embedded_migrations::run(&conn).expect("Failed running embedded migration!");
        }
        _ => {
            println!("Failed running embedded migration!");
        }
    }

    // Population
    println!("Running population...");
    match pool.clone().get() {
        Ok(pool) => {
            populate::populate(pool);
        }
        _ => {
            println!("Failed ppoulating");
        }
    }

    HttpServer::new(move || {
        App::new()
            .data(pool.clone())
            .wrap(
                Cors::default()
                    .allow_any_origin()
                    .allow_any_method()
                    .allow_any_header()
                    // .allowed_methods(vec!["GET", "POST"])
                    //     .allowed_headers(vec![http::header::AUTHORIZATION, http::header::ACCEPT])
                    //     .allowed_header(http::header::CONTENT_TYPE)
                    .max_age(3600),
            )
            .wrap(middleware::SayHi)
            // .wrap_fn(|req, srv| {
            //     // println!("Path: {}, headers: {:?}", req.path(), req.headers());

            //     // req.headers();
            //     // req.headers_mut().insert(
            //     //     http::HeaderName::from_lowercase(b"test").unwrap(),
            //     //     http::HeaderValue::from_str("Testing").unwrap(),
            //     // );

            //     // println!("Headers now: {:?}", req.headers());

            //     srv.call(req)
            // })
            .service(home)
            // Logins
            .service(google_login_verify)
            // Emails
            .service(get_emails)
            .service(get_email_by_name)
            .service(get_email)
            .service(post_email)
            .service(post_email_save)
            .service(get_email_subscriptions)
            .service(get_email_by_name_subscriptions)
            // Subscriptions
            .service(get_subscriptions)
            .service(get_subscription)
            .service(post_subscription)
            // Currencies
            .service(get_currencies)
            // Intervals
            .service(get_intervals)
        // .route("/", web::get().to(home))
        // .route("/{name}", web::get().to(index))
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}


