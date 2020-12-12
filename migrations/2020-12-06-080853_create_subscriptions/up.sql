-- Your SQL goes here
create table subscriptions (
    id integer primary key autoincrement,
    email_id integer,
    name text,
    cost integer,
    created_at datetime default current_timestamp
)