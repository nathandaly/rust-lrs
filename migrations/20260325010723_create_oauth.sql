-- Nonce
CREATE TABLE oauth_provider_nonce (
    id           SERIAL PRIMARY KEY,
    token_key    VARCHAR(32)  NOT NULL,
    consumer_key VARCHAR(256) NOT NULL,
    key          VARCHAR(255) NOT NULL,
    "timestamp"  INTEGER      NOT NULL
);

CREATE INDEX oauth_provider_nonce_timestamp_idx ON oauth_provider_nonce ("timestamp");

-- Consumer
CREATE TABLE oauth_provider_consumer (
     id              SERIAL PRIMARY KEY,
     name            VARCHAR(255) NOT NULL,
     description     TEXT         NOT NULL DEFAULT '',
     key             VARCHAR(256) NOT NULL,
     secret          VARCHAR(2048) NOT NULL DEFAULT '',
     rsa_signature   BOOLEAN      NOT NULL DEFAULT FALSE,
     status          SMALLINT     NOT NULL DEFAULT 1,  -- 1=PENDING
     user_id         INT REFERENCES auth_user(id) ON DELETE CASCADE,
     xauth_allowed   BOOLEAN      NOT NULL DEFAULT FALSE
);

-- Token
CREATE TABLE oauth_provider_token (
    id                  SERIAL PRIMARY KEY,
    key                 VARCHAR(32),
    secret              VARCHAR(2048),
    token_type          SMALLINT     NOT NULL,  -- 1=REQUEST, 2=ACCESS
    "timestamp"         INTEGER      NOT NULL DEFAULT EXTRACT(EPOCH FROM NOW())::INTEGER,
    is_approved         BOOLEAN      NOT NULL DEFAULT FALSE,
    user_id             INT REFERENCES auth_user(id) ON DELETE CASCADE,
    consumer_id         INT          NOT NULL REFERENCES oauth_provider_consumer(id) ON DELETE CASCADE,
    scope               VARCHAR(100) NOT NULL DEFAULT 'statements/write statements/read/mine',
    verifier            VARCHAR(10)  NOT NULL DEFAULT '',
    callback            VARCHAR(2083),
    callback_confirmed  BOOLEAN      NOT NULL DEFAULT FALSE
);