--day 2 starts
--aggregate examples
select count(title) from events where title like '%Day%';
select min(starts), max(ends) from events inner join venues on events.venue_id = venues.venue_id where venues.name = 'Crystal Ballroom';

--counting at all venues
select count(*) from events where venue_id = 1;
--... becomes tedious
select count(*) from events group by venue_id;
--count
---------
--     3
--     2
--     1
--     1
--(4 rows)
--this is ugly
select venue_id, count(*) from events group by venue_id;
-- venue_id | count
------------+-------
--          |     3
--        2 |     2
--        1 |     1
--        3 |     1
--(4 rows)
--better...but out of order
select venue_id, count(*) from events group by venue_id order by venue_id;
-- venue_id | count
------------+-------
--        1 |     1
--        2 |     2
--        3 |     1
--          |     3
--(4 rows)

--might have gotten ahead of myself...
--having is like the where clause, except it can filter by aggregate fns
--this query could be for "most popular venue"
select venue_id from events group by venue_id having count(*) >= 2 AND venue_id is not null;

--the following are equivalent -> removes duplicates
select venue_id from events group by venue_id;
select distinct venue_id from events;


--Window functions
--The problem with GROUP BY is that the results are collapsed to single rows
--i.e. select title, venue_id, count(*) from events group by venue_id;
-- LARP Club and wedding have two titles with a single venue_id so it is unclear _which_ to display
select title, count(*) over (partition by venue_id) from events;
--      title      | count
-------------------+-------
-- Moby            |     1
-- LARP Club       |     2
-- Wedding         |     2
-- Tour            |     1
-- April Fools Day |     3
-- Christmas Day   |     3
-- Valentine's Day |     3
--(7 rows)


--Transactions - _all or nothing_
-- ACID compliance
--Each command we've executed thus far has been implicity wrapped in a transaction
-- i.e. `delete from accounts where total > 20;` would not execute in any capacity had the DB crashed
--useful when modifying two tables/rows that cannot be out of sync - think bank transfer funds

--example transaction - notice the state inside the transaction + after rollback
--book=# begin transaction;
--BEGIN
--book=# delete from events;
--DELETE 7
--book=# select * from events;
-- event_id | title | starts | ends | venue_id
------------+-------+--------+------+----------
--(0 rows)
--
--book=# rollback;
--ROLLBACK
--book=# select * from events;
-- event_id |      title      |       starts        |        ends         | venue_id
------------+-----------------+---------------------+---------------------+----------
--        1 | LARP Club       | 2012-02-15 17:30:00 | 2012-02-15 19:30:00 |        2
--        2 | April Fools Day | 2012-04-01 00:00:00 | 2012-04-01 23:59:59 |
--        3 | Christmas Day   | 2012-12-25 00:00:00 | 2012-12-25 23:59:59 |
--        4 | Moby            | 2012-02-06 21:00:00 | 2012-02-06 23:00:00 |        1
--        5 | Wedding         | 2012-02-26 21:00:00 | 2012-02-26 23:00:00 |        2
--        6 | Tour            | 2012-02-26 18:00:00 | 2012-02-26 20:30:00 |        3
--        7 | Valentine's Day | 2012-02-14 00:00:00 | 2012-02-14 23:59:00 |
--(7 rows)

--Stored Procedures
-- client side vs db side decision
--  cost depends a lot on your situation - do you want to send 1000s of rows to app? or solve in db and send one result?
-- also keep in mind vendor lock-in -> always going to be a thing

--\i /sql/add_event.sql
--select add_event('House Party', '2012-05-03 23:00', '2012-05-04 02:00', 'Run''s House', '97205', 'us');
--NOTICE:  Venue found 4
-- add_event
-------------
-- t
--(1 row)

--Triggers - fire stored procedures when some event happens
-- before or after updates/inserts

