#!/bin/bash
PG_CONTAINER_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' qw-postgres)
PGPASSWORD=question psql -h $PG_CONTAINER_IP -d qw -U qw -f drop_qw.sql
PGPASSWORD=postgres psql -h $PG_CONTAINER_IP -d postgres -U postgres -f drop_postgres.sql
