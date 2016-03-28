-- CREATE USER
CREATE ROLE qw WITH LOGIN PASSWORD 'question';

-- This will allow virtual files
-- UPDATE pg_authid SET rolcatupdate = true WHERE rolname = 'qw';
GRANT INSERT,DELETE ON pg_catalog.pg_largeobject TO qw;

-- CREATE DATABASE
CREATE DATABASE qw WITH owner = qw;

-- Grant access to qw table to qw
GRANT ALL ON DATABASE qw TO qw;

