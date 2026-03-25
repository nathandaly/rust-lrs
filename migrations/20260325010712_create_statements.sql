CREATE TABLE lrs_statement (
    id                       SERIAL PRIMARY KEY,
    statement_id             UUID         NOT NULL DEFAULT gen_random_uuid(),
    object_agent_id          INT  REFERENCES lrs_agent(id)         ON DELETE SET NULL,
    object_activity_id       INT  REFERENCES lrs_activity(id)      ON DELETE SET NULL,
    object_substatement_id   INT  REFERENCES lrs_substatement(id)  ON DELETE SET NULL,
    object_statementref      UUID,
    actor_id                 INT  REFERENCES lrs_agent(id)         ON DELETE SET NULL,
    verb_id                  INT  REFERENCES lrs_verb(id)          ON DELETE SET NULL,
    result_success           BOOLEAN,
    result_completion        BOOLEAN,
    result_response          TEXT         NOT NULL DEFAULT '',
    result_duration          VARCHAR(40)  NOT NULL DEFAULT '',
    result_score_scaled      DOUBLE PRECISION,
    result_score_raw         DOUBLE PRECISION,
    result_score_min         DOUBLE PRECISION,
    result_score_max         DOUBLE PRECISION,
    result_extensions        JSONB        NOT NULL DEFAULT '{}',
    stored                   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    "timestamp"              TIMESTAMPTZ  NOT NULL,
    authority_id             INT  REFERENCES lrs_agent(id)         ON DELETE SET NULL,
    voided                   BOOLEAN      DEFAULT FALSE,
    context_registration     VARCHAR(40)  NOT NULL DEFAULT '',
    context_instructor_id    INT  REFERENCES lrs_agent(id)         ON DELETE SET NULL,
    context_team_id          INT  REFERENCES lrs_agent(id)         ON DELETE SET NULL,
    context_revision         TEXT         NOT NULL DEFAULT '',
    context_platform         VARCHAR(50)  NOT NULL DEFAULT '',
    context_language         VARCHAR(50)  NOT NULL DEFAULT '',
    context_extensions       JSONB        NOT NULL DEFAULT '{}',
    context_contextAgents    JSONB        NOT NULL DEFAULT '[]',
    context_contextGroups    JSONB        NOT NULL DEFAULT '[]',
    context_statement        VARCHAR(40)  NOT NULL DEFAULT '',
    version                  VARCHAR(7)   NOT NULL,
    user_id                  INT  REFERENCES auth_user(id)         ON DELETE SET NULL,
    full_statement           JSONB        NOT NULL
);

CREATE INDEX lrs_statement_statement_id_idx          ON lrs_statement (statement_id);
CREATE INDEX lrs_statement_stored_idx                ON lrs_statement (stored);
CREATE INDEX lrs_statement_timestamp_idx             ON lrs_statement ("timestamp");
CREATE INDEX lrs_statement_object_agent_id_idx       ON lrs_statement (object_agent_id);
CREATE INDEX lrs_statement_object_activity_id_idx    ON lrs_statement (object_activity_id);
CREATE INDEX lrs_statement_object_statementref_idx   ON lrs_statement (object_statementref);
CREATE INDEX lrs_statement_actor_id_idx              ON lrs_statement (actor_id);
CREATE INDEX lrs_statement_authority_id_idx          ON lrs_statement (authority_id);
CREATE INDEX lrs_statement_context_registration_idx  ON lrs_statement (context_registration);
CREATE INDEX lrs_statement_context_instructor_id_idx ON lrs_statement (context_instructor_id);
CREATE INDEX lrs_statement_user_id_idx               ON lrs_statement (user_id);

-- ManyToManyField(Activity, related_name="stmt_context_ca_parent")
CREATE TABLE lrs_statement_context_ca_parent (
     statement_id INT NOT NULL REFERENCES lrs_statement(id) ON DELETE CASCADE,
     activity_id  INT NOT NULL REFERENCES lrs_activity(id)  ON DELETE CASCADE,
     PRIMARY KEY (statement_id, activity_id)
);

-- ManyToManyField(Activity, related_name="stmt_context_ca_grouping")
CREATE TABLE lrs_statement_context_ca_grouping (
    statement_id INT NOT NULL REFERENCES lrs_statement(id) ON DELETE CASCADE,
    activity_id  INT NOT NULL REFERENCES lrs_activity(id)  ON DELETE CASCADE,
    PRIMARY KEY (statement_id, activity_id)
);

-- ManyToManyField(Activity, related_name="stmt_context_ca_category")
CREATE TABLE lrs_statement_context_ca_category (
    statement_id INT NOT NULL REFERENCES lrs_statement(id) ON DELETE CASCADE,
    activity_id  INT NOT NULL REFERENCES lrs_activity(id)  ON DELETE CASCADE,
    PRIMARY KEY (statement_id, activity_id)
);

-- ManyToManyField(Activity, related_name="stmt_context_ca_other")
CREATE TABLE lrs_statement_context_ca_other (
    statement_id INT NOT NULL REFERENCES lrs_statement(id) ON DELETE CASCADE,
    activity_id  INT NOT NULL REFERENCES lrs_activity(id)  ON DELETE CASCADE,
    PRIMARY KEY (statement_id, activity_id)
);