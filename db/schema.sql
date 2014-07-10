DROP SCHEMA IF EXISTS delayed CASCADE;
CREATE SCHEMA delayed;

CREATE TABLE delayed.job (
    id uuid NOT NULL,
    handler json,
    method text,
    args json,
    PRIMARY KEY (id)
);

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE delayed.job TO delayed;
