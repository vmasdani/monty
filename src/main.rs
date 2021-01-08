#[macro_use]
extern crate diesel;

#[macro_use]
extern crate serde;

#[macro_use]
extern crate diesel_migrations;

#[macro_use]
extern crate actix_web;

pub mod handler;
pub mod model;
pub mod populate;
pub mod postbody;
pub mod schema;

use actix_cors::Cors;
use actix_files::Files;
use actix_service::{Service, Transform};
use actix_web::{App, Error, HttpResponse, HttpServer, Responder, Result, dev::{ServiceRequest, ServiceResponse}, error::{ErrorBadRequest, ErrorUnauthorized}, get, http::{self, ContentEncoding}, middleware, web};
use chrono::{Datelike, NaiveDate, NaiveDateTime, Utc};
use diesel::{
    prelude::*,
    r2d2::{ConnectionManager, Pool},
    SqliteConnection,
};
use diesel_migrations::embed_migrations;
use dotenv::dotenv;
use futures::{Future, future::{ok, Either, FutureExt, Ready}};
use http::StatusCode;
use model::{Currencie, Email};
use serde_json::Value;
use std::{env, fs::File, io::{self, BufReader, Read}, pin::Pin, sync::Arc, task::{Context, Poll}, time::Duration};
use tokio::{sync::Mutex, task::LocalSet};

type DbPool = diesel::r2d2::Pool<ConnectionManager<SqliteConnection>>;

use handler::*;
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
    dotenv().ok();

    let mut DATABASE_URL = String::new();
    let mut FIXER_API_KEY = String::new();
    let mut APP_PORT = String::new();

    // Parse env.json
    match File::open("env.json") {
        Ok(contents) => {
            let mut json_str = String::new();

            BufReader::new(contents).read_to_string(&mut json_str);

            println!("env.json contents:");
            println!("{}", json_str);

            match serde_json::from_str(&json_str) as Result<Value, _> {
                Ok(val) => {
                    FIXER_API_KEY = match val["fixer_api_key"].as_str() {
                        Some(fixer_api_key) => fixer_api_key.to_string(),
                        _ => FIXER_API_KEY
                    };
                    APP_PORT = match val["server_port"].as_str() {
                        Some(server_port) => server_port.to_string(),
                        _ => APP_PORT
                    };
                },
                _ => {
                    println!("Error parsing env.json")
                }
            }

            
        },
        _ => {
            println!("Error opening env.json!");
        }
    }

    // Parse .env
    for (key, value) in env::vars() {
        match key.as_str() {
            "DATABASE_URL" => DATABASE_URL = value,
            _ => {
                println!(".env variable irrelevant");
            }
        }
    }

    println!("db url: {}", DATABASE_URL);
    println!("fixer api key: {}", FIXER_API_KEY);
    println!("server port: {}", APP_PORT);

    let manager = ConnectionManager::<SqliteConnection>::new(DATABASE_URL);
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

    tokio::join!(
        run_http(actix_data_pool_clone, &APP_PORT),
        poll_db(poll_db_pool_clone, FIXER_API_KEY)
    );
}

async fn my_async_fun() {
    tokio::time::delay_for(Duration::from_secs(1)).await;
}

