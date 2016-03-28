-- SEQUENCES

CREATE SEQUENCE qw_id_seq;
CREATE SEQUENCE qw_event_seq;

-- TABLES

CREATE TABLE qw$app (
    name VARCHAR(16),
    update_t TIMESTAMP DEFAULT now(),
    db_version VARCHAR(32),
    cli_version VARCHAR(32),
    PRIMARY KEY(name,update_t)
);

CREATE TABLE qw$prop (
    id INT4 NOT NULL,     -- ID of object property is applied to
    key VARCHAR(64),      -- Protperty is key/value pair
    valid_t TIMESTAMP DEFAULT now(),
    value VARCHAR(128),   -- New property value
    username VARCHAR(32), -- Username for auditing
    PRIMARY KEY (id, key, valid_t)
);

CREATE TABLE qw$event (
    seq INT4 NOT NULL PRIMARY KEY DEFAULT nextval('qw_event_seq'),
    create_t TIMESTAMP NOT NULL DEFAULT now(),
    id INT4 NOT NULL,              -- ID of object associated with event
    event VARCHAR(16) NOT NULL,    -- Event type string
    username VARCHAR(32),
    description TEXT,
    data XML
);
CREATE INDEX qw$event_search ON qw$event (id,event,username);

CREATE TABLE qw$xml (
    id INT4 NOT NULL,
    valid_t TIMESTAMP DEFAULT now(),
    data XML,
    PRIMARY KEY(id, valid_t)
);

CREATE TABLE qw$json (
    id INT4 NOT NULL,
    valid_t TIMESTAMP DEFAULT now(),
    data JSONB,
    PRIMARY KEY(id, valid_t)
);

