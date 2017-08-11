--insert the data
\i /data/movies_data.sql
select title from movies where title ilike 'stardust%';
--makes sure the title is not Stardust
select title from movies where title ilike 'stardust_%';
--number of movies that do not (!) have (~) a title that starts with the (case insensitive (*))
select count(*) from movies where title !~* '^the.*';
--https://dba.stackexchange.com/questions/53811/why-would-you-index-text-pattern-ops-on-a-text-column
--https://dba.stackexchange.com/questions/10694/pattern-matching-with-like-similar-to-or-regular-expressions-in-postgresql/10696
--https://stackoverflow.com/questions/26458548/in-postgresql-which-part-of-locale-causes-problems-with-like-operations
--https://www.postgresql.org/docs/current/static/locale.html
--https://www.postgresql.org/docs/9.6/static/indexes-types.html
--useful mostly when not using the C locale (becoming less common, mine was en_US.utf8)
create index movies_title_pattern on movies (lower(title) text_pattern_ops);
--from fuzzystrmatch, detects steps to go from bat -> fads
select levenshtein('bat', 'fads');
-- levenshtein
---------------
--           3
--(1 row)
--b=>f, t=>d, +s
--levenshtein is case sensitive, so you can convert case based on search
select movie_id, title from movies where levenshtein(lower(title), lower(​'a hard day nght'​)) <= 3;
select show_trgm('Avatar');
--              show_trgm
---------------------------------------
-- {"  a"," av","ar ",ata,ava,tar,vat}
--(1 row)
--uses trigram index we created (movies_title_trigram)
--good choice for accepting user input without the weight of a wildcard
select title from movies where title % 'Avatre';

select title from movies where title @@ 'night & day';
--             title
---------------------------------
-- A Hard Day's Night
-- Six Days Seven Nights
-- Long Day's Journey Into Night
--(3 rows)
--notice that night and day don't have to be in order
--title => tsvector (list of tokens), the query specifies that the title contain night and day (boolean)
select title from movies where to_tsvector(title) @@ to_tsquery('english', 'night & day');
--to show the breakdown:
select to_tsvector('A Hard Day''s Night'), to_tsquery('english', 'night & day');
--        to_tsvector         |   to_tsquery
------------------------------+-----------------
-- 'day':3 'hard':2 'night':5 | 'night' & 'day'
--(1 row)

select * from movies where title @@ 'a';
--...
--NOTICE:  text-search query contains only stop words or doesn't contain lexemes, ignored
-- movie_id | title | genre
------------+-------+-------
--(0 rows)
---'a' is considered a stop word in the english dictionary for postgres
---cat `pg_config --sharedir`/tsearch_data/english.stop
---we can use the simple dictionary if we really want to
select * from movies where to_ts_vector('simple', title) @@ to_tsquery('simple', 'a');

explain select * from movies where title @@ 'night & day';
--                        QUERY PLAN
------------------------------------------------------------
-- Seq Scan on movies  (cost=0.00..815.86 rows=3 width=171)
--   Filter: (title @@ 'night & day'::text)
--(2 rows)
--- Seq Scan on movies means a whole table scan => bad
--create index if not exists movies_title_searchable on movies using gin(to_tsvector('english', title));
explain select * from movies where title @@ 'night & day';
--                        QUERY PLAN
------------------------------------------------------------
-- Seq Scan on movies  (cost=0.00..815.86 rows=3 width=171)
--   Filter: (title @@ 'night & day'::text)
--(2 rows)
---Postgres is NOT using our index
---This is because our index specifies the english requirement
explain select * from movies where to_tsvector('english', title) @@ 'night & day';
--                                            QUERY PLAN
----------------------------------------------------------------------------------------------------
-- Bitmap Heap Scan on movies  (cost=20.00..24.26 rows=1 width=171)
--   Recheck Cond: (to_tsvector('english'::regconfig, title) @@ '''night'' & ''day'''::tsquery)
--   ->  Bitmap Index Scan on movies_title_searchable  (cost=0.00..20.00 rows=1 width=0)
--         Index Cond: (to_tsvector('english'::regconfig, title) @@ '''night'' & ''day'''::tsquery)
--(4 rows)

--Metaphones
---algorithm for creating a string representation of word sounds
select * from actors where metaphone(name, 6) = metaphone('Broos Willis', 6);
-- actor_id |     name
------------+--------------
--      573 | Bruce Willis
--(1 row)

--natural join is an inner join that automatically joins on matching column names (actor_id)
select title from movies natural join movies_actors natural join actors where metaphone(name, 6) = metaphone('Broos Willis', 6);

--get me the names that sound most like robin williams, in order
select * from actors where metaphone(name, 8) % metaphone('robin williams', 8) order by levenshtein('robin williams', lower(name));
-- actor_id |      name
------------+-----------------
--     4093 | Robin Williams
--     2442 | John Williams
--     4479 | Steven Williams
--     4090 | Robin Shou
--(4 rows)
