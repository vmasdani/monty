#[macro_use]
extern crate diesel;

#[macro_use]
extern crate serde;

#[macro_use]
extern crate diesel_migrations;

pub mod handler;
pub mod middleware;
pub mod model;
pub mod populate;
pub mod schema;

use std::{
    io,
    pin::Pin,
    task::{Context, Poll},
    time::Duration,
};

use actix_cors::Cors;
use actix_service::{Service, Transform};
use actix_web::{
    dev::{ServiceRequest, ServiceResponse},
    error::{ErrorBadRequest, ErrorUnauthorized},
    get, http, web, App, Error, HttpResponse, HttpServer, Responder, Result,
};
use chrono::{Datelike, NaiveDate, Utc};
use diesel::{
    prelude::*,
    r2d2::{ConnectionManager, Pool},
    SqliteConnection,
};
use diesel_migrations::embed_migrations;
use futures::{
    future::{ok, Either, FutureExt, Ready},
    Future,
};
use http::StatusCode;
use model::{Currencie, Email};
use tokio::task::LocalSet;

type DbPool = diesel::r2d2::Pool<ConnectionManager<SqliteConnection>>;

use crate::handler::*;
use tokio_diesel::*;

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

#[tokio::main]
async fn main() {
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

    let actix_data_pool_clone = pool.clone();
    let poll_db_pool_clone = pool.clone();

    tokio::join!(run_http(actix_data_pool_clone), poll_db(poll_db_pool_clone));
}

async fn my_async_fun() {
    tokio::time::delay_for(Duration::from_secs(1)).await;
}

async fn run_http(pool: Pool<ConnectionManager<SqliteConnection>>) -> () {
    let local = LocalSet::new();
    let sys = actix_web::rt::System::run_in_tokio("server", &local);

    let server = HttpServer::new(move || {
        App::new()
            .data(pool.clone())
            .wrap_fn(|req, srv| {
                let auth_header = match req.headers().get("authorization") {
                    Some(auth) => Some(String::from(auth.to_str().unwrap_or(""))),
                    _ => None,
                };
                let fut = srv.call(req);

                async move {
                    let res: ServiceResponse<_> = fut.await?;
                    // println!("{:?}", auth_header);

                    match auth_header {
                        Some(auth) => {
                            // println!("Auth header: {:?}", auth);

                            let url = format!(
                                "https://oauth2.googleapis.com/tokeninfo?id_token={}",
                                auth
                            );

                            let resp = reqwest::get(url.as_str()).await;

                            let authorized = match resp {
                                Ok(resp_res) => {
                                    if resp_res.status() == StatusCode::OK {
                                        true
                                    } else {
                                        println!("Token invalid! {}", resp_res.status());
                                        false
                                    }
                                }
                                _ => {
                                    println!("Unauthorized!");
                                    false
                                }
                            };

                            if authorized {
                                Ok(res)
                            } else {
                                Err(ErrorUnauthorized("Unauthorized!"))
                            }
                        }
                        _ => Err(ErrorBadRequest("No auth header present!")),
                    }
                }
            })
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
    .bind("127.0.0.1:8080");

    match server {
        Ok(srv) => {
            srv.run().await;
        }
        _ => {
            println!("Error running HTTP srever.");
        }
    }
}

async fn poll_db(pool: Pool<ConnectionManager<SqliteConnection>>) -> () {
    const CURRENCIES_LIST: [&str; 168] = [
        "AED", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN", "BAM", "BBD", "BDT",
        "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BRL", "BSD", "BTC", "BTN", "BWP", "BYN", "BYR",
        "BZD", "CAD", "CDF", "CHF", "CLF", "CLP", "CNY", "COP", "CRC", "CUC", "CUP", "CVE", "CZK",
        "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "EUR", "FJD", "FKP", "GBP", "GEL", "GGP",
        "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD", "HNL", "HRK", "HTG", "HUF", "IDR", "ILS",
        "IMP", "INR", "IQD", "IRR", "ISK", "JEP", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KMF",
        "KPW", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", "LSL", "LTL", "LVL", "LYD",
        "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRO", "MUR", "MVR", "MWK", "MXN", "MYR",
        "MZN", "NAD", "NGN", "NIO", "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR",
        "PLN", "PYG", "QAR", "RON", "RSD", "RUB", "RWF", "SAR", "SBD", "SCR", "SDG", "SEK", "SGD",
        "SHP", "SLL", "SOS", "SRD", "STD", "SVC", "SYP", "SZL", "THB", "TJS", "TMT", "TND", "TOP",
        "TRY", "TTD", "TWD", "TZS", "UAH", "UGX", "USD", "UYU", "UZS", "VEF", "VND", "VUV", "WST",
        "XAF", "XAG", "XAU", "XCD", "XDR", "XOF", "XPF", "YER", "ZAR", "ZMK", "ZMW", "ZWL",
    ];

    loop {
        let mut currencies_handle = vec![];

        CURRENCIES_LIST.into_iter().for_each(|currency_name| {
            let pool_clone = pool.clone();

            currencies_handle.push(async move {
                use crate::schema::currencies::dsl::*;

                let found_currency = currencies
                    .filter(name.eq(currency_name))
                    .first_async::<Currencie>(&pool_clone)
                    .await;

                match found_currency {
                    Ok(currency) => {
                        match currency.last_update_day {
                            Some(update_day) => {
                                let current_utc = Utc::now();
                                let current_naive_date_time = NaiveDate::from_ymd(
                                    current_utc.year(),
                                    current_utc.month(),
                                    current_utc.day(),
                                )
                                .and_hms(0, 0, 0);

                                let comp = current_naive_date_time.gt(&update_day);

                                println!(
                        "Currency {} found. Last update: {:?}, current: {}, greater? {}",
                        currency_name, currency.last_update_day, current_naive_date_time, comp
                    );
                            }
                            None => {
                                println!("Currency {} found, last update invalid.", currency_name);
                            }
                        }
                    }
                    Err(_) => {
                        let utc_now = Utc::now();
                        let naive_date_time_now =
                            NaiveDate::from_ymd(utc_now.year(), utc_now.month(), utc_now.day())
                                .and_hms(0, 0, 0);

                        println!(
                            "Currency {} not found! Creating..., Update date: {:?}",
                            currency_name, naive_date_time_now
                        );

                        diesel::replace_into(currencies)
                            .values(Currencie {
                                id: None,
                                name: Some(currency_name.to_string()),
                                created_at: None,
                                updated_at: None,
                                rate: Some(0.0),
                                last_update_day: Some(naive_date_time_now),
                            })
                            .execute_async(&pool_clone);
                    }
                }
            });
        });

        for currency_handle in currencies_handle {
            currency_handle.await;
        }

        tokio::time::delay_for(Duration::from_secs(10)).await;
    }
}
