CREATE TABLE adl_lrs_hook (
    hook_id     UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(50)  NOT NULL,
    config      JSONB        NOT NULL,
    filters     JSONB        NOT NULL,
    user_id     INT          NOT NULL REFERENCES auth_user(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE (name, user_id)
);