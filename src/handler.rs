use actix_web::{client::Client, get, post, web, HttpResponse, Responder};
use diesel::{r2d2::ConnectionManager, SqliteConnection};

type DbPool = diesel::r2d2::Pool<ConnectionManager<SqliteConnection>>;

use crate::model::*;
use diesel::prelude::*;

// EMAILS

#[get("/emails")]
async fn get_emails(pool: web::Data<DbPool>) -> impl Responder {
    println!("Getting emails!");

    match pool.get() {
        Ok(conn) => {
            use crate::schema::emails::dsl::*;

            let emails_res = web::block(move || emails.load::<Email>(&conn)).await;
            match emails_res {
                Ok(emails_list) => HttpResponse::Ok().json(&emails_list),
                _ => HttpResponse::InternalServerError().body("Error getting emails!"),
            }
        }
        _ => HttpResponse::InternalServerError().body("Getting connection error!"),
    }
}

#[get("/emails/{email_id}")]
async fn get_email(pool: web::Data<DbPool>, email_id: web::Path<i32>) -> impl Responder {
    match pool.get() {
        Ok(conn) => {
            use crate::schema::emails::dsl::{emails, id};
            let email_res = web::block(move || {
                emails
                    .filter(id.eq(email_id.into_inner()))
                    .first::<Email>(&conn)
            })
            .await;

            match email_res {
                Ok(email) => HttpResponse::Ok().json(&email),
                _ => HttpResponse::InternalServerError().body("Error getting email!"),
            }
        }
        _ => HttpResponse::InternalServerError().body("Getting connection error!"),
    }
}

#[get("/emails/{email_id}/subscriptions")]
async fn get_email_subscriptions(
    pool: web::Data<DbPool>,
    email_id: web::Path<i32>,
) -> impl Responder {
    match pool.get() {
        Ok(conn) => {
            let subscriptions_res = web::block(move || {
                use crate::schema::emails::dsl::{emails, id};

                let email = emails.find(email_id.into_inner()).first::<Email>(&conn)?;
                Subscription::belonging_to(&email).load::<Subscription>(&conn)
            })
            .await;

            match subscriptions_res {
                Ok(subscriptions_list) => HttpResponse::Ok().json(&subscriptions_list),
                _ => HttpResponse::InternalServerError().body("Getting subscriptions list error!"),
            }
        }
        _ => HttpResponse::InternalServerError().body("Getting connection error!"),
    }
}

#[post("/emails")]
async fn post_email(pool: web::Data<DbPool>, email_body: web::Json<Email>) -> impl Responder {
    match pool.get() {
        Ok(conn) => {
            let res = web::block(move || {
                use crate::schema::emails::dsl::{emails, id};
                diesel::replace_into(emails)
                    .values(&email_body.into_inner())
                    .execute(&conn)
            })
            .await;

            match res {
                Ok(_) => HttpResponse::Created().body("OK"),
                _ => HttpResponse::InternalServerError().body("Error replacing email!"),
            }
        }
        _ => HttpResponse::InternalServerError().body("Getting connection error!"),
    }
}

// SUBSCRIPTIONS
#[get("/subscriptions")]
async fn get_subscriptions(pool: web::Data<DbPool>) -> impl Responder {
    match pool.get() {
        Ok(conn) => {
            let subscriptions_res = web::block(move || {
                use crate::schema::subscriptions::dsl::*;
                subscriptions.load::<Subscription>(&conn)
            })
            .await;

            match subscriptions_res {
                Ok(subscriptions) => HttpResponse::Ok().json(subscriptions),
                _ => HttpResponse::InternalServerError().body("Error fetching subscriptions"),
            }
        }
        _ => HttpResponse::InternalServerError().body("Error getting pool"),
    }
}

#[get("/subscriptions/{subscription_id}")]
async fn get_subscription(
    pool: web::Data<DbPool>,
    subscription_id: web::Query<i32>,
) -> impl Responder {
    match pool.get() {
        Ok(conn) => {
            let subscription_res = web::block(move || {
                use crate::schema::subscriptions::dsl::*;
                subscriptions
                    .find(subscription_id.into_inner())
                    .first::<Subscription>(&conn)
            })
            .await;

            match subscription_res {
                Ok(subscription) => HttpResponse::Ok().json(subscription),
                _ => HttpResponse::InternalServerError().body("Error fetching subscriptions"),
            }
        }
        _ => HttpResponse::InternalServerError().body("Error getting pool"),
    }
}

#[post("/subscriptions")]
async fn post_subscription(
    pool: web::Data<DbPool>,
    subscription: web::Json<Subscription>,
) -> impl Responder {
    match pool.get() {
        Ok(conn) => {
            let res = web::block(move || {
                use crate::schema::subscriptions::dsl::*;
                diesel::replace_into(subscriptions)
                    .values(&subscription.into_inner())
                    .execute(&conn)
            })
            .await;

            match res {
                Ok(_) => HttpResponse::Created().body("OK"),
                _ => HttpResponse::InternalServerError().body("Error replacing subscription"),
            }
        }
        _ => HttpResponse::InternalServerError().body("Error getting pool"),
    }
}

#[derive(Deserialize)]
struct IdTokenBody {
    id_token: String,
}

#[post("/google-login-verify")]
async fn google_login_verify(id_token_body: web::Json<IdTokenBody>) -> impl Responder {
    println!("Verifying login!");

    let url = format!(
        "https://oauth2.googleapis.com/tokeninfo?id_token={}",
        id_token_body.id_token
    );
    #[derive(Serialize, Deserialize, Debug)]
    pub struct OauthResponseBody {
        email: String,
    }

    match reqwest::get(url.as_str()).await {
        Ok(resp) => match resp.json::<OauthResponseBody>().await {
            Ok(oauth_response) => HttpResponse::Ok().json(OauthResponseBody {
                email: oauth_response.email,
            }),
            _ => HttpResponse::InternalServerError().body("Error getting email!"),
        },
        Err(e) => HttpResponse::InternalServerError().body(format!("{:?}", e)),
    }
}
