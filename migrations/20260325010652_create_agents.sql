CREATE TABLE lrs_agent (
   id                SERIAL PRIMARY KEY,
   "objectType"      VARCHAR(6)    NOT NULL DEFAULT 'Agent',
   name              VARCHAR(100)  NOT NULL DEFAULT '',
   mbox              VARCHAR(128)  UNIQUE,
   mbox_sha1sum      VARCHAR(40)   UNIQUE,
   openid            VARCHAR(2083) UNIQUE,
   oauth_identifier  VARCHAR(192)  UNIQUE,
   account_homePage  VARCHAR(2083),
   account_name      VARCHAR(50),
   user_id           INT           UNIQUE REFERENCES auth_user(id) ON DELETE SET NULL,
   UNIQUE (account_homePage, account_name)
);

CREATE INDEX lrs_agent_mbox_idx             ON lrs_agent (mbox);
CREATE INDEX lrs_agent_mbox_sha1sum_idx     ON lrs_agent (mbox_sha1sum);
CREATE INDEX lrs_agent_openid_idx           ON lrs_agent (openid);
CREATE INDEX lrs_agent_oauth_identifier_idx ON lrs_agent (oauth_identifier);

-- ManyToManyField('self') — Django names this lrs_agent_member
-- symmetrical=False is implied by related_name="agents" being set
CREATE TABLE lrs_agent_member (
  from_agent_id INT NOT NULL REFERENCES lrs_agent(id) ON DELETE CASCADE,
  to_agent_id   INT NOT NULL REFERENCES lrs_agent(id) ON DELETE CASCADE,
  PRIMARY KEY (from_agent_id, to_agent_id)
);