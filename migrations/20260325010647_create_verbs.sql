CREATE TABLE lrs_verb (
    id             SERIAL PRIMARY KEY,
    verb_id        VARCHAR(2083) NOT NULL UNIQUE,
    canonical_data JSONB         NOT NULL DEFAULT '{}'
);

CREATE INDEX lrs_verb_verb_id_idx ON lrs_verb (verb_id);