async fn run_http(pool: Pool<ConnectionManager<SqliteConnection>>, app_port: &String) -> () {
    let local = LocalSet::new();
    let sys = actix_web::rt::System::run_in_tokio("server", &local);

    let server = HttpServer::new(move || {
        App::new()
            .data(pool.clone())
            .wrap(middleware::Compress::new(ContentEncoding::Br))
            .wrap_fn(|req, srv| {
                let path = req.path().to_string();
                let auth_header = match req.headers().get("authorization") {
                    Some(auth) => Some(String::from(auth.to_str().unwrap_or(""))),
                    _ => None,
                };
                let fut = srv.call(req);

                
                    async move {
                        let res: ServiceResponse<_> = fut.await?;
                        // println!("{:?}", auth_header);
    
                        if path.eq("/") 
                        || path.eq("/currencies") 
                        || path.eq("/script.js") 
                        || path.eq("/main.js") 
                        || path.eq("/diesel.png")
                        || path.eq("/paypal.webp") {
                            println!("Pass! {}", path);

                            Ok(res)
                        } else {
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
            // .service(home)
            // Logins
            .service(google_login_verify)
            // Emails
            .service(get_emails)
            .service(get_email_by_name)
            .service(get_email)
            .service(post_email)
            .service(post_email_save)
            .service(post_email_save_bulk)
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
            .service(Files::new("/", "./frontend").index_file("index.html"))
        // .route("/", web::get().to(home))
        // .route("/{name}", web::get().to(index))
    })
    .bind(format!("127.0.0.1:{}", app_port.as_str()));

    match server {
        Ok(srv) => {
            srv.run().await;
        }
        _ => {
            println!("Error running HTTP srever.");
        }
    }
}

async fn poll_db(pool: Pool<ConnectionManager<SqliteConnection>>, fixer_api_key: String) -> () {
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

        let un_updated = Arc::new(Mutex::new(0));

        CURRENCIES_LIST.iter().for_each(|currency_name| {
            let pool_clone = pool.clone();
            let un_updated_clone = un_updated.clone();

            currencies_handle.push(async move {
                use crate::schema::currencies::dsl::*;

                let found_currency = currencies
                    .filter(name.eq(currency_name))
                    .first_async::<Currencie>(&pool_clone)
                    .await;

                match found_currency {
                    Ok(currency) => match currency.last_update_day {
                        Some(update_day) => {
                            let utc_now = Utc::now();
                            let current_naive_date_time =
                                NaiveDate::from_ymd(utc_now.year(), utc_now.month(), utc_now.day())
                                    .and_hms(0, 0, 0);

                            let comp = current_naive_date_time.gt(&update_day);

                            println!(
                                "Currency {} found ({}). Last update: {:?}, current: {}, greater? {}",
                                currency_name,
                                currency.rate.unwrap_or(0.0),
                                currency.last_update_day,
                                current_naive_date_time,
                                comp
                            );
                            if comp {
                                let mut un_updated_lock = un_updated_clone.lock().await;
                                *un_updated_lock = *un_updated_lock + 1;
                            }
                        }
                        None => {
                            println!("Currency {} found, last update invalid.", currency_name);
                        }
                    },
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
                                // last_update_day: Some(naive_date_time_now),
                                last_update_day: None,
                            })
                            .execute_async(&pool_clone)
                            .await;

                        // Increase non updated
                        let mut un_updated_val = un_updated_clone.lock().await;
                        *un_updated_val = *un_updated_val + 1;
                    }
                }
            });
        });

        for currency_handle in currencies_handle {
            currency_handle.await;
        }

        let un_updated_clone = un_updated.clone();
        let un_updated_val: i32 = *un_updated_clone.lock().await;

        println!("Currencies not updated: {}", un_updated_val);

        if un_updated_val > 0 {
            let fixer_url = format!(
                "http://data.fixer.io/api/latest?access_key={}",
                fixer_api_key
            );

            println!("Updating!");

            let resp_res = reqwest::get(fixer_url.as_str()).await;

            match resp_res {
                Ok(resp) => match resp.text().await {
                    Ok(resp_text) => {
                        // println!("Resp text: {}", resp_text);

                        match serde_json::from_str(resp_text.as_str()) as Result<Value, _> {
                            Ok(resp_json) => {
                                let mut currency_list_handles = vec![];

                                CURRENCIES_LIST.iter().for_each(|currency_name| {
                                    let pool = pool.clone();
                                    let rate_f64 =
                                        resp_json["rates"][currency_name].as_f64().unwrap_or(0.0);

                                    println!("currency: {}, rate: {}", currency_name, rate_f64);

                                    currency_list_handles.push(async move {
                                        use crate::schema::currencies::dsl::*;

                                        let found_currencie_res = currencies
                                            .filter(name.eq(currency_name))
                                            .first_async::<Currencie>(&pool)
                                            .await;

                                        match found_currencie_res {
                                            Ok(mut found_currencie) => {
                                                let utc_now = Utc::now();
                                                let naive_date_time_now = NaiveDate::from_ymd(
                                                    utc_now.year(),
                                                    utc_now.month(),
                                                    utc_now.day(),
                                                )
                                                .and_hms(0, 0, 0);

                                                found_currencie.rate = Some(rate_f64 as f32);
                                                found_currencie.last_update_day =
                                                    Some(naive_date_time_now);

                                                println!("Updated currency {}: on {:?}", currency_name, found_currencie.last_update_day);

                                                diesel::replace_into(currencies)
                                                    .values(found_currencie)
                                                    .execute_async(&pool)
                                                    .await;
                                            }
                                            _ => {
                                                println!(
                                                    "currency {} not found in db",
                                                    currency_name
                                                );
                                            }
                                        }
                                    });
                                });

                                for handle in currency_list_handles {
                                    handle.await;
                                }
                            }
                            _ => {
                                println!("Failed parsing json");
                            }
                        }
                    }
                    _ => {
                        println!("Extracting response text error");
                    }
                },
                _ => {
                    println!("Error fetching rates");
                }
            }
        } else {
            println!("No need to update. Already latest.");
        }

        tokio::time::delay_for(Duration::from_secs(3600)).await;
    }
}
