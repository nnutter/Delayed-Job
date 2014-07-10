DROP SCHEMA IF EXISTS delayed CASCADE;
CREATE SCHEMA delayed;

CREATE TABLE delayed.job (
    id uuid NOT NULL,
    handler_class text,
    method text,
    handler_data json,
    args json,
    PRIMARY KEY (id)
);

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE delayed.job TO delayed;
