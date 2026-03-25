---
name: Rust LRS Migration Plan
overview: Migrate the Django-based ADL LRS to a Rust application using Actix Web and PostgreSQL, following clean architecture with strict separation of concerns and SOLID principles for high-performance xAPI statement processing.
todos:
  - id: scaffold
    content: Scaffold Cargo project with dependencies (actix-web, sqlx, serde, uuid, chrono, iri-string, thiserror, config, bcrypt, hmac, sha2, tokio)
    status: pending
  - id: config
    content: Create config.rs and config.toml for database, server, auth, and hooks settings
    status: pending
  - id: domain-types
    content: "Define domain structs: Statement, Actor/Ifi, Verb, Activity, Result, Context, Attachment, SubStatement in domain/"
    status: pending
  - id: domain-errors
    content: Define LrsError enum in domain/error.rs with variants for each HTTP-mappable error
    status: pending
  - id: domain-validation
    content: "Implement split validators: statement, actor, verb, object, result, context, attachment, common helpers"
    status: pending
  - id: repo-traits
    content: "Define repository traits in application layer: StatementRepository, AgentRepository, ActivityRepository, VerbRepository, DocumentRepository, AuthRepository"
    status: pending
  - id: services
    content: "Implement application services: StatementService, DocumentService, AgentService, ActivityService, AuthService"
    status: pending
  - id: migrations
    content: Write sqlx SQL migrations for all tables (verbs, agents, activities, statements, sub_statements, attachments, document stores, auth, hooks)
    status: pending
  - id: pg-repos
    content: Implement Postgres repository structs in infrastructure/db/ using sqlx queries
    status: pending
  - id: middleware
    content: "Build Actix middleware: auth extractor (Basic + OAuth), version header check, error-to-HTTP mapper"
    status: pending
  - id: handlers
    content: "Write Actix handlers for all xAPI endpoints: statements, activities, agents, state, profiles, about"
    status: pending
  - id: dto
    content: Create request/response DTOs with serde for all endpoints
    status: pending
  - id: background
    content: Implement background task runner for metadata fetching and webhook delivery via tokio::spawn
    status: pending
  - id: routes
    content: Wire all routes in api/routes.rs, register middleware, inject services via web::Data
    status: pending
  - id: main
    content: "Bootstrap main.rs: load config, create PgPool, construct services, start Actix server"
    status: pending
isProject: false
---

# Rust xAPI LRS -- Architecture and Migration Plan

## Original Codebase Reference (ADL_LRS -- Django/Python)

