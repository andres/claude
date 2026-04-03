# 10 — Client Identity

> Core identity, demographics, contacts, and relationships for behavioral health clients.

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

Client Identity is the foundation of NewBear. Every other domain references a client.
This domain owns who the client is (identity, demographics), how to reach them (addresses,
phones, emails), who is in their life (relationships, families), and metadata that follows
them across all clinical, billing, and program interactions.

Primary users: front desk, intake staff, clinicians, billing staff, and AI agents resolving
client context from voice/text input.

---

## Legacy Mapping

### Tables Migrated From

| Legacy Table | Legacy DB | Migration Category | NewBear Table |
|-------------|-----------|-------------------|---------------|
| `people` (type='Client') | MariaDB | B — Restructured | `clients` |
| `people` (identifiable_type='User') | MariaDB | B — Restructured | Stays in Workforce domain (`staff_persons`) |
| `people` (identifiable_type='Tfc::Parent') | MariaDB | B — Restructured | Stays in Foster Care domain |
| `names` | MariaDB | A — Direct Map | `client_names` |
| `addresses` (addressable_type='Person') | MariaDB | B — Restructured | `client_addresses` |
| `phones` (phonable_type='Person') | MariaDB | B — Restructured | `client_phones` |
| `emails` (emailable_type='Person') | MariaDB | B — Restructured | `client_emails` |
| `genders` | MariaDB | B — Restructured | `client_genders` |
| `gender_types` | MariaDB | A — Direct Map | `gender_types` |
| `civil_statuses` | MariaDB | B — Restructured | `client_civil_statuses` |
| `civil_status_types` | MariaDB | A — Direct Map | `civil_status_types` |
| `relationships` | MariaDB | A — Direct Map | `client_relationships` |
| `families` | MariaDB | A — Direct Map | `families` |
| `taggables` / `tags` | MariaDB | A — Direct Map | `client_tags` / `tags` |

### Key Changes from Legacy

- **No more STI on `people`:** The `people` table was shared between clients, staff persons,
  and TFC parents via Single Table Inheritance. In NewBear, `clients` is a dedicated table.
  Staff persons live in the Workforce domain. TFC parents live in the Foster Care domain.
- **No more polymorphic contacts:** Legacy `addresses`, `phones`, and `emails` used polymorphic
  `*_type` / `*_id` columns to serve people, companies, and locations. In NewBear, each
  entity type gets its own contact tables (`client_addresses`, `client_phones`, `client_emails`).
  Companies and locations get their own in their respective domains.
- **Current name is denormalized:** Legacy required a subquery (`MAX(id)`) to get the current
  name. In NewBear, `clients` has `first_name`, `last_name`, etc. directly. The `client_names`
  table preserves full name history.
- **Gender modernized:** Legacy had a `sex` varchar on `people` plus a `genders` STI table
  with `gender_types`. NewBear separates biological sex (for clinical/billing) from gender
  identity (for respectful care), both as structured fields.
- **Merge tracking explicit:** Legacy used `hidden` + `hidden_active_client_id` for merged
  records. NewBear has an explicit `client_merges` table with full audit trail.
- **SSN encrypted properly:** Legacy had both `ssn` (plaintext) and `encrypted_ssn`. NewBear
  stores only encrypted, with application-level decryption for authorized users.

### Migration Risks

- **STI splitting:** Every `people` row must be routed to the correct NewBear table based on
  `type` and `identifiable_type`. Rows with no `type` and no `identifiable_type` need manual review.
- **Polymorphic contact splitting:** `addresses` rows with `addressable_type = 'Person'` must
  be matched to the correct NewBear table based on whether the person is a client, staff, or
  TFC parent.
- **Name denormalization:** Migrating `MAX(id)` name into `clients` columns — must handle
  clients with zero name records (data quality issue in some agencies).
- **Inconsistent sex values:** Legacy data may contain casing variations or blanks beyond
  the documented `'male'`, `'female'`, `'unknown'`.
- **SSN data:** Some agencies store plaintext SSN, others encrypted. Migration must handle both.

---

## Capabilities

### Must Have (Day 1)

