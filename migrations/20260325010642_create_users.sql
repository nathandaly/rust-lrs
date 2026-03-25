CREATE TABLE auth_user (
    id            SERIAL PRIMARY KEY,
    username      VARCHAR(150) NOT NULL UNIQUE,
    email         VARCHAR(254) NOT NULL DEFAULT '',
    password      VARCHAR(128) NOT NULL,
    first_name    VARCHAR(150) NOT NULL DEFAULT '',
    last_name     VARCHAR(150) NOT NULL DEFAULT '',
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    is_staff      BOOLEAN NOT NULL DEFAULT FALSE,
    is_superuser  BOOLEAN NOT NULL DEFAULT FALSE,
    date_joined   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login    TIMESTAMPTZ
);