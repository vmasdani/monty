-- Your SQL goes here
create table intervals (
    id integer primary key autoincrement,
    created_at datetime default current_timestamp,
    updated_at datetime default current_timestamp,
    name text
);

create trigger intervals_ts after insert on intervals
begin
    update intervals set updated_at=current_timestamp where id=new.id;
end;