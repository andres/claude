# 02 — Data Contract

Rules governing data migration from legacy Bear to NewBear. These are non-negotiable
guarantees to every agency.

---

## The Promise

**After migration, no agency loses any data, any history, or any report capability.**

If it was in their database before, it is in their database after — findable, queryable,
and connected to the entity it belongs to.

---

## Migration Categories

### Category A: Direct Map

Legacy column maps cleanly to a NewBear column. Data is transformed (type conversion,
normalization) but the meaning is preserved 1:1.

**Example:** `people.date_of_birth` (date) → `clients.date_of_birth` (date)

**Rule:** Automated migration. Validation compares row counts and spot-checks values.

### Category B: Restructured

Legacy data maps to NewBear but the schema changed — tables split, merged, or reorganized.
The data is preserved but lives in a different structure.

**Example:** `people` (STI with `type = 'Client'`) → dedicated `clients` table.

**Rule:** Migration script must be reversible. Both old and new queries must produce
identical results during validation.

### Category C: Consolidated

Multiple legacy sources converge into one NewBear structure.

**Example:** MariaDB `medications` + MongoDB `med_medications` → unified `clinical_medications` table.

**Rule:** Provenance tracking — every migrated record carries `legacy_source` (which system),
`legacy_table` (which table), `legacy_id` (which row).

### Category D: Deprecated

Legacy data that has no equivalent in NewBear's active schema. The feature was removed
or completely redesigned.

**Rule:** Data is NOT discarded. It is migrated to a `legacy_archive` schema with:
- Original table name
- Original row as JSONB
- Link to the NewBear entity it relates to (if any)
- Queryable and exportable
- Clearly labeled as archived in any UI that surfaces it

---

## Migration Guarantees

### Row Count Integrity

For every legacy table, the migration must account for every row:
- Migrated to new schema (Category A/B/C), OR
- Archived (Category D)

`legacy_row_count = new_row_count + archived_row_count` — no exceptions.

### Referential Integrity

All foreign key relationships that existed in legacy must have equivalent relationships
in NewBear. If a legacy `billcase` pointed to a `client_id`, the migrated billcase must
point to the migrated client.

### Temporal Integrity

Timestamps from legacy are preserved exactly as they were. `created_at` in NewBear
reflects when the record was created in legacy, not when it was migrated. A separate
`migrated_at` column tracks the migration event.

### Financial Integrity

Sum of all `*_cents` columns in legacy must equal the sum in NewBear, per agency.
Financial migration has zero tolerance for rounding or loss.

### Clinical Integrity

Diagnosis codes, medication records, vitals, and clinical notes must migrate with their
full history and their link to the encounter/visit they were documented in.

---

## Legacy ID Mapping

Every migrated entity carries:

```sql
legacy_id          integer       -- original auto-increment PK from legacy
legacy_table       varchar       -- original table name (e.g., 'people', 'billcases')
legacy_source      varchar       -- 'mariadb' or 'mongodb'
migrated_at        timestamptz   -- when this row was migrated
migration_batch    varchar       -- migration run identifier
```

A dedicated `legacy_id_map` table provides global lookup:

```sql
CREATE TABLE legacy_id_map (
  legacy_source   varchar NOT NULL,
  legacy_table    varchar NOT NULL,
  legacy_id       varchar NOT NULL,   -- varchar to handle MongoDB ObjectIds
  new_table       varchar NOT NULL,
  new_id          bigint NOT NULL,
  migrated_at     timestamptz NOT NULL,
  PRIMARY KEY (legacy_source, legacy_table, legacy_id)
);
```

---

## Schema Evolution Rules

After initial migration, the schema continues to evolve. Rules for changes:

### Adding Columns

- Always nullable or with a default value
- Never break existing API consumers
- Document in the domain spec changelog

### Removing Columns

- Never remove — deprecate first (mark as `deprecated_at` in schema docs)
- After 2 major versions with deprecation warning, column can be dropped
- Data must be migrated or archived before drop

### Renaming Tables/Columns

- Never rename in place — create new, migrate data, deprecate old
- Both names work during transition period

### Changing Types

- Must be lossless (e.g., varchar(100) → varchar(255) OK, decimal → integer NOT OK)
- Lossy changes require a new column + migration + deprecation cycle

---

## Validation Framework

Every migration run produces a validation report:

```
Agency: agency_name
Migration batch: 2026-04-02-001
Started: 2026-04-02T10:00:00Z
Completed: 2026-04-02T10:45:00Z

Table-level validation:
  people          → clients:           OK (3,421 rows, 0 discrepancies)
  billcases       → billing_cases:     OK (4,039 rows, 0 discrepancies)
  ...

Aggregate validation:
  Total billed (legacy):    $2,341,567.89
  Total billed (new):       $2,341,567.89    OK
  Total paid (legacy):      $1,876,234.12
  Total paid (new):         $1,876,234.12    OK

Referential integrity:
  Orphaned FKs:             0
  Broken links:             0

Archived records:
  legacy_archive rows:      1,247
  Linked to entities:       1,193 (95.7%)
  Unlinked:                 54 (reviewed, OK — config tables with no entity parent)
```

**A migration does not go live until validation passes with zero discrepancies.**

---

## MongoDB Migration Strategy

Legacy Bear stores clinical documents in MongoDB (`med_*` collections). **All MongoDB
data will be migrated to PostgreSQL relational tables.** There is no MongoDB in NewBear.

### Approach

Each `med_*` collection becomes one or more proper relational tables with typed columns,
foreign keys, and indexes — not JSONB blobs.

1. **Map:** For each `med_*` collection, define the target relational table(s) in the
   appropriate domain spec (most land in Clinical Records or Clinical Documentation)
2. **Extract:** Read all documents from each `med_*` collection
3. **Transform:** Flatten document fields into relational columns. Map MongoDB ObjectIds
   to the associated MariaDB entity IDs (client_id, encounter_form_id) using the legacy_id_map.
   Nested arrays become child tables with foreign keys back to the parent.
4. **Load:** Insert into the new PostgreSQL relational tables
5. **Validate:** Compare document counts, verify all cross-references resolve,
   spot-check field values against source documents

### Handling Schema Variance

MongoDB documents within the same collection may have different fields (schema-less).
Strategy:

- Fields present in >90% of documents → required columns in the relational table
- Fields present in 10-90% of documents → nullable columns
- Fields present in <10% of documents → stored in a `metadata` JSONB column on the
  relational table (catch-all for rare/legacy fields, still queryable)

### Collections to Tables (high-level mapping, detailed in domain specs)

| MongoDB Collection | Target Domain | Target Table(s) |
|-------------------|--------------|-----------------|
| `med_medications` | Clinical Records | `clinical_medications` |
| `med_diagnoses` | Clinical Records | `clinical_diagnoses` (merge with MariaDB `diagnoses`) |
| `med_clinical_notes` | Clinical Documentation | `clinical_notes` |
| `med_assessments` | Clinical Documentation | `clinical_assessments` |
| `med_vital_extensions` | Clinical Records | `vital_extensions` (child of `vitals`) |
| `med_problems` | Clinical Records | `problem_list` |
| `med_procedures` | Clinical Documentation | `clinical_procedures` |
| `med_care_plans` | Clinical Documentation | `care_plans` |
| `med_social_histories` | Clinical Records | `social_histories` |
| `med_referrals` | Care Coordination | `referrals` |

Each domain spec will define the full column layout for its target tables.
