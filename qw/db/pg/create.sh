#!/bin/bash
PG_CONTAINER_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' qw-postgres)
PGPASSWORD=postgres psql -h $PG_CONTAINER_IP -d postgres -U postgres -f create_postgres.sql
PGPASSWORD=question psql -h $PG_CONTAINER_IP -d qw -U qw -f create_qw.sql
