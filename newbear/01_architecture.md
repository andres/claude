# 01 — Architecture

Technical architecture guidelines for NewBear. These are starting positions, not
final decisions — each will be validated as domains are built.

---

## Deployment Model

**Single-tenant.** Each agency gets its own application instance and database.
This is a business decision, not a technical limitation — it simplifies compliance,
data isolation, and per-agency customization.

See [90 Multi-Tenancy](90_multi_tenancy.md) for future considerations.

---

## High-Level Architecture

```
                    ┌─────────────────────────────────┐
                    │         Client Apps              │
                    │  Web UI  │  Mobile  │  Portal    │
                    └────────────────┬────────────────┘
                                     │
                    ┌────────────────▼────────────────┐
                    │           API Gateway            │
                    │   Auth · Rate Limit · Routing    │
                    └────────────────┬────────────────┘
                                     │
          ┌──────────────────────────┼──────────────────────────┐
          │                          │                          │
   ┌──────▼──────┐          ┌───────▼───────┐         ┌───────▼───────┐
   │  Domain      │          │  Domain        │         │  Domain        │
   │  Services    │          │  Services      │         │  Services      │
   │  (Clinical)  │          │  (Financial)   │         │  (Operations)  │
   └──────┬──────┘          └───────┬───────┘         └───────┬───────┘
          │                          │                          │
          └──────────────────────────┼──────────────────────────┘
                                     │
                    ┌────────────────▼────────────────┐
                    │        Data Layer                │
                    │  Primary DB · Clinical Store ·   │
                    │  Search · Cache · File Store     │
                    └────────────────┬────────────────┘
                                     │
                    ┌────────────────▼────────────────┐
                    │        AI / Analytics Layer      │
                    │  Datalake · Models · Embeddings  │
                    └─────────────────────────────────┘
```

---

## Stack Decisions (Starting Positions)

### Application Layer

| Concern | Decision | Rationale |
|---------|----------|-----------|
| API framework | TBD | Must support OpenAPI spec generation, middleware, streaming |
| API style | REST + events | REST for CRUD, event bus for cross-domain communication |
| Auth | OAuth 2.0 / OIDC | Standard, supports SSO, machine-to-machine, and patient portal |
| Real-time | WebSocket / SSE | Notifications, live updates, collaborative editing |

### Data Layer

| Concern | Decision | Rationale |
|---------|----------|-----------|
| Primary database | PostgreSQL | Mature, JSON support, full-text search, excellent tooling |
| Clinical documents | PostgreSQL relational tables | MongoDB data migrated to proper relational schema — no document store in NewBear |
| Search | PostgreSQL full-text + optional dedicated search | Start simple, add Elasticsearch/Typesense if needed |
| File storage | S3-compatible object store | Documents, images, lab results, scanned records |
| Cache | Redis | Sessions, rate limiting, real-time pub/sub |
| Clinical terminology | Dedicated reference tables | SNOMED CT, ICD-10, RxNorm, CPT/HCPCS as structured lookup tables |

### AI / Analytics Layer

| Concern | Decision | Rationale |
|---------|----------|-----------|
| AI datalake | S3 + query engine (Athena/DuckDB) | Revenue cycle analytics, population health, training data |
| LLM integration | Provider-agnostic abstraction | Support multiple providers, swap models without code changes |
| Embeddings | Vector store (pgvector or dedicated) | Clinical similarity search, smart matching, RAG |
| Report generation | AI-assisted with human review | Natural language → SQL/chart, AI drafts → human approves |

### Infrastructure

| Concern | Decision | Rationale |
|---------|----------|-----------|
| Containerization | Docker / OCI | Consistent dev/prod, single-tenant deployment simplicity |
| Orchestration | TBD | K8s for multi-instance management, or simpler per-tenant VMs |
| CI/CD | TBD | Automated testing, migration validation, per-agency rollout |
| Monitoring | Structured logging + metrics + traces | OpenTelemetry-compatible |

---

## Data Model Principles

### Identity

- Primary keys are **auto-increment integers** (bigint), same as legacy Bear
- Existing IDs are preserved as-is during migration — no ID translation needed
- Cross-domain foreign keys reference integer IDs directly
- External-facing identifiers (API responses, URLs, webhooks) may use a separate
  public token or slug where needed to avoid exposing sequential IDs — but the
  internal data model stays on integers

### Audit

Every table that stores mutable data includes:

```
created_at     timestamptz  NOT NULL DEFAULT now()
created_by     bigint       NOT NULL  -- references users
updated_at     timestamptz  NOT NULL DEFAULT now()
updated_by     bigint       NOT NULL
deleted_at     timestamptz           -- soft delete
deleted_by     bigint
deleted_reason text                  -- why it was deleted
```

### Versioning

For entities where history matters (clinical records, consent, insurance):

- Use an append-only version table or event sourcing
- The "current" view is derived from the latest version
- Previous versions are immutable and queryable

### Clinical Terminology

Structured code storage pattern for all coded data:

```
code           varchar      -- the code value (e.g., 'F32.1')
code_system    varchar      -- the coding system (e.g., 'ICD-10-CM', 'SNOMED-CT', 'RxNorm')
display        varchar      -- human-readable display text
version        varchar      -- code system version
```

### Money

- All financial amounts stored as integer cents (bigint)
- Currency is always USD (single-country product)
- Display formatting is a UI concern, never stored

### Timestamps

- All timestamps are `timestamptz` (UTC storage, timezone-aware)
- Agency timezone is a configuration setting applied at display time
- "Date of service" and similar business dates are `date` type (no time component)

---

## API Design

### URL Structure

```
/api/v1/{domain}/{resource}
/api/v1/{domain}/{resource}/{id}
/api/v1/{domain}/{resource}/{id}/{sub-resource}
```

### Standard Patterns

| Operation | Method | URL | Notes |
|-----------|--------|-----|-------|
| List | GET | /api/v1/clients | Paginated, filterable |
| Create | POST | /api/v1/clients | Returns created resource |
| Read | GET | /api/v1/clients/{id} | Includes related data via `?include=` |
| Update | PATCH | /api/v1/clients/{id} | Partial update |
| Delete | DELETE | /api/v1/clients/{id} | Soft delete by default |
| Search | POST | /api/v1/clients/search | Complex queries |
| Bulk | POST | /api/v1/clients/bulk | Batch operations |

### AI Agent Endpoints

Every domain exposes:

```
POST /api/v1/{domain}/query     -- natural language query → structured results
POST /api/v1/{domain}/suggest   -- AI suggestions for current context
POST /api/v1/{domain}/validate  -- validate a proposed action before executing
```

---

## Cross-Domain Communication

### Synchronous: API Calls

For queries and commands that need immediate responses.
One domain calls another's API through an internal service client.

### Asynchronous: Domain Events

For notifications that other domains may care about but don't need to block on.

```
Event format:
{
  "event_type": "client.enrolled",
  "domain": "care_programs",
  "entity_id": "uuid",
  "entity_type": "program_enrollment",
  "occurred_at": "2026-04-02T...",
  "actor_id": "uuid",
  "payload": { ... }
}
```

Consumers subscribe to event types they care about. Events are persisted for replay.

---

## Security Model

- Role-Based Access Control (RBAC) at the API level
- Row-level security for multi-program data isolation within an agency
- 42 CFR Part 2 consent enforcement at the query layer (not just UI)
- All PHI access is logged
- API keys for machine-to-machine, JWT for human sessions
- Encryption at rest and in transit (no exceptions)
