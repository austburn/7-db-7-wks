FROM postgres:9.6

ADD sql /sql
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["psql", "-h", "postgres", "-U", "postgres", "book"]
