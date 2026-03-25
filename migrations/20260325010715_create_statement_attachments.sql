CREATE TABLE lrs_statementattachment (
     id             SERIAL PRIMARY KEY,
     canonical_data JSONB        NOT NULL DEFAULT '{}',
     payload        VARCHAR(150),
     statement_id   INT REFERENCES lrs_statement(id) ON DELETE CASCADE
);