This Rust LRS is a ground-up rewrite of the [ADL LRS](https://github.com/adlnet/ADL_LRS), an open-source Django-based xAPI Learning Record Store. The original source lives in this same repo under the `zby` worktree. Every architectural decision below traces back to specific files in that codebase.

### Source File Map -- What Each Django File Does and What Replaces It

**Core xAPI Processing Pipeline**


| Original Django File                      | Lines | What It Does                                                                                                                                                                                                                      | Rust Replacement                                                                                                                                                                                                |
| ----------------------------------------- | ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `./ADL_LRS/lrs/views.py`                  | 254   | God-dispatcher `handle_request` maps URL names to validate/process function pairs. Catches all exceptions and maps to HTTP status codes.                                                                                          | `api/handlers/*.rs` (one file per endpoint) + `api/middleware/error_handler.rs`                                                                                                                                 |
| `./ADL_LRS/lrs/utils/req_parse.py`        | ~570  | Parses Authorization header (Basic/OAuth), extracts body/params, handles multipart/mixed attachments, builds internal request dict.                                                                                               | `api/middleware/auth.rs` + `api/extractors/auth.rs` + `api/extractors/query.rs`                                                                                                                                 |
| `./ADL_LRS/lrs/utils/req_validate.py`     | 920   | 20+ functions mixing auth checks (`@auth` decorator), parameter validation, `StatementValidator` calls, OAuth scope enforcement, and ETag checks for every endpoint.                                                              | `application/*_service.rs` (business rules) + `domain/validation/*.rs` (xAPI rules) + `api/middleware/auth.rs` (auth/scope)                                                                                     |
| `./ADL_LRS/lrs/utils/req_process.py`      | 552   | Database reads/writes for all endpoints: statement insertion via `StatementManager`, document CRUD via state/profile managers, complex GET queries with filtering, pagination (cache-based "more" tokens), and response building. | `application/*_service.rs` (orchestration) + `infrastructure/db/*_repo.rs` (SQL)                                                                                                                                |
| `./ADL_LRS/lrs/utils/StatementValidator.py` | 987   | Single class validates the entire xAPI spec: actor, verb, object, result, context, attachments, interaction types, IRIs, UUIDs, language maps, durations. All in one file with deeply nested method calls.                        | `domain/validation/` directory -- one file per concern: `actor_validator.rs`, `verb_validator.rs`, `object_validator.rs`, `result_validator.rs`, `context_validator.rs`, `attachment_validator.rs`, `common.rs` |
| `./ADL_LRS/lrs/utils/authorization.py`    | 270   | `@auth` decorator, `http_auth_helper` (Basic auth), `oauth_helper` (OAuth token validation, group agent creation), `validate_oauth_scope`, `validate_oauth_for_documents`.                                                        | `application/auth_service.rs` + `api/middleware/auth.rs`                                                                                                                                                        |


**Models and Database Managers**


| Original Django File                             | Lines | What It Does                                                                                                                                                                                                                                                                                                            | Rust Replacement                                                                                                  |
| ------------------------------------------------ | ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `./ADL_LRS/lrs/models.py`                        | 865   | Django ORM models for `Verb`, `Agent` (with `AgentManager`), `Activity`, `SubStatement`, `Statement`, `StatementAttachment`, `ActivityState`, `ActivityProfile`, `AgentProfile`. Mixes schema definition with serialization (`to_dict`, `object_return`), business logic (`retrieve_or_create`), and language handling. | `domain/*.rs` (pure structs/enums) + `infrastructure/db/*_repo.rs` (SQL) + `api/dto/*.rs` (serialization)         |
| `./ADL_LRS/lrs/managers/StatementManager.py`     | ~350  | `populate` pipeline: `build_verb`, `build_statement_object`, `build_context`, `build_result`, `build_model_object`, `build_attachments`. Flattens nested xAPI JSON into Django model fields. Also `SubStatementManager`.                                                                                                | `application/statement_service.rs` (pipeline orchestration) + `infrastructure/db/statement_repo.rs` (persistence) |
| `./ADL_LRS/lrs/managers/ActivityManager.py`      | ~150  | `get_or_create` activity, merges language maps in `definition` when `define` permission is set, manages `authority` on activities.                                                                                                                                                                                      | `application/activity_service.rs` + `infrastructure/db/activity_repo.rs`                                          |
| `./ADL_LRS/lrs/managers/ActivityStateManager.py` | ~200  | GET/PUT/POST/DELETE for activity state documents. POST does JSON merge of existing + new. ETag-based concurrency.                                                                                                                                                                                                       | `application/document_service.rs` + `infrastructure/db/document_repo.rs`                                          |
| `./ADL_LRS/lrs/managers/ActivityProfileManager.py` | ~180  | Same pattern as state but for activity profiles. JSON merge on POST, full replace on PUT.                                                                                                                                                                                                                               | `application/document_service.rs` + `infrastructure/db/document_repo.rs`                                          |
| `./ADL_LRS/lrs/managers/AgentProfileManager.py`  | ~180  | Same pattern for agent profiles.                                                                                                                                                                                                                                                                                        | `application/document_service.rs` + `infrastructure/db/document_repo.rs`                                          |


**Authentication and OAuth**


| Original Django File                   | Lines | What It Does                                                                                                                                | Rust Replacement                                             |
| -------------------------------------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `./ADL_LRS/oauth_provider/models.py`   | ~120  | Django models: `Nonce`, `Consumer` (key/secret/status), `Token` (request/access, scopes, verifier). `TokenManager`.                         | `infrastructure/db/auth_repo.rs` + domain types in `domain/` |
| `./ADL_LRS/oauth_provider/views.py`    | 280   | OAuth 1.0a handshake: `request_token` (initiate), `user_authorization` (approve/deny), `access_token` (exchange), plus xAuth flow.          | `api/handlers/oauth.rs` (if you add OAuth handshake)         |
| `./ADL_LRS/oauth_provider/store.py`    | ~200  | `Store` class: `lookup_consumer`, `lookup_token`, `lookup_nonce`, `create_request_token`, `create_access_token`, `authorize_request_token`. | `infrastructure/db/auth_repo.rs`                             |
| `./ADL_LRS/oauth_provider/utils.py`    | ~150  | `CheckOauth` class: verifies OAuth signatures, timestamps, nonces.                                                                          | `application/auth_service.rs`                                |


**Background Tasks and Webhooks**


| Original Django File       | Lines | What It Does                                                                                                                                                                                                                                                                        | Rust Replacement                                                                                                                             |
| -------------------------- | ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `./ADL_LRS/lrs/tasks.py`   | 249   | Celery tasks: `check_activity_metadata` (HTTP fetch activity definitions, update canonical data), `check_statement_hooks` (filter statements against Hook configs, POST to webhook endpoints with optional HMAC `X-LRS-Signature`). Also helper functions for parsing hook filters. | `infrastructure/background/metadata_fetcher.rs` + `infrastructure/background/webhook_sender.rs` + `infrastructure/background/task_runner.rs` |


**Configuration and Infrastructure**


| Original Django File                | Lines | What It Does                                                                                                                                                               | Rust Replacement                                                |
| ----------------------------------- | ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `./ADL_LRS/adl_lrs/settings.py`     | ~200  | Django settings: DB config from `settings.ini`, Celery/AMQP, caches, middleware stack, installed apps, media paths, logging.                                               | `config.rs` + `config.toml`                                     |
| `./ADL_LRS/settings.ini.example`    | ~40   | INI config: database, email, recaptcha, debug, auth flags, hooks, AMQP, Redis.                                                                                             | `config.toml`                                                   |
| `./ADL_LRS/adl_lrs/models.py`       | ~60   | `Hook` model: UUID PK, name, config (endpoint), filters (JSON), user FK.                                                                                                   | `domain/hook.rs` + `infrastructure/db/hook_repo.rs`             |
| `./ADL_LRS/adl_lrs/views.py`        | 446   | Web UI views: home, register, login, "me" dashboard, hook management, statement validator form, app status. Not part of xAPI spec.                                         | Out of scope for initial Rust LRS (admin UI can be added later) |
| `./ADL_LRS/adl_lrs/middleware.py`   | 149   | `ErrorHandlingMiddleware`: catches exceptions, logs with error_id, returns JSON for xAPI paths or HTML for web paths. Defined but not wired into `MIDDLEWARE` in settings. | `api/middleware/error_handler.rs`                               |


**SQL Migrations (Custom, outside Django)**


| SQL File                                                                         | What It Does                                                                                                                                | Rust Equivalent                                     |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| `./ADL_LRS/sql/01_adl_lrs_registration_migration_fixed.sql`                      | Creates `registrations`, `registration_submissions`, `registration_modules` tables + materialized view + trigger on `lrs_statement` insert. | Later migration: `migrations/011_registrations.sql` |
| `./ADL_LRS/sql/02_pathways_resources_migration.sql`                              | Creates `pathways`, `resources`, `resource_submissions`, `resource_modules`, `pathway_registrations` + materialized views.                  | Later migration: `migrations/012_pathways.sql`      |
| `./ADL_LRS/sql/03_fix_resource_sync.sql`                                         | Default pathway, selective EasyGenerator trigger.                                                                                           | Folded into 012.                                    |
| `./ADL_LRS/sql/04_platform_aware_sync_functions.sql`                             | `detect_lms_platform` function, unified routing trigger, rewritten sync functions.                                                          | Later migration: `migrations/013_platform_sync.sql` |
| `./ADL_LRS/sql/05_fix_ambiguous_column.sql` through `sql/07_fix_table_columns.sql` | Bug fixes for column names, DISTINCT/ORDER BY, and INSERT alignment.                                                                        | Fixes incorporated into 011-013 from the start.     |
| `./ADL_LRS/docker/clear.sql`                                                     | Truncation script respecting FK order.                                                                                                      | Utility script, not a migration.                    |


### Key xAPI Validation Rules (from `./ADL_LRS/lrs/utils/StatementValidator.py`)

These rules must be faithfully reimplemented in `domain/validation/`:

- **Statement**: Required fields `actor`, `verb`, `object`. Optional `id` (UUID v4), `timestamp`, `context`, `result`, `attachments`, `authority`, `version`. Version must match `^(1|2)\.0(\.\d+)?$`.
- **Actor/Agent**: Exactly one IFI (`mbox` as `mailto:` + email, `mbox_sha1sum` as 40 hex, `openid` as IRI, or `account` with `homePage` IRI + `name`). Groups may have 0-1 IFI; anonymous groups require `member` list. Members cannot be Groups. Authority groups must have exactly 2 members.
- **Verb**: `id` required (valid IRI). Optional `display` language map. Voided verb (`http://adlnet.gov/expapi/verbs/voided`) requires object to be StatementRef.
- **Object**: Activity (default): `id` IRI, optional `definition` with interaction types from SCORM list. Agent/Group: same rules as actor. SubStatement: no nested SubStatements. StatementRef: `id` UUID v4.
- **Result**: `score.scaled` in [-1,1]; `raw` between `min` and `max` if all present; `min < max`. `duration` as ISO 8601. `success`/`completion` booleans.
- **Context**: `registration` UUID. `revision`/`platform` only when object is Activity. `contextActivities` keys: `parent`, `grouping`, `category`, `other` (each a list of Activities). `contextAgents`/`contextGroups` with `relevantTypes` IRI lists (xAPI 2.0).
- **Attachments**: Required `usageType` IRI, `display` language map, `contentType`, `length` int, `sha2` (64 hex lowercase). Optional `fileUrl` IRI.

### API Endpoint Catalog (from `./ADL_LRS/lrs/urls.py` + `./ADL_LRS/lrs/views.py`)

All mounted at `/xapi/` (case-insensitive: `/XAPI/`, `/xAPI/` also accepted):


| Method                       | Path                    | Auth     | Django Validate       | Django Process        | Rust Handler                       |
| ---------------------------- | ----------------------- | -------- | --------------------- | --------------------- | ---------------------------------- |
| GET, HEAD                    | `/about`                | None     | --                    | --                    | `handlers/about.rs`                |
| POST                         | `/statements`           | Required | `statements_post`     | `statements_post`     | `handlers/statements.rs::post`     |
| PUT                          | `/statements`           | Required | `statements_put`      | `statements_put`      | `handlers/statements.rs::put`      |
| GET, HEAD                    | `/statements`           | Required | `statements_get`      | `statements_get`      | `handlers/statements.rs::get`      |
| GET, HEAD                    | `/statements/more/{id}` | Required | `statements_more_get` | `statements_more_get` | `handlers/statements_more.rs::get` |
| GET, POST, PUT, DELETE, HEAD | `/activities/state`     | Required | `activity_state`_*    | `activity_state`_*    | `handlers/activity_state.rs`       |
| GET, POST, PUT, DELETE, HEAD | `/activities/profile`   | Required | `activity_profile`_*  | `activity_profile`_*  | `handlers/activity_profile.rs`     |
| GET, HEAD                    | `/activities`           | Required | `activities_get`      | `activities_get`      | `handlers/activities.rs`           |
| GET, POST, PUT, DELETE, HEAD | `/agents/profile`       | Required | `agent_profile`_*     | `agent_profile`_*     | `handlers/agent_profile.rs`        |
| GET, HEAD                    | `/agents`               | Required | `agents_get`          | `agents_get`          | `handlers/agents.rs`               |


### OAuth Handshake Endpoints (from `./ADL_LRS/oauth_provider/urls.py`)


| Method    | Path                    | Auth                                       | Description               |
| --------- | ----------------------- | ------------------------------------------ | ------------------------- |
| POST      | `/xapi/OAuth/initiate`  | Consumer OAuth signature                   | Request token             |
| GET, POST | `/xapi/OAuth/authorize` | Session (logged-in user must own consumer) | Approve/deny + redirect   |
| POST      | `/xapi/OAuth/token`     | OAuth verifier or xAuth credentials        | Exchange for access token |


### Authorization Scopes (from `./ADL_LRS/oauth_provider/consts.py` + `./ADL_LRS/lrs/utils/authorization.py`)

Scopes control what OAuth tokens can do: `statements/write`, `statements/read`, `statements/read/mine`, `state`, `define`, `profile`, `all`. The `@auth` decorator in `./ADL_LRS/lrs/utils/req_validate.py` calls `validate_oauth_scope` to enforce method+endpoint vs token scope. The `define` flag controls whether the client can create/update Activity definitions.

---

## Problems With the Current Python Codebase

Before designing the Rust version, here is what makes the Django codebase hard to maintain:

- `**./ADL_LRS/lrs/views.py`** -- A single `handle_request` function acts as a god-dispatcher, routing all xAPI endpoints through nested dicts of validators and processors. No separation between HTTP concerns and business logic.
- `**./ADL_LRS/lrs/utils/req_validate.py`** (920 lines) -- Mixes authentication, authorization, parameter extraction, and xAPI validation into one monolithic module with 20+ functions.
- `**./ADL_LRS/lrs/utils/req_process.py`** (552 lines) -- Mixes database queries, serialization, caching, pagination, and response building.
- `**./ADL_LRS/lrs/utils/StatementValidator.py`** (987 lines) -- One class validates the entire xAPI spec with deeply nested method calls and no separation of validation concerns (actor vs verb vs result vs context).
- `**./ADL_LRS/lrs/models.py`** (865 lines) -- Django models mix persistence schema with serialization (`to_dict`, `object_return`), business logic (`AgentManager.retrieve_or_create`), and language handling.
- `**./ADL_LRS/lrs/managers/StatementManager.py`** -- Mixes ORM operations with business rules for building/flattening statement structures.
- **Auth is scattered** across `./ADL_LRS/lrs/utils/req_parse.py`, `./ADL_LRS/lrs/utils/authorization.py`, OAuth provider views, and decorators with no single responsibility boundary.

## Rust Architecture: Clean / Hexagonal Layers

```mermaid
graph TB
  subgraph api [API Layer]
    Handlers["Actix Handlers"]
    Middleware["Auth / Version Middleware"]
    DTOs["Request / Response DTOs"]
  end

  subgraph app [Application Layer]
    StatementService["StatementService"]
    DocumentService["DocumentService"]
    AgentService["AgentService"]
    ActivityService["ActivityService"]
    AuthService["AuthService"]
  end

  subgraph domain [Domain Layer - Pure Rust, No Dependencies]
    Statement["Statement"]
    Actor["Actor / Agent / Group"]
    Verb["Verb"]
    ActivityDomain["Activity"]
    Result["Result"]
    Context["Context"]
    Attachment["Attachment"]
    Validator["Validation Traits"]
  end

  subgraph infra [Infrastructure Layer]
    PgRepo["Postgres Repositories"]
    BackgroundWorker["Background Task Runner"]
    WebhookClient["Webhook HTTP Client"]
  end

  Handlers --> StatementService
  Handlers --> DocumentService
  Handlers --> AgentService
  Handlers --> ActivityService
  Middleware --> AuthService
  StatementService --> Validator
  StatementService --> PgRepo
  StatementService --> BackgroundWorker
  DocumentService --> PgRepo
  AgentService --> PgRepo
  ActivityService --> PgRepo
  AuthService --> PgRepo
  BackgroundWorker --> WebhookClient
```



### Layer Rules

1. **Domain** -- Pure Rust structs, enums, and traits. Zero framework dependencies. Contains xAPI types, validation logic, and domain errors. Tested in isolation.
2. **Application** -- Services that orchestrate domain logic and call repository traits. Depends only on domain. No HTTP or SQL knowledge.
3. **Infrastructure** -- Implements repository traits with `sqlx` (Postgres), provides background task execution via `tokio::spawn`.
4. **API** -- Actix Web handlers, middleware, extractors, and DTOs. Thin layer that deserializes requests, calls services, serializes responses.

## Recommended Crate Stack

- **Web**: `actix-web` 4.x
- **Database**: `sqlx` with compile-time query checking (async, no ORM overhead)
- **Serialization**: `serde` + `serde_json`
- **Validation**: Custom via traits + `thiserror` for typed errors
- **UUID**: `uuid` crate (v4 generation, parsing)
- **DateTime**: `chrono` (with serde feature)
- **IRI validation**: `iri-string` crate
- **Auth**: Custom middleware; `hmac` + `sha2` for webhook signing; `bcrypt` for passwords
- **Background tasks**: `tokio::spawn` for simple async tasks (replaces Celery)
- **Connection pooling**: `sqlx::PgPool` (built-in)
- **Config**: `config` crate reading from TOML/env

## Directory Structure

```
src/
  main.rs                        -- Actix server bootstrap, config, pool setup
  config.rs                      -- Configuration loading (TOML + env vars)

  domain/                        -- Pure domain types and validation
    mod.rs
    statement.rs                 -- Statement, SubStatement structs
    actor.rs                     -- Agent, Group, IFI enum
    verb.rs                      -- Verb struct
    activity.rs                  -- Activity, ActivityDefinition
    result.rs                    -- Result, Score
    context.rs                   -- Context, ContextActivities
    attachment.rs                -- Attachment struct
    error.rs                     -- Domain error enum (ValidationError, NotFound, etc.)
    validation/
      mod.rs
      statement_validator.rs     -- Validate top-level statement
      actor_validator.rs         -- Validate actor/agent/group/authority
      verb_validator.rs          -- Validate verb
      object_validator.rs        -- Validate object (activity, agent, sub-statement, ref)
      result_validator.rs        -- Validate result + score
      context_validator.rs       -- Validate context + context activities
      attachment_validator.rs    -- Validate attachments
      common.rs                  -- IRI validation, language tag, duration, UUID helpers

  application/                   -- Use cases / services (orchestration)
    mod.rs
    statement_service.rs         -- POST/PUT/GET statements, voiding, pagination
    document_service.rs          -- Activity state, activity profile, agent profile
    agent_service.rs             -- Agent lookup, retrieve_or_create
    activity_service.rs          -- Activity lookup, canonical data merge
    auth_service.rs              -- Authenticate, authorize, scope checking

  infrastructure/                -- External system implementations
    mod.rs
    db/
      mod.rs
      statement_repo.rs          -- SQL queries for statements
      agent_repo.rs              -- SQL queries for agents
      activity_repo.rs           -- SQL queries for activities
      verb_repo.rs               -- SQL queries for verbs
      document_repo.rs           -- SQL queries for state/profiles
      attachment_repo.rs         -- SQL queries + file storage for attachments
      auth_repo.rs               -- SQL queries for users, consumers, tokens
    background/
      mod.rs
      task_runner.rs             -- tokio::spawn based task executor
      metadata_fetcher.rs        -- Fetch activity metadata from URLs
      webhook_sender.rs          -- POST to hook endpoints with HMAC

  api/                           -- Actix Web HTTP layer
    mod.rs
    routes.rs                    -- All route registrations
    middleware/
      mod.rs
      auth.rs                    -- Extract + validate Basic / OAuth credentials
      version_header.rs          -- X-Experience-API-Version enforcement
      error_handler.rs           -- Map domain errors to HTTP status codes
    handlers/
      mod.rs
      statements.rs              -- GET/POST/PUT /xapi/statements
      statements_more.rs         -- GET /xapi/statements/more/{id}
      activity_state.rs          -- CRUD /xapi/activities/state
      activity_profile.rs        -- CRUD /xapi/activities/profile
      activities.rs              -- GET /xapi/activities
      agent_profile.rs           -- CRUD /xapi/agents/profile
      agents.rs                  -- GET /xapi/agents
      about.rs                   -- GET /xapi/about
    extractors/
      mod.rs
      auth.rs                    -- FromRequest for AuthenticatedUser
      query.rs                   -- Typed query params per endpoint
    dto/
      mod.rs
      statement.rs               -- Request/Response statement shapes
      agent.rs                   -- Agent DTOs
      error.rs                   -- ErrorResponse shape

migrations/                      -- sqlx migrations (plain SQL)
  001_create_verbs.sql
  002_create_agents.sql
  003_create_activities.sql
  004_create_statements.sql
  005_create_sub_statements.sql
  006_create_attachments.sql
  007_create_document_stores.sql -- state, activity_profile, agent_profile
  008_create_auth_tables.sql     -- users, consumers, tokens, nonces
  009_create_hooks.sql
  010_create_indexes.sql

Cargo.toml
config.toml                      -- Runtime config (replaces settings.ini)
```

## Database Schema (Postgres, via sqlx migrations)

Key tables mapped from `./ADL_LRS/lrs/models.py`:

- `**verbs**` -- `id SERIAL PK`, `verb_id TEXT UNIQUE NOT NULL`, `canonical_data JSONB`
- `**agents**` -- `id SERIAL PK`, `object_type TEXT`, `name TEXT`, `mbox TEXT UNIQUE`, `mbox_sha1sum TEXT UNIQUE`, `openid TEXT UNIQUE`, `oauth_identifier TEXT UNIQUE`, `account_home_page TEXT`, `account_name TEXT`, `user_id INT FK`, `UNIQUE(account_home_page, account_name)`
- `**agents_members**` -- M2M join table for group membership
- `**activities**` -- `id SERIAL PK`, `activity_id TEXT UNIQUE NOT NULL`, `canonical_data JSONB`, `authority_id INT FK agents`
- `**sub_statements**` -- mirrors Statement but no `statement_id`, `stored`, `voided`, `full_statement`
- `**statements**` -- `id SERIAL PK`, `statement_id UUID UNIQUE NOT NULL`, `verb_id FK`, `actor_id FK agents`, `object_activity_id FK`, `object_agent_id FK`, `object_sub_statement_id FK`, `object_statement_ref UUID`, result fields, context fields, `stored TIMESTAMPTZ`, `timestamp TIMESTAMPTZ`, `authority_id FK`, `voided BOOL`, `version TEXT`, `full_statement JSONB`, `user_id FK`
- `**statement_context_activities_***` -- join tables for parent/grouping/category/other
- `**statement_attachments**` -- `id SERIAL PK`, `canonical_data JSONB`, `payload_path TEXT`, `statement_id FK`
- `**activity_states**` -- `id SERIAL PK`, `state_id TEXT`, `activity_id TEXT`, `registration_id TEXT`, `agent_id FK`, `json_state JSONB`, `content_type TEXT`, `etag TEXT`, `updated TIMESTAMPTZ`
- `**activity_profiles**` / `**agent_profiles**` -- similar document stores
- `**users**` -- `id SERIAL PK`, `username TEXT UNIQUE`, `email TEXT`, `password_hash TEXT`
- `**oauth_consumers**` -- `id SERIAL PK`, `key TEXT UNIQUE`, `secret TEXT`, `name TEXT`, `status INT`, `user_id FK`
- `**oauth_tokens**` -- `id SERIAL PK`, `key TEXT`, `secret TEXT`, `token_type INT`, `consumer_id FK`, `user_id FK`, `scope TEXT`, `verifier TEXT`, `is_approved BOOL`
- `**hooks**` -- `id UUID PK`, `name TEXT`, `config JSONB`, `filters JSONB`, `user_id FK`, `UNIQUE(name, user_id)`

## SOLID Mapping


| Principle                 | How It Applies                                                                                                                                                                                         |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Single Responsibility** | Each handler file owns one endpoint. Each validator module validates one xAPI component. Each repository handles one table. Each service orchestrates one bounded context.                             |
| **Open/Closed**           | Repository and service traits allow swapping implementations (e.g. mock repos for testing) without changing business logic. New xAPI extensions add new validator modules, not modify existing ones.   |
| **Liskov Substitution**   | All repositories implement traits (`StatementRepository`, `AgentRepository`, etc.). Any implementation satisfying the trait contract is interchangeable.                                               |
| **Interface Segregation** | Services depend on narrow repository traits, not a single "database" interface. `StatementService` depends on `StatementRepository + VerbRepository + AgentRepository`, not a monolithic DB struct.    |
| **Dependency Inversion**  | Application services depend on trait abstractions defined in the application layer. Infrastructure provides concrete implementations. Actix handlers receive services via `web::Data<Arc<dyn Trait>>`. |


## Key Design Decisions

### 1. Validation via Rust Type System + Validator Traits

Instead of one 987-line validator class, split into focused modules. Use Rust enums to make invalid states unrepresentable:

```rust
// domain/actor.rs
pub enum Ifi {
    Mbox(String),
    MboxSha1Sum(String),
    OpenId(String),
    Account { home_page: String, name: String },
}

pub enum ActorType {
    Agent { ifi: Ifi, name: Option<String> },
    Group { ifi: Option<Ifi>, name: Option<String>, members: Vec<ActorType> },
}
```

### 2. Error Handling

A single domain error enum maps cleanly to HTTP status codes in the API layer:

```rust
// domain/error.rs
pub enum LrsError {
    Validation(String),       // 400
    Unauthorized(String),     // 401
    Forbidden(String),        // 403
    NotFound(String),         // 404
    Conflict(String),         // 409
    PreconditionFailed(String), // 412
    Internal(String),         // 500
}
```

### 3. Statement Pipeline (replaces req_parse + req_validate + req_process)

```mermaid
sequenceDiagram
    participant Client
    participant AuthMW as Auth Middleware
    participant Handler as statements::post
    participant Service as StatementService
    participant Validator as domain::validation
    participant Repo as StatementRepo
    participant BG as BackgroundRunner

    Client->>AuthMW: POST /xapi/statements
    AuthMW->>AuthMW: Extract credentials, verify
    AuthMW->>Handler: AuthenticatedUser injected
    Handler->>Handler: Deserialize body to Vec of StatementDTO
    Handler->>Service: create_statements(user, statements)
    Service->>Validator: validate each statement
    Validator-->>Service: Ok or ValidationError
    Service->>Repo: insert statements (single transaction)
    Repo-->>Service: stored statement IDs
    Service->>BG: spawn metadata_fetch + webhook tasks
    Service-->>Handler: Ok(statement_ids)
    Handler-->>Client: 200 with IDs array
```



### 4. Background Tasks Without Celery

Rust's `tokio::spawn` replaces Celery entirely. No RabbitMQ needed. For persistence across restarts, consider a lightweight Postgres-backed job queue later, but `tokio::spawn` handles the two existing tasks (metadata fetch, webhooks) with less infrastructure.

### 5. Configuration

Replace `settings.ini` with a `config.toml`:

```toml
[server]
host = "0.0.0.0"
port = 8080

[database]
url = "postgres://lrs_owner:password@localhost:5432/lrs"
max_connections = 20

[auth]
oauth_enabled = true
allow_empty_http_auth = false

[hooks]
enabled = true
hmac_secret = "..."
```

## Migration Strategy

The existing Postgres data can be preserved. Write sqlx migrations that either:

- Create fresh tables with the new schema (recommended for a clean start), or
- Add views/adapters over the existing Django-created tables if you need to run both systems during transition.

The custom SQL from `./ADL_LRS/sql/` (registrations, pathways, resources) can be ported as later migrations once the core LRS is working.

## Performance Advantages Over Python

- **Zero-cost abstractions**: No GIL, no interpreter overhead. Actix Web handles ~500k+ req/s on benchmarks.
- **Async I/O**: `sqlx` async queries + `tokio` runtime = no blocking threads waiting on DB.
- **Connection pooling**: Built into `sqlx::PgPool`, no external pooler needed.
- **No serialization tax**: `serde` compiles serialization at build time; JSON parsing is ~10x faster than Python's `json` module.
- **Memory safety**: Rust's ownership model eliminates entire classes of bugs (use-after-free, data races) that Django apps can hit under concurrency.
- **No Celery/RabbitMQ**: `tokio::spawn` runs background tasks in the same process with near-zero overhead, eliminating two infrastructure services.
