-- Your SQL goes here
create table emails (
    id integer primary key autoincrement,
    created_at datetime default current_timestamp,
    updated_at datetime default current_timestamp,
    email text
);

create trigger emails_ts after insert on emails
begin
    update emails set updated_at=current_timestamp where id=new.id;
end;