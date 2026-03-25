CREATE TABLE lrs_contextagent (
    id           SERIAL PRIMARY KEY,
    "objectType" VARCHAR(14) NOT NULL DEFAULT 'contextAgent',
    agent_id     INT REFERENCES lrs_agent(id) ON DELETE SET NULL
);

CREATE INDEX lrs_contextagent_agent_id_idx ON lrs_contextagent (agent_id);

-- ManyToManyField(RelevantType, related_name="conag_relevantType")
CREATE TABLE lrs_contextagent_relevanttype (
    contextagent_id  INT NOT NULL REFERENCES lrs_contextagent(id)  ON DELETE CASCADE,
    relevanttype_id  INT NOT NULL REFERENCES lrs_relevanttype(id)  ON DELETE CASCADE,
    PRIMARY KEY (contextagent_id, relevanttype_id)
);

CREATE TABLE lrs_contextgroup (
    id           SERIAL PRIMARY KEY,
    "objectType" VARCHAR(14) NOT NULL DEFAULT 'contextGroup',
    group_id     INT REFERENCES lrs_agent(id) ON DELETE SET NULL
);

CREATE INDEX lrs_contextgroup_group_id_idx ON lrs_contextgroup (group_id);

-- ManyToManyField(RelevantType, related_name="congrp_relevantType")
CREATE TABLE lrs_contextgroup_relevanttype (
    contextgroup_id  INT NOT NULL REFERENCES lrs_contextgroup(id)  ON DELETE CASCADE,
    relevanttype_id  INT NOT NULL REFERENCES lrs_relevanttype(id)  ON DELETE CASCADE,
    PRIMARY KEY (contextgroup_id, relevanttype_id)
);