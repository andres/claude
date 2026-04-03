# 03 — Build Rules

How to define, build, test, and ship each domain in NewBear.

---

## Build Order Philosophy

Not every domain is equal. Some are foundational (other domains depend on them),
some are leaf nodes (they depend on others but nothing depends on them).

### Foundation Layer (build first)

These domains must exist before anything else can work:

1. **Client Identity** — everything references a client
2. **Workforce** — everything references a user/provider
3. **Care Programs** — enrollment is the operational backbone
4. **Audit & Compliance** — audit trail must be in place from day one

### Core Layer (build second)

These domains deliver the primary clinical and financial workflows:

5. **Scheduling** — the daily operational heartbeat
6. **Clinical Documentation** — the core clinical workflow
7. **Clinical Records** — diagnoses, vitals, meds
8. **Revenue Cycle** — the business model
9. **Payer Management** — insurance drives everything

### Service Layer (build third)

Specialized service lines that build on core:

10. **Group Services** — extends scheduling + documentation
11. **Prescribing** — extends clinical records
12. **Diagnostics** — extends clinical records
13. **Foster Care** — extends enrollment + documentation + billing
14. **Substance Use Treatment** — extends enrollment + clinical + dispensing
15. **Residential** — extends enrollment + location management
16. **Care Logistics** — extends scheduling + billing

### Intelligence Layer (build alongside)

AI and analytics capabilities that layer across all domains:

17. **AI Clinical Assist** — hooks into documentation
18. **AI Revenue Intelligence** — hooks into billing + claims
19. **AI Report Assist** — hooks into all domains
20. **Analytics** — hooks into all domains
21. **Workflow Engine** — cross-domain automation

### Experience Layer (build when core is stable)

End-user-facing capabilities:

22. **Client Portal** — depends on identity + scheduling + documents
23. **Telehealth** — depends on scheduling + documentation
24. **Notifications** — cross-domain
25. **Care Coordination** — cross-domain
26. **Consent & Privacy** — cross-domain (but design up front)
27. **Crisis & Safety** — clinical specialty
28. **SDOH** — clinical specialty
29. **Outcomes & Quality** — depends on most other domains
30. **Interoperability** — depends on clean data models

---

## Building a Domain: Step by Step

### Step 1: Define

Write the domain spec using [04 Domain Template](04_domain_template.md). This includes:
- What it does (capabilities)
- What data it owns (entities)
- What it depends on (other domains)
- What it exposes (API surface, events)
- What legacy data maps to it
- What's new vs. reimagined

**Gate:** Domain spec reviewed and approved before any code.

### Step 2: Schema

Design the database schema for the domain:
- Entity tables with all columns, types, constraints
- Relationship tables (joins, polymorphic links)
- Reference/lookup tables
- Indexes for known query patterns
- Migration scripts from legacy tables

**Gate:** Schema reviewed. Migration script tested against a copy of a real agency's data.

### Step 3: API

Implement the API layer:
- CRUD endpoints for all entities
- Search/filter endpoints
- Business logic endpoints (state transitions, validations)
- AI endpoints (query, suggest, validate)
- OpenAPI spec generated and published

**Gate:** API contract tests pass. All endpoints documented.

### Step 4: Migration

Build and validate the data migration:
- Migration scripts for all legacy tables in this domain
- Validation framework checks (row counts, sums, referential integrity)
- Run against at least 3 real agency databases
- Performance benchmarks (migration must complete in a reasonable window)

**Gate:** Migration validation report shows zero discrepancies on all test agencies.

### Step 5: Integration

Wire up cross-domain connections:
- Publish domain events that other domains need
- Subscribe to events from domains this one depends on
- Test end-to-end workflows that span domains

**Gate:** Integration tests pass for all cross-domain workflows.

### Step 6: UI

Build the user interface:
- Follows the API — every UI action is an API call
- Responsive, works on tablet (many users are on tablets in clinical settings)
- Keyboard-navigable for power users
- Accessible (WCAG 2.1 AA)

**Gate:** UI review with actual users from at least 2 agencies.

### Step 7: AI

Add AI capabilities specific to this domain:
- Natural language query support
- Smart defaults and suggestions
- Documentation assist (where applicable)
- Anomaly detection (where applicable)

**Gate:** AI features tested with real clinical scenarios. False positive/negative rates acceptable.

### Step 8: Ship

Incremental rollout:
- Deploy to a staging agency (internal test)
- Deploy to 2-3 early adopter agencies
- Monitor for issues, iterate
- Gradual rollout to remaining agencies
- Legacy domain remains available during transition (strangler fig)

---

## Code Standards

### General

- Types everywhere — no `any`, no untyped data crossing boundaries
- Tests are not optional — unit tests for logic, integration tests for API, migration tests for data
- No business logic in the database (stored procedures, triggers) — logic lives in application code
- No business **rule enforcement** in the frontend — the API is the final authority on
  what is valid, what is allowed, and what state transitions are legal. However,
  **UI presentation logic** lives in the frontend: showing/hiding fields based on
  selections, enabling/disabling sections based on context, conditional form layouts,
  and field dependencies. These are driven by form configuration metadata from the API,
  not hardcoded — so the same rules apply whether the user is on web, mobile, or voice
- Configuration over convention where behavior varies by agency
- **Sensible defaults everywhere** — if the system can predict the most likely value,
  pre-select it. The user should be correcting exceptions, not filling in the obvious:
  - Dropdowns default to the most probable selection based on context
    (e.g., provider → logged-in user, location → user's assigned location,
    program → client's active enrollment, payor → client's primary insurance)
  - Date fields default to today where appropriate (date of service, appointment date)
  - Forms pre-populate from the client's existing data (demographics, insurance, diagnoses)
  - Repeat visits pre-populate from the last encounter of the same type
  - Defaults are learned over time — if a user always picks the same appointment type
    or place of service, the system should start suggesting it
  - AI-suggested defaults are visually distinguishable from data-driven defaults
  - Every default is overridable — never lock the user into an assumed value

### API

- Every endpoint returns consistent error format with actionable messages
- Pagination is cursor-based, not offset-based (offset breaks with concurrent writes)
- All list endpoints support filtering, sorting, and field selection
- Rate limiting per API key / user
- Versioning via URL path (`/api/v1/`, `/api/v2/`)

### Data

- Auto-increment bigint for primary keys (consistent with legacy, zero migration friction)
- Soft deletes everywhere (hard delete only for GDPR/compliance, and logged)
- Audit columns on every mutable table
- Indexes are deliberate — every index has a documented query pattern it supports
- No nulls for business-critical fields — use explicit "unknown" / "not provided" values where needed

### Security

- All inputs validated and sanitized at the API boundary
- SQL injection impossible (parameterized queries only)
- PHI is encrypted at rest
- API keys are hashed, never stored in plaintext
- No secrets in code, config, or logs

---

## Documentation Requirements

Every domain must maintain:

1. **Domain spec** — the document from this spec suite
2. **API reference** — auto-generated from OpenAPI spec
3. **Migration guide** — how legacy data maps to new schema
4. **Runbook** — how to operate, monitor, and troubleshoot this domain
5. **Changelog** — what changed, when, and why
