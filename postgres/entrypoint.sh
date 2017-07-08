#!/bin/bash

psql -h postgres -U postgres -f /sql/init.sql

exec "$@"
