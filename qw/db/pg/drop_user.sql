-- DROP USER

REVOKE INSERT,DELETE ON pg_catalog.pg_largeobject FROM qw;
DROP ROLE qw;