1. **Client registration** — Create a new client with demographics, contact info, and identifiers
2. **Client search** — Search by name, DOB, client number, SSN (last 4), phone — fast, fuzzy, typo-tolerant
3. **Client profile view** — Single screen showing identity, demographics, contacts, active programs, alerts, photo
4. **Name management** — Update name with full history preserved (legal name changes, corrections)
5. **Contact management** — CRUD for addresses, phones, emails with type labels and HIPAA consent flags
6. **Relationship management** — Link family members, emergency contacts, guardians, responsible parties
7. **Client merge** — Merge duplicate clients with full audit trail and cascading updates across all domains
8. **Demographics** — Sex, gender identity, pronouns, DOB, date of death, citizenship, civil status, race, ethnicity, language
9. **Identifiers** — Client number, SSN (encrypted), Medicaid number, external system IDs
10. **Client photo** — Face photo for identification at check-in
11. **Soft delete with reason** — Deactivate client with reason, all data preserved
12. **Tags** — Flexible tagging system for agency-defined categorization

### Should Have (Fast Follow)

1. **Duplicate detection** — AI-assisted detection of potential duplicates on create (name + DOB + SSN fuzzy match)
2. **Client timeline** — Chronological view of all events across all domains for a client
3. **Consent status summary** — At-a-glance view of active consents (owned by Consent & Privacy domain, displayed here)
4. **Bulk import** — CSV/Excel import for agency onboarding or data migration from other systems
5. **Client alerts** — Configurable alerts that display on the client header (allergy, safety risk, legal hold, etc.)

### Future

1. **Client self-service profile** — Client updates own demographics via portal
2. **Identity verification** — Integration with external identity services
3. **Address geocoding** — Auto-geocode addresses for proximity-based features (transportation, service area)
4. **Family genogram** — Visual family relationship map

---

## Entities

### `clients`

> The core client identity record. One row per client.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `client_number` | varchar(50) | NO | Unique client identifier, agency-assigned |
| `first_name` | varchar(100) | NO | Current first name (denormalized from client_names) |
| `middle_name` | varchar(100) | YES | Current middle name |
| `last_name` | varchar(100) | NO | Current last name (denormalized from client_names) |
| `preferred_name` | varchar(100) | YES | Preferred/chosen name |
| `name_suffix` | varchar(20) | YES | Jr, III, etc. |
| `name_prefix` | varchar(20) | YES | De, Van, etc. |
| `date_of_birth` | date | NO | |
| `date_of_death` | date | YES | |
| `cause_of_death` | varchar(255) | YES | |
| `death_by_suicide` | boolean | NO | Default false |
| `sex` | varchar(20) | NO | Biological sex: 'male', 'female', 'unknown', 'intersex' — used for clinical/billing |
| `gender_identity` | varchar(50) | YES | Self-reported gender identity |
| `pronouns` | varchar(50) | YES | Preferred pronouns |
| `ssn_encrypted` | varchar(255) | YES | Encrypted SSN — application-level decryption |
| `ssn_last_four` | varchar(4) | YES | Last 4 of SSN for search (derived, stored for index) |
| `ssn_not_available` | boolean | NO | Default false |
| `citizenship` | varchar(100) | YES | |
| `nationality` | varchar(100) | YES | |
| `primary_language` | varchar(50) | YES | |
| `requires_interpreter` | boolean | NO | Default false |
| `race` | varchar(100) | YES | |
| `ethnicity` | varchar(100) | YES | |
| `marital_status` | varchar(50) | YES | |
| `location_id` | bigint | YES | FK locations — primary site |
| `secondary_location_id` | bigint | YES | FK locations |
| `pcp_id` | bigint | YES | FK pcps — primary care physician |
| `pharmacy_id` | bigint | YES | FK pharmacies — preferred pharmacy |
| `photo_url` | varchar(500) | YES | Path to face photo in file store |
| `is_new` | boolean | NO | Default true |
| `returning` | boolean | NO | Default false |
| `treat_as_adult` | boolean | NO | Default false — minor treated as adult for consent |
| `see_nurse` | boolean | NO | Default false |
| `pcp_auto_fax` | boolean | NO | Default false |
| `health_info_sharing_opt_in` | boolean | NO | Default true |
| `stripe_customer_id` | varchar(255) | YES | Payment integration |
| `oasas_account_id` | varchar(255) | YES | NY OASAS ID |
| `cib_number` | varchar(255) | YES | |
| `merged_into_id` | bigint | YES | FK self-ref — if this client was merged into another |
| `merged_at` | timestamptz | YES | When merged |
| `legacy_id` | integer | YES | Original people.id from legacy Bear |
| `legacy_table` | varchar(50) | YES | 'people' |
| `legacy_source` | varchar(20) | YES | 'mariadb' |
| `migrated_at` | timestamptz | YES | |
| `metadata` | jsonb | YES | Catch-all for rare/legacy fields (<10% usage) |
| `created_at` | timestamptz | NO | |
| `created_by` | bigint | NO | FK users |
| `updated_at` | timestamptz | NO | |
| `updated_by` | bigint | NO | FK users |
| `deleted_at` | timestamptz | YES | Soft delete |
| `deleted_by` | bigint | YES | FK users |
| `deleted_reason` | text | YES | |

