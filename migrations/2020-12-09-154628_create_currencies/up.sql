-- Your SQL goes here-- Your SQL goes here
create table currencies (
    id integer primary key autoincrement,
    created_at datetime default current_timestamp,
    updated_at datetime  default current_timestamp,
    name text
);

create trigger currencies_ts after insert on currencies
begin
    update currencies set updated_at=current_timestamp where id=new.id;
end;