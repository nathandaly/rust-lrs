CREATE TABLE lrs_relevanttype (
    id            SERIAL PRIMARY KEY,
    "relevantType" VARCHAR(2083) NOT NULL DEFAULT ''
);

CREATE INDEX lrs_relevanttype_relevanttype_idx ON lrs_relevanttype ("relevantType");