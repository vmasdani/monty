-- Your SQL goes here
create table subscriptions (
    id integer primary key autoincrement,
    created_at datetime default current_timestamp,
    updated_at datetime default current_timestamp,
    email_id integer,
    name text,
    cost real
);

create trigger subscriptions_ts after insert on subscriptions
begin
    update subscriptions set updated_at=current_timestamp where id=new.id;
end;