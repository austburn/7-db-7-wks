create or replace function log_event() returns trigger as $$
  declare
  begin
    insert into logs (event_id, old_title, old_starts, old_ends)
      values (old.event_id, old.title, old.starts, old.ends);
    raise notice 'Someone just changed event #%', old.event_id;
    return new;
  end;
  $$ language plpgsql;
