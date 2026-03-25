CREATE TABLE lrs_substatement (
    id                      SERIAL PRIMARY KEY,
    object_agent_id         INT  REFERENCES lrs_agent(id)    ON DELETE SET NULL,
    object_activity_id      INT  REFERENCES lrs_activity(id) ON DELETE SET NULL,
    object_statementref     UUID,
    actor_id                INT  REFERENCES lrs_agent(id)    ON DELETE SET NULL,
    verb_id                 INT  REFERENCES lrs_verb(id)     ON DELETE SET NULL,
    result_success          BOOLEAN,
    result_completion       BOOLEAN,
    result_response         TEXT         NOT NULL DEFAULT '',
    result_duration         VARCHAR(40)  NOT NULL DEFAULT '',
    result_score_scaled     DOUBLE PRECISION,
    result_score_raw        DOUBLE PRECISION,
    result_score_min        DOUBLE PRECISION,
    result_score_max        DOUBLE PRECISION,
    result_extensions       JSONB        NOT NULL DEFAULT '{}',
    "timestamp"             TIMESTAMPTZ,
    context_registration    VARCHAR(40)  NOT NULL DEFAULT '',
    context_instructor_id   INT  REFERENCES lrs_agent(id)    ON DELETE SET NULL,
    context_team_id         INT  REFERENCES lrs_agent(id)    ON DELETE SET NULL,
    context_revision        TEXT         NOT NULL DEFAULT '',
    context_platform        VARCHAR(50)  NOT NULL DEFAULT '',
    context_language        VARCHAR(50)  NOT NULL DEFAULT '',
    context_extensions      JSONB        NOT NULL DEFAULT '{}',
    context_contextAgents   JSONB        NOT NULL DEFAULT '[]',
    context_contextGroups   JSONB        NOT NULL DEFAULT '[]',
    context_statement       VARCHAR(40)  NOT NULL DEFAULT ''
);

CREATE INDEX lrs_substatement_object_agent_id_idx       ON lrs_substatement (object_agent_id);
CREATE INDEX lrs_substatement_object_activity_id_idx    ON lrs_substatement (object_activity_id);
CREATE INDEX lrs_substatement_object_statementref_idx   ON lrs_substatement (object_statementref);
CREATE INDEX lrs_substatement_context_registration_idx  ON lrs_substatement (context_registration);
CREATE INDEX lrs_substatement_context_instructor_id_idx ON lrs_substatement (context_instructor_id);

-- ManyToManyField(Activity, related_name="sub_context_ca_parent")
CREATE TABLE lrs_substatement_context_ca_parent (
    substatement_id INT NOT NULL REFERENCES lrs_substatement(id) ON DELETE CASCADE,
    activity_id     INT NOT NULL REFERENCES lrs_activity(id)     ON DELETE CASCADE,
    PRIMARY KEY (substatement_id, activity_id)
);

-- ManyToManyField(Activity, related_name="sub_context_ca_grouping")
CREATE TABLE lrs_substatement_context_ca_grouping (
    substatement_id INT NOT NULL REFERENCES lrs_substatement(id) ON DELETE CASCADE,
    activity_id     INT NOT NULL REFERENCES lrs_activity(id)     ON DELETE CASCADE,
    PRIMARY KEY (substatement_id, activity_id)
);

-- ManyToManyField(Activity, related_name="sub_context_ca_category")
CREATE TABLE lrs_substatement_context_ca_category (
    substatement_id INT NOT NULL REFERENCES lrs_substatement(id) ON DELETE CASCADE,
    activity_id     INT NOT NULL REFERENCES lrs_activity(id)     ON DELETE CASCADE,
    PRIMARY KEY (substatement_id, activity_id)
);

-- ManyToManyField(Activity, related_name="sub_context_ca_other")
CREATE TABLE lrs_substatement_context_ca_other (
    substatement_id INT NOT NULL REFERENCES lrs_substatement(id) ON DELETE CASCADE,
    activity_id     INT NOT NULL REFERENCES lrs_activity(id)     ON DELETE CASCADE,
    PRIMARY KEY (substatement_id, activity_id)
);