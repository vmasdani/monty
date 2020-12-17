-- Your SQL goes here
create table intervals_subscriptions (
    id integer primary key autoincrement,
    created_at datetime default current_timestamp,
    updated_at datetime default current_timestamp,
    interval_id integer,
    subscription_id integer
);

create trigger intervals_subscriptions_ts after insert on intervals_subscriptions
begin
    update intervals_subscriptions set updated_at=current_timestamp where id=new.id;
end;