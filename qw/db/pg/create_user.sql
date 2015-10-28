-- CREATE USER
CREATE ROLE qw WITH LOGIN PASSWORD 'question';

-- This will allow virtual files
UPDATE pg_authid SET rolcatupdate = true WHERE rolname = 'qw';
GRANT INSERT,DELETE ON pg_catalog.pg_largeobject TO qw;

