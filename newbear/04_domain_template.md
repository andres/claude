# 04 — Domain Template

Use this template when defining each functional domain. Copy it, fill it in,
and save as the domain's spec file (e.g., `10_client_identity.md`).

---

```markdown
# {Number} — {Domain Name}

> One-line description of what this domain does.

## Status

- [ ] Spec defined
- [ ] Schema designed
- [ ] Migration mapped
- [ ] API implemented
- [ ] Migration validated
- [ ] UI built
- [ ] AI capabilities added
- [ ] Shipped to early adopters
- [ ] General availability

---

## Purpose

2-3 sentences: What is this domain responsible for? What problems does it solve?
Who are the primary users?

---

## Legacy Mapping

### Tables Migrated From

| Legacy Table | Legacy DB | Migration Category | NewBear Table |
|-------------|-----------|-------------------|---------------|
| `table_name` | MariaDB / MongoDB | A / B / C / D | `new_table_name` |

### Key Changes from Legacy

- What's different about the new schema vs. the old?
- What legacy patterns are being replaced (e.g., STI → dedicated tables)?
- What was implicit that is now explicit?

### Migration Risks

- Data quality issues known in legacy (e.g., inconsistent enum casing)
- Tables with unusual patterns (e.g., polymorphic associations)
- Large tables that need batched migration

---

## Capabilities

### Must Have (Day 1)

List the core capabilities this domain must provide at launch.
Each capability should be a concrete user action or system behavior.

1. **Capability name** — Description of what it does
2. ...

### Should Have (Fast Follow)

Capabilities that ship shortly after launch.

1. ...

### Future

Capabilities planned but not committed.

1. ...

---

## Entities

### `entity_name`

> One-line description.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `legacy_id` | integer | YES | FK to legacy system |
| ... | ... | ... | ... |
| `created_at` | timestamptz | NO | |
| `created_by` | bigint | NO | FK users |
| `updated_at` | timestamptz | NO | |
| `updated_by` | bigint | NO | FK users |
| `deleted_at` | timestamptz | YES | Soft delete |
| `deleted_by` | bigint | YES | FK users |

**Relationships:**
- `belongs_to :other_entity` via `other_entity_id`
- `has_many :child_entities`

**Indexes:**
- `idx_entity_name_on_x` — supports query pattern Y

### `next_entity`

...

---

## API Surface

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/{domain}/{resource} | List with filters |
| POST | /api/v1/{domain}/{resource} | Create |
| GET | /api/v1/{domain}/{resource}/{id} | Get by ID |
| PATCH | /api/v1/{domain}/{resource}/{id} | Update |
| DELETE | /api/v1/{domain}/{resource}/{id} | Soft delete |
| ... | ... | ... |

### AI Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | /api/v1/{domain}/query | Natural language query |
| POST | /api/v1/{domain}/suggest | Context-aware suggestions |
| POST | /api/v1/{domain}/validate | Pre-validate an action |

### Domain Events Published

| Event Type | Trigger | Payload |
|-----------|---------|---------|
| `{domain}.{entity}.created` | New entity created | Entity snapshot |
| `{domain}.{entity}.updated` | Entity modified | Changed fields |
| `{domain}.{entity}.deleted` | Entity soft-deleted | Entity ID + reason |
| ... | ... | ... |

### Domain Events Consumed

| Event Type | Source Domain | Action Taken |
|-----------|-------------|-------------|
| `other_domain.entity.event` | Other Domain | What this domain does in response |

---

## Business Rules

Rules that the API enforces. These are not UI hints — they are hard constraints.

1. **Rule name:** Description. When violated, the API returns error code X.
2. ...

---

## Dependencies

### Depends On

| Domain | Why |
|--------|-----|
| Client Identity | Every entity in this domain references a client |
| ... | ... |

### Depended On By

| Domain | Why |
|--------|-----|
| ... | ... uses this domain's entities/events |

---

## Clinical Terminology

| Code System | Usage in This Domain |
|------------|---------------------|
| ICD-10-CM | ... |
| SNOMED CT | ... |
| RxNorm | ... |
| CPT/HCPCS | ... |

---

## Open Questions

Things not yet decided for this domain.

1. ...
2. ...
```