--Views
-- use the results of a complex query just like a table
-- not functions, but aliased queries
--book=# select name, to_char(date, 'Month DD, YYYY') as date from holidays where date <= '2012-04-01';
--      name       |        date
-------------------+--------------------
-- April Fools Day | April     01, 2012
-- Valentine's Day | February  14, 2012
--(2 rows)
-- cannot directly update a view... need rules

--Rules
-- how to alter the parsed query tree
-- every time we run a sql statement - statement -> abstract syntax tree
--  we can rewrite this tree using rules before sending to the planner (optimizations)
-- views are rules
--book=# explain verbose select * from holidays;
--                                    QUERY PLAN
-------------------------------------------------------------------------------------
-- Seq Scan on public.events  (cost=0.00..1.04 rows=1 width=528)
--   Output: events.event_id, events.title, events.starts
--   Filter: ((events.venue_id IS NULL) AND ((events.title)::text ~~ '%Day%'::text))
--(3 rows)
--would need insert/delete rules as well

--crosstab
--used to build a pivot table
select extract(year from starts) as year,
       extract(month from starts) as month,
       count(*)
    from events
    group by year, month
    order by year, month;
--use of crosstab - query must return rowid,category,value
select * from crosstab(
    'select extract(year from starts) as year,
            extract(month from starts) as month,
            count(*)
        from events
        group by year, month
        order by year, month',
    'select * from generate_series(1,12)'
);
--ERROR:  function crosstab(unknown, unknown) does not exist
--LINE 1: SELECT * FROM crosstab(
--                      ^
--HINT:  No function matches the given name and argument types. You might need to add explicit type casts.
--create extension tablefunc;
--retry...
-- get:
--ERROR:  a column definition list is required for functions returning "record"
--LINE 1: SELECT * FROM crosstab(
--                      ^
-- function is returning a set of records(rows) but it doesn't know how to label them or what the datatypes are
select * from crosstab(
    'select extract(year from starts) as year,
            extract(month from starts) as month,
            count(*)
        from events
        group by year, month
        order by year, month',
    'select * from generate_series(1,12)'
) as (
    year int,
    jan int, feb int, mar int, apr int, may int, jun int, jul int, aug int, sep int, oct int, nov int, dec int
) order by year;
-- year | jan | feb | mar | apr | may | jun | jul | aug | sep | oct | nov | dec
--------+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+-----
-- 2012 |     |   5 |     |   1 |   1 |     |     |     |     |     |     |   1
--(1 row)

--day 2, problem 1
--https://www.postgresql.org/docs/9.5/static/functions-aggregate.html

--day 2, problem 2
---1 - create a rule that captures deletes on venues and instead sets the active flag to false
----book=# \i /sql/delete_venue_rule.sql
----CREATE RULE
----book=# delete from venues where venue_id = 1;
----DELETE 0
----book=# select * from venues;
---- venue_id |       name       |  street_address   |  type   | postal_code | country_code | active
--------------+------------------+-------------------+---------+-------------+--------------+--------
----        2 | Voodoo Donuts    |                   | public  | 97205       | us           |
----        3 | Texas Capitol    | 1100 Congress Ave | public  | 78701       | us           | t
----        4 | Run's House      |                   | public  | 97205       | us           | t
----        1 | Crystal Ballroom |                   | public  | 97205       | us           | f
----(4 rows)
----NOTICE: Crystal ballroom active is now false

---2
---NOTICE - using generate_series as opposed to `select * from month_count;`

---3 - build pivot table that displays every day in a single month, where each week is a row and each day forms a column (sun - sat)
---select extract(year from starts) as year,
---       extract(month from starts) as month,
---       extract(day from starts) as day,
---       count(*)
---from events
---group by year, month, day
---order by year, month, day;
--- year | month | day | count
---------+-------+-----+-------
--- 2012 |     2 |   6 |     1
--- 2012 |     2 |  14 |     1
--- 2012 |     2 |  15 |     1
--- 2012 |     2 |  26 |     2
--- 2012 |     4 |   1 |     1
--- 2012 |     5 |   3 |     1
--- 2012 |    12 |  25 |     1
---(7 rows)
---
---tacking on `having extract(month from starts)=2` after `day` in group by gets me only feb events
select * from crosstab(
    'select extract(week from starts) as week,
            extract(day from starts) as day,
            count(*)
        from events
        group by week, day
        order by week, day',
    'select * from generate_series(1,7)'
) as (
    week int,
    sun int, mon int, tues int, wed int, thurs int, fri int, sat int
) order by week;
-- this ^^ kinda works... doesn't give me all the weeks or days
-- this vv gives me all the days with the corresponding week
select extract(week from ts) as week,
       extract(day from ts) as day
from generate_series(
  format('2012-%s-01', 02)::timestamp,
  format('2012-%s-01', 02)::timestamp + interval '1 month' - interval '1 day',
  interval '1 day'
) as ts;
--
select extract(week from ts) as week,
       extract(day from ts) as day
from generate_series(
  (select min(starts) from events),
  (select max(ends) from events),
  interval '1 day'
)
as ts;
--
select extract(week from e.starts) as week,
       extract(day from e.starts) as day,
       count(*)
from month_weeks_days m
full join events e on m.month = 2 AND m.week = extract(week from e.starts) AND m.day = extract(day from e.starts);
--
create temporary table ts_span(ts timestamp);
---gets a span of timestamps for entire events range
insert into ts_span select ts from generate_series(
    (select min(starts) from events),
    (select max(starts) from events),
    interval '1 day'
);
---full join, gets me all weeks, day with an associated count from events!!
select extract(week from t.ts) as week,
       extract(day from t.ts) as day,
       count(e.*)
from ts_span t
full join events e on
extract(week from t.ts) = extract(week from e.starts) and
extract(day from t.ts) = extract(day from e.starts)
group by week, day
order by week, day;
---now the pivot
select * from crosstab(
    'select extract(week from t.ts) as week,
            extract(day from t.ts) as day,
            count(e.*)
     from ts_span t
     full join events e on
     extract(week from t.ts) = extract(week from e.starts) and
     extract(day from t.ts) = extract(day from e.starts)
     group by week, day
     order by week, day;',
    'select * from generate_series(1,7)'
) as (
    week int,
    sun int, mon int, tues int, wed int, thurs int, fri int, sat int
) order by week;
---close...but missing some days, i think it has to do with:
----day is the attribute here, and doesn't map to 1-7, they're the actual day...modulo?
----also drop to 0-6
select * from crosstab(
    'select extract(week from t.ts) as week,
            cast(extract(day from t.ts) as int) % 7 as day,
            count(e.*)
     from ts_span t
     full join events e on
     extract(week from t.ts) = extract(week from e.starts) and
     extract(day from t.ts) = extract(day from e.starts)
     group by week, day
     order by week, day;',
    'select * from generate_series(0,6)'
) as (
    week int,
    sun int, mon int, tues int, wed int, thurs int, fri int, sat int
) order by week;
----closer...some dates still blank
----ok looking at original query, i do not want to actually group by week, day for the ts_span table
----i think i need an intermediate query of just the aggregated events
create temporary table events_per_week_day(week int, day int, total int);

insert into events_per_week_day
select extract(week from starts) as week,
       extract(day from starts) as day,
       count(*)
from events
group by week, day;

----looking good
select extract(week from t.ts) as week,
       extract(day from t.ts) as day,
       e.total
from ts_span t
full join events_per_week_day e on
extract(week from t.ts) = e.week and
extract(day from t.ts) = e.day;
select * from crosstab(
    'select extract(week from t.ts) as week,
            cast(extract(day from t.ts) as integer) % 7 as day,
            e.total
     from ts_span t
     full join events_per_week_day e on
     extract(week from t.ts) = e.week and
     extract(day from t.ts) = e.day;',
     --and extract(month from t.ts) = month_no
    'select * from generate_series(0,6)'
) as (
    week int,
    sun int, mon int, tues int, wed int, thurs int, fri int, sat int
) order by week;
----Success!
