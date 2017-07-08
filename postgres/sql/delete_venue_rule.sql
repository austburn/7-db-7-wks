create rule delete_venue as on delete to venues do instead
  update venues
    set active = false
    where name = old.name;
