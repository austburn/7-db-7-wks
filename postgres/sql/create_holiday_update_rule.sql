create rule update_holidays as on update to holidays do instead
  update events
    set title = new.name,
        starts = new.date,
        colors = new.colors
    where title = old.name;
