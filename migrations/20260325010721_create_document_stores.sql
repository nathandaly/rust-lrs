-- ActivityState
CREATE TABLE lrs_activitystate (
    id               SERIAL PRIMARY KEY,
    state_id         VARCHAR(2083) NOT NULL,
    updated          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    activity_id      VARCHAR(2083) NOT NULL,
    registration_id  VARCHAR(40)   NOT NULL DEFAULT '',
    content_type     VARCHAR(255)  NOT NULL DEFAULT '',
    etag             VARCHAR(50)   NOT NULL DEFAULT '',
    agent_id         INT           NOT NULL REFERENCES lrs_agent(id) ON DELETE CASCADE,
    json_state       JSONB         NOT NULL DEFAULT '{}',
    state            VARCHAR(100)  -- FileField upload_to path
);

CREATE INDEX lrs_activitystate_updated_idx         ON lrs_activitystate (updated);
CREATE INDEX lrs_activitystate_activity_id_idx     ON lrs_activitystate (activity_id);
CREATE INDEX lrs_activitystate_registration_id_idx ON lrs_activitystate (registration_id);

-- ActivityProfile
CREATE TABLE lrs_activityprofile (
     id           SERIAL PRIMARY KEY,
     profile_id   VARCHAR(2083) NOT NULL,
     updated      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
     activity_id  VARCHAR(2083) NOT NULL,
     content_type VARCHAR(255)  NOT NULL DEFAULT '',
     etag         VARCHAR(50)   NOT NULL DEFAULT '',
     json_profile JSONB         NOT NULL DEFAULT '{}',
     profile      VARCHAR(100)  -- FileField upload_to path
);

CREATE INDEX lrs_activityprofile_profile_id_idx  ON lrs_activityprofile (profile_id);
CREATE INDEX lrs_activityprofile_updated_idx     ON lrs_activityprofile (updated);
CREATE INDEX lrs_activityprofile_activity_id_idx ON lrs_activityprofile (activity_id);

-- AgentProfile
CREATE TABLE lrs_agentprofile (
    id           SERIAL PRIMARY KEY,
    profile_id   VARCHAR(2083) NOT NULL,
    updated      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    content_type VARCHAR(255)  NOT NULL DEFAULT '',
    etag         VARCHAR(50)   NOT NULL DEFAULT '',
    agent_id     INT           NOT NULL REFERENCES lrs_agent(id) ON DELETE CASCADE,
    json_profile JSONB         NOT NULL DEFAULT '{}',
    profile      VARCHAR(100)  -- FileField upload_to path
);

CREATE INDEX lrs_agentprofile_profile_id_idx ON lrs_agentprofile (profile_id);
CREATE INDEX lrs_agentprofile_updated_idx    ON lrs_agentprofile (updated);
CREATE INDEX lrs_agentprofile_agent_id_idx   ON lrs_agentprofile (agent_id);