**Relationships:**
- `has_many :client_names` — name history
- `has_many :client_addresses`
- `has_many :client_phones`
- `has_many :client_emails`
- `has_many :client_genders` — gender history
- `has_many :client_civil_statuses` — civil status history
- `has_many :client_relationships` → families
- `has_many :client_tags` → tags
- `has_many :client_merges` — merge audit trail
- `has_many :client_alerts`
- Referenced by: every other domain via `client_id`

**Indexes:**
- `idx_clients_client_number` UNIQUE — fast lookup by client number
- `idx_clients_name` — (`last_name`, `first_name`) for name search
- `idx_clients_dob` — date of birth search
- `idx_clients_ssn_last_four` — SSN search
- `idx_clients_location_id` — clients per location
- `idx_clients_deleted_at` — filter active clients
- `idx_clients_merged_into_id` — find merged records

---

### `client_names`

> Name history. Every name change creates a new record. Latest by MAX(id) is current.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `client_id` | bigint | NO | FK clients |
| `first` | varchar(100) | NO | |
| `middle` | varchar(100) | YES | |
| `last` | varchar(100) | NO | |
| `prefix` | varchar(20) | YES | Name prefix (De, Van) |
| `suffix` | varchar(20) | YES | Jr, III |
| `alias` | varchar(100) | YES | |
| `preferred` | varchar(100) | YES | |
| `maiden` | varchar(100) | YES | |
| `reason_for_change` | varchar(255) | YES | Why the name changed |
| `legacy_id` | integer | YES | Original names.id |
| `created_at` | timestamptz | NO | |
| `created_by` | bigint | NO | FK users |
| `deleted_at` | timestamptz | YES | |
| `deleted_by` | bigint | YES | |

**Indexes:**
- `idx_client_names_client_id` — names for a client
- `idx_client_names_search` — (`last`, `first`) for search across history

---

### `client_addresses`

> Client addresses. Multiple per client, typed (Home, Postal, etc.).

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `client_id` | bigint | NO | FK clients |
| `address_type` | varchar(50) | NO | 'Home', 'Postal', 'Temporary', 'Primary home', 'Vacation home' |
| `street_1` | varchar(255) | NO | |
| `street_2` | varchar(255) | YES | |
| `city` | varchar(100) | NO | |
| `state_id` | bigint | YES | FK us_states |
| `zip` | varchar(10) | NO | |
| `county` | varchar(100) | YES | |
| `country` | varchar(50) | YES | Default 'US' |
| `latitude` | decimal(10,7) | YES | Geocoded |
| `longitude` | decimal(10,7) | YES | Geocoded |
| `is_primary` | boolean | NO | Default false — one primary per client |
| `hipaa_permission` | boolean | NO | Default false — OK to send mail here |
| `note` | text | YES | |
| `legacy_id` | integer | YES | Original addresses.id |
| `created_at` | timestamptz | NO | |
| `created_by` | bigint | NO | FK users |
| `updated_at` | timestamptz | NO | |
| `updated_by` | bigint | NO | FK users |
| `deleted_at` | timestamptz | YES | |
| `deleted_by` | bigint | YES | |

**Indexes:**
- `idx_client_addresses_client_id` — addresses for a client
- `idx_client_addresses_zip` — geographic queries

---

### `client_phones`

> Client phone numbers. Multiple per client, typed by flags.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `client_id` | bigint | NO | FK clients |
| `number` | varchar(20) | NO | Stored normalized (digits only) |
| `extension` | varchar(10) | YES | |
| `phone_type` | varchar(20) | NO | 'home', 'mobile', 'work', 'home_fax', 'work_fax' |
| `is_primary` | boolean | NO | Default false |
| `use_for_reminders` | boolean | NO | Default false |
| `hipaa_permission` | boolean | NO | Default false |
| `note` | text | YES | |
| `legacy_id` | integer | YES | |
| `created_at` | timestamptz | NO | |
| `created_by` | bigint | NO | FK users |
| `deleted_at` | timestamptz | YES | |
| `deleted_by` | bigint | YES | |

**Indexes:**
- `idx_client_phones_client_id` — phones for a client
- `idx_client_phones_number` — reverse lookup by phone number

---

### `client_emails`

