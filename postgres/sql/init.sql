create extension if not exists cube;
create extension if not exists tablefunc;
drop database if exists book;
create database book;
\connect book;

create table if not exists countries (
  country_code char(2) primary key,
  country_name text unique);
insert into countries values
  ('us','United States'),
  ('mx','Mexico'),
  ('au','Australia'),
  ('gb','United Kingdom'),
  ('de','Germany'),
  ('ll','Loompaland') on conflict do nothing;
delete from countries where country_code = 'll';

create table if not exists cities (
  name text not null,
  postal_code varchar(9) check (postal_code <> ''),
  country_code char(2) references countries,
  primary key (country_code, postal_code));
--ca not in countries table
--insert into cities values ('Toronto','M4C1B5','ca');
delete from cities where name = 'Portland';
insert into cities values ('Portland','87200','us') on conflict do nothing;
update cities SET postal_code = '97205' where name = 'Portland';
select cities.*, country_name from
  cities inner join countries
  on cities.country_code = countries.country_code;

create table if not exists venues (
  venue_id serial primary key,
  name varchar(255),
  street_address text,
  type char(7) check ( type in ('public','private') ) DEFAULT 'public',
  postal_code varchar(9),
  country_code char(2),
  foreign key (country_code, postal_code)
  references cities (country_code, postal_code) match full
);
insert into venues (name, postal_code, country_code) values ('Crystal Ballroom', '97205', 'us');
select v.venue_id, v.name, c.name from venues v
  inner join cities c
  on v.postal_code=c.postal_code and v.country_code=c.country_code;
insert into venues (name, postal_code, country_code) values ('Voodoo Donuts', '97205', 'us') returning venue_id;

--have to have an explicit column in the table to reference as foreign key
--was not adding `venue_id integer` and getting errors -> column "venue_id" referenced in foreign key constraint does not exist
create table if not exists events (
  event_id serial primary key,
  title varchar(255),
  starts timestamp,
  ends timestamp,
  venue_id integer,
  foreign key (venue_id) references venues match full
);
insert into events (title, starts, ends, venue_id) values
  ('LARP Club', '2012-02-15 17:30:00', '2012-02-15 19:30:00', 2);
insert into events (title, starts, ends) values
  ('April Fools Day', '2012-04-01 00:00:00', '2012-04-01 23:59:59'),
  ('Christmas Day', '2012-12-25 00:00:00', '2012-12-25 23:59:59');

-- \di - list all indexes, can see p_key, unique
create index event_starts on events using btree(starts);

--day 1, problem 3
alter table if exists venues add column if not exists active boolean, alter column active set default true;

--day 2 starts
insert into cities values ('Austin', '78701', 'us') on conflict do nothing;
insert into venues (name, street_address, postal_code, country_code) values ('Texas Capitol', '1100 Congress Ave', '78701', 'us');
insert into events (title, starts, ends, venue_id) values
  ('Moby', '2012-02-06 21:00', '2012-02-06 23:00', (
    select venue_id from venues where name = 'Crystal Ballroom'
  )),
  ('Wedding', '2012-02-26 21:00:00', '2012-02-26 23:00:00', (
    select venue_id from venues where name = 'Voodoo Donuts'
  )),
  ('Tour', '2012-02-26 18:00:00', '2012-02-26 20:30:00', (
    select venue_id from venues where name = 'Texas Capitol'
  ));
insert into events (title, starts, ends) values ('Valentine''s Day', '2012-02-14 00:00:00', '2012-02-14 23:59:00');

\i /sql/add_event.sql
select add_event('House Party', '2012-05-03 23:00', '2012-05-04 02:00', 'Run''s House', '97205', 'us');

create table if not exists logs (
  event_id integer,
  old_title varchar(255),
  old_starts timestamp,
  old_ends timestamp,
  logged_at timestamp default current_timestamp
);
\i /sql/log_event.sql
create trigger log_events after update on events for each row execute procedure log_event();
update events set ends='2012-05-04 01:00:00' where title='House Party';
--psql:/sql/init.sql:94: NOTICE:  Someone just changed event #8

--add colors to events
--update view query to handle colors
alter table events add colors text array;
\i /sql/holiday_view_1.sql
--cannot update views
--UPDATE holidays SET colors = '{"red","green"}' where name = 'Christmas Day';
\i /sql/create_holiday_update_rule.sql
update holidays set colors = '{"red","green"}' where name = 'Christmas Day';

--replaced with generate_series
--create temporary table month_count(month int);
--insert into month_count values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12);

\i /sql/delete_venue_rule.sql
