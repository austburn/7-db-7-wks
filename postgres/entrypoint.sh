#!/bin/bash

psql -h postgres -U postgres -f /init.sql

exec "$@"
