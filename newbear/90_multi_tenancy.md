# 90 — Multi-Tenancy Considerations

**Status: NOT COMMITTED.** This document captures the trade-offs for a potential future
move from single-tenant to multi-tenant architecture. It exists for weighing options,
not for building.

---

## Current Model: Single-Tenant

Each agency gets its own:
- Application instance
- Database (MariaDB in legacy, PostgreSQL in NewBear)
- Configuration
- Deployment lifecycle

**Advantages of staying single-tenant:**
- Complete data isolation (compliance is trivial)
- Per-agency customization without affecting others
- Independent upgrade schedules
- Simple debugging (one agency = one system)
- No noisy-neighbor performance issues
- 42 CFR Part 2 compliance is inherent — no cross-agency data leakage risk

**Disadvantages:**
- Operational overhead scales linearly with agency count (80 today, grows over time)
- Schema changes must be rolled out N times
- Cross-agency analytics requires aggregation layer
- Infrastructure cost per agency has a floor

---

## Multi-Tenancy Options

### Option 1: Shared App, Separate Databases

Each agency gets its own database, but the application is shared. Tenant is determined
by subdomain/header, and the connection pool routes to the correct database.

- Data isolation: HIGH (separate DBs)
- Operational overhead: MEDIUM (one app, N databases)
- Migration complexity: LOW (keep existing DB-per-tenant, share the app)
- Risk: Connection pool management, schema drift between tenants

### Option 2: Shared App, Shared Database, Schema Isolation

All agencies in one database, each in a separate PostgreSQL schema.

- Data isolation: MEDIUM (schema-level, not instance-level)
- Operational overhead: LOW (one app, one DB)
- Migration complexity: MEDIUM (consolidate DBs)
- Risk: Schema migration must update all tenant schemas atomically. One bad migration affects everyone.

### Option 3: Shared Everything with Row-Level Security

All agencies in one database, one schema, with `agency_id` on every table and
PostgreSQL Row-Level Security (RLS) enforcing isolation.

- Data isolation: LOW-MEDIUM (depends on RLS correctness)
- Operational overhead: LOWEST (one of everything)
- Migration complexity: HIGH (consolidate all data, add agency_id everywhere)
- Risk: A single RLS bug exposes cross-agency PHI. Unacceptable for behavioral health.

---

## Recommendation (if/when the time comes)

**Option 1** is the most natural evolution from single-tenant. It preserves the data
isolation guarantees that behavioral health compliance demands while reducing operational
overhead on the application side.

Key design decision: if NewBear's API and domain services are designed to be
tenant-aware from the start (even in single-tenant mode), migrating to Option 1
later is a connection-pool change, not a rewrite.

**Design for this now (even if we don't build it):**
- Every request carries a tenant context (even if there's only one)
- Database connections are resolved through an abstraction, not hardcoded
- Configuration is always tenant-scoped
- Logging always includes tenant identifier

---

## Decision Triggers

Revisit this document when any of these conditions are met:
- Agency count exceeds 200
- Operational cost per agency becomes a business problem
- A customer or prospect requires multi-tenant as a contractual condition
- Cross-agency analytics becomes a core product requirement
