-- Your SQL goes here
create table intervals (
    id integer primary key autoincrement,
    name text,
    created_at datetime default current_timestamp
)