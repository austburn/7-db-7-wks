create view holidays as
  select event_id as holiday_id, title as name, starts as date, colors
  from events
  where title like '%Day%' and venue_id is null;
