-- Your SQL goes here
create table emails (
    id integer primary key autoincrement,
    email text,
    created_at datetime default (datetime('now'))
)