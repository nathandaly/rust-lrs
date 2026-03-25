CREATE TABLE lrs_activity (
    id             SERIAL PRIMARY KEY,
    activity_id    VARCHAR(2083) NOT NULL UNIQUE,
    canonical_data JSONB         NOT NULL DEFAULT '{}',
    authority_id   INT REFERENCES lrs_agent(id) ON DELETE CASCADE
);

CREATE INDEX lrs_activity_activity_id_idx ON lrs_activity (activity_id);