-- Your SQL goes here-- Your SQL goes here
create table currencies (
    id integer primary key autoincrement,
    name text,
    created_at datetime default current_timestamp
)