> Client email addresses.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `client_id` | bigint | NO | FK clients |
| `email` | varchar(255) | NO | |
| `email_type` | varchar(20) | YES | 'personal', 'work', etc. |
| `is_primary` | boolean | NO | Default false |
| `hipaa_permission` | boolean | NO | Default true |
| `legacy_id` | integer | YES | |
| `created_at` | timestamptz | NO | |
| `created_by` | bigint | NO | FK users |
| `deleted_at` | timestamptz | YES | |
| `deleted_by` | bigint | YES | |

**Indexes:**
- `idx_client_emails_client_id` — emails for a client
- `idx_client_emails_email` — reverse lookup

---

### `client_relationships`

> Links a client to people in their life: family, guardians, emergency contacts.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `client_id` | bigint | NO | FK clients — the client |
| `related_person_id` | bigint | YES | FK clients — if the related person is also a client |
| `family_id` | bigint | YES | FK families — family grouping |
| `relationship_type` | varchar(50) | NO | 'parent', 'child', 'spouse', 'sibling', 'guardian', 'emergency_contact', 'other' |
| `first_name` | varchar(100) | YES | Name of related person (if not a client) |
| `last_name` | varchar(100) | YES | |
| `phone` | varchar(20) | YES | Contact phone (if not a client) |
| `email` | varchar(255) | YES | Contact email (if not a client) |
| `is_emergency_contact` | boolean | NO | Default false |
| `is_guardian` | boolean | NO | Default false |
| `is_responsible_party` | boolean | NO | Default false — financially responsible |
| `lives_with_client` | boolean | NO | Default false |
| `note` | text | YES | |
| `legacy_id` | integer | YES | Original relationships.id |
| `created_at` | timestamptz | NO | |
| `created_by` | bigint | NO | FK users |
| `deleted_at` | timestamptz | YES | |
| `deleted_by` | bigint | YES | |

---

### `families`

> Family grouping. Links multiple clients and relationships into a family unit.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `name` | varchar(100) | YES | Family name (optional label) |
| `legacy_id` | integer | YES | |
| `created_at` | timestamptz | NO | |
| `created_by` | bigint | NO | FK users |
| `deleted_at` | timestamptz | YES | |

---

### `client_merges`

> Audit trail for client merge operations. Replaces legacy hidden/hidden_active_client_id pattern.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `source_client_id` | bigint | NO | FK clients — the duplicate being merged away |
| `target_client_id` | bigint | NO | FK clients — the surviving record |
| `merged_by` | bigint | NO | FK users |
| `merged_at` | timestamptz | NO | |
| `reason` | text | YES | |
| `rollback_data` | jsonb | YES | Snapshot for undo capability |

---

### `client_tags`

> Join between clients and tags for flexible categorization.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `client_id` | bigint | NO | FK clients |
| `tag_id` | bigint | NO | FK tags |
| `created_at` | timestamptz | NO | |
| `created_by` | bigint | NO | FK users |
| `deleted_at` | timestamptz | YES | |

### `tags`

> Agency-defined tags for categorizing clients.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `name` | varchar(100) | NO | Unique per agency |
| `color` | varchar(7) | YES | Hex color for display |
| `legacy_id` | integer | YES | |
| `created_at` | timestamptz | NO | |
| `deleted_at` | timestamptz | YES | |

---

### `client_alerts`

> Configurable alerts that display on the client header. Safety, clinical, administrative.

| Column | Type | Nullable | Notes |
|--------|------|----------|-------|
| `id` | bigint | NO | PK, auto-increment |
| `client_id` | bigint | NO | FK clients |
| `alert_type` | varchar(50) | NO | 'safety', 'allergy', 'legal', 'clinical', 'administrative' |
| `severity` | varchar(20) | NO | 'critical', 'warning', 'info' |
| `message` | text | NO | Alert text |
| `active` | boolean | NO | Default true |
| `expires_at` | timestamptz | YES | Auto-deactivate after date |
| `created_at` | timestamptz | NO | |
| `created_by` | bigint | NO | FK users |
| `resolved_at` | timestamptz | YES | |
| `resolved_by` | bigint | YES | FK users |
| `deleted_at` | timestamptz | YES | |

---

