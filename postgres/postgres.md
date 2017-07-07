Postgres
========

`./bootstrap.sh`

CREATE EXTENSION bit pulled from https://stackoverflow.com/questions/12589127/trouble-installing-additional-module-cube-in-postgresql-8-4.
```bash
root@bf326d368da7:/# createdb -h postgres -U postgres book
root@bf326d368da7:/# psql -h postgres -U postgres book -c "SELECT '1'::cube;"
ERROR:  type "cube" does not exist
LINE 1: SELECT '1'::cube;
                    ^
root@bf326d368da7:/# psql -h postgres -U postgres book -c "CREATE EXTENSION cube;"
CREATE EXTENSION
root@bf326d368da7:/# psql -h postgres -U postgres book -c "SELECT '1'::cube;"
 cube
------
 (1)
(1 row)

```
