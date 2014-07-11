DROP SCHEMA IF EXISTS delayed CASCADE;
CREATE SCHEMA delayed;

CREATE TABLE delayed.job (
    id uuid NOT NULL,
    handler_class text,
    method text,
    handler_data json,
    args json,
    queue text,
    priority int4,
    attempts int4,
    run_at timestamp with time zone,
    failed_at timestamp with time zone,
    created_at timestamp with time zone,
    PRIMARY KEY (id)
);

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE delayed.job TO delayed;