## API Surface

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/clients | List clients with filters (name, DOB, location, program, tag) |
| POST | /api/v1/clients | Create new client |
| GET | /api/v1/clients/{id} | Get client profile (includes current name, primary contacts, active alerts) |
| PATCH | /api/v1/clients/{id} | Update client demographics |
| DELETE | /api/v1/clients/{id} | Soft delete with reason |
| GET | /api/v1/clients/{id}/names | Name history |
| POST | /api/v1/clients/{id}/names | Add name record (updates denormalized name on client) |
| GET | /api/v1/clients/{id}/addresses | List addresses |
| POST | /api/v1/clients/{id}/addresses | Add address |
| PATCH | /api/v1/clients/{id}/addresses/{aid} | Update address |
| DELETE | /api/v1/clients/{id}/addresses/{aid} | Remove address |
| GET | /api/v1/clients/{id}/phones | List phones |
| POST | /api/v1/clients/{id}/phones | Add phone |
| PATCH | /api/v1/clients/{id}/phones/{pid} | Update phone |
| DELETE | /api/v1/clients/{id}/phones/{pid} | Remove phone |
| GET | /api/v1/clients/{id}/emails | List emails |
| POST | /api/v1/clients/{id}/emails | Add email |
| GET | /api/v1/clients/{id}/relationships | List relationships |
| POST | /api/v1/clients/{id}/relationships | Add relationship |
| GET | /api/v1/clients/{id}/alerts | Active alerts |
| POST | /api/v1/clients/{id}/alerts | Create alert |
| PATCH | /api/v1/clients/{id}/alerts/{aid} | Update/resolve alert |
| GET | /api/v1/clients/{id}/tags | Client tags |
| POST | /api/v1/clients/{id}/tags | Add tag |
| DELETE | /api/v1/clients/{id}/tags/{tid} | Remove tag |
| POST | /api/v1/clients/{id}/merge | Merge another client into this one |
| GET | /api/v1/clients/{id}/timeline | Chronological events across all domains |
| POST | /api/v1/clients/search | Full search (fuzzy name, DOB, SSN last 4, phone, client number) |
| POST | /api/v1/clients/detect-duplicates | Check for potential duplicates before creating |

### AI Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | /api/v1/clients/query | Natural language query ("show me clients at Main St location over 65") |
| POST | /api/v1/clients/suggest | Context-aware suggestions (e.g., during intake: "similar client exists") |
| POST | /api/v1/clients/validate | Pre-validate a create/update before executing |

### Domain Events Published

| Event Type | Trigger | Payload |
|-----------|---------|---------|
| `client_identity.client.created` | New client registered | Client snapshot |
| `client_identity.client.updated` | Demographics changed | Changed fields |
| `client_identity.client.deleted` | Client soft-deleted | Client ID + reason |
| `client_identity.client.merged` | Two clients merged | Source ID, target ID, affected records |
| `client_identity.name.changed` | Name updated | Client ID, old name, new name |
| `client_identity.alert.created` | New alert added | Client ID, alert type, severity |
| `client_identity.alert.resolved` | Alert resolved | Client ID, alert ID |

### Domain Events Consumed

| Event Type | Source Domain | Action Taken |
|-----------|-------------|-------------|
| `care_programs.enrollment.created` | Care Programs | Update client.is_new if first enrollment |
| `clinical_records.death.recorded` | Clinical Records | Set date_of_death, cause_of_death |

---

## Business Rules

1. **Unique client number:** `client_number` must be unique. API returns `409 Conflict` on duplicate.
2. **DOB required:** Every client must have a date of birth. No nulls, no future dates.
3. **At least one name:** A client must have at least one `client_names` record.
4. **One primary address/phone/email:** At most one contact record per type can be `is_primary = true`. Setting a new primary clears the old one.
5. **SSN format:** If provided, SSN must be exactly 9 digits. Stored encrypted, last 4 derived.
6. **Merge is one-way:** Source client is marked `merged_into_id`, all FKs across all domains are updated to point to target. Source becomes read-only.
7. **Cannot delete merged client:** A client that has been the target of a merge cannot be soft-deleted without first unmerging.
8. **Death date after birth date:** If `date_of_death` is set, it must be >= `date_of_birth`.
9. **Name change creates history:** Updating name always creates a new `client_names` record and updates denormalized columns on `clients`.

---

## Dependencies

### Depends On

| Domain | Why |
|--------|-----|
| Workforce | `created_by`, `updated_by`, `deleted_by` reference users |
| (None else) | Client Identity is a foundation domain |

### Depended On By

| Domain | Why |
|--------|-----|
| Every domain | All domains reference `client_id` |

---

## Clinical Terminology

| Code System | Usage in This Domain |
|------------|---------------------|
| None | Client Identity does not store coded clinical data. Race/ethnicity may adopt CDC race codes in future. |

---

## Open Questions

1. Should `race` and `ethnicity` use CDC/OMB standard categories or remain free text?
2. Should `primary_language` reference ISO 639 codes or a lookup table?
3. How many legacy agencies have plaintext SSNs vs. already-encrypted? Affects migration script.
4. Should the client photo be stored in the DB (blob) or file store (URL)? Leaning file store.
5. How does the client portal domain authenticate a client? Separate identity or linked to this record?
