-- VIEWS

CREATE VIEW qw$view$properties AS
    SELECT id,key,value,username FROM qw$prop p WHERE valid_t in (
        SELECT max(valid_t) FROM qw$prop t WHERE t.id = p.id and t.key = p.key
    );

CREATE VIEW qw$view$valid_properties AS
    SELECT p.id AS id,p.key AS key,p.value AS value,p.username AS username FROM qw$prop p
    JOIN
    (SELECT id, key, max(valid_t) AS latest FROM qw$prop GROUP BY id, key) l
    ON p.id = l.id AND p.key = l.key AND p.valid_t = l.latest;
