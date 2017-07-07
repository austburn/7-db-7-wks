FROM postgres:9.6

ADD init.sql /init.sql
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["psql", "-h", "postgres", "-U", "postgres", "book"]
