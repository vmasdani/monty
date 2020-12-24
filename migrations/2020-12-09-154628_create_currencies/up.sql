-- Your SQL goes here-- Your SQL goes here
create table currencies (
    id integer primary key autoincrement,
    created_at datetime default (datetime('now')),
    updated_at datetime default (datetime('now')),
    name text
);

create trigger currencies_ts after insert on currencies
begin
    update currencies set updated_at=(datetime('now')) where id=new.id;
end;