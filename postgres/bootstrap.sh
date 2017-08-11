#!/bin/bash

docker build --tag postgres-bs .

docker_status=$(docker inspect --format "{{ .State.Status }}" postgres)

if [ "$docker_status" = "exited" ]; then
    docker rm -f postgres
    docker run -d --name postgres postgres
elif [ "$docker_status" != "running" ]; then
    docker run -d --name postgres postgres
fi

while ! docker run -it --link postgres:postgres postgres /bin/bash -c "psql -h postgres -U postgres -c '\d'"; do
    echo waiting for postgres to become available
done


docker run -it --link postgres:postgres postgres-bs

