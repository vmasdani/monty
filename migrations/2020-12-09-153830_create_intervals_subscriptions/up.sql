-- Your SQL goes here
create table intervals_subscriptions (
    id integer primary key autoincrement,
    interval_id integer,
    subscription_id integer,
    created_at datetime default current_timestamp
)