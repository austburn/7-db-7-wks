select v.venue_id, v.name, c.name from venues v
  inner join cities c
  on v.postal_code=c.postal_code and v.country_code=c.country_code;
--inner join by default, returns _only_ if values match
select e.title, v.name from events e join venues v on e.venue_id = v.venue_id;
--includes _all_ values from left table, joined wherever values match
select e.title, v.name from events e left join venues v on e.venue_id = v.venue_id;
--includes _all_ values from right table, joined wherever values match
select e.title, v.name from events e right join venues v on e.venue_id = v.venue_id;
--includes _all_ values from both table, joined wherever values match
select e.title, v.name from events e full join venues v on e.venue_id = v.venue_id;

select * from events where starts >= '2012-04-01';

--day 1 problem 2
select c.country_name, e.title from countries c
  join venues v on v.country_code = c.country_code
  join events e on v.venue_id = e.venue_id
  where e.title = 'LARP Club';
--day 1 problem 3
alter table if exists venues add column if not exists active boolean, alter column active set default true;
