# Domain 9: Treatment Foster Care (TFC)

## Overview
Treatment Foster Care module. Manages foster homes, foster parents, child placements,
billing for TFC services, and foster parent documentation/forms.

**Table prefix:** `tfc_`

## Tables

### `tfc_assignments`
Links a client to a TFC home within a program enrollment.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `client_id` | integer | FK to people (Client) |
| `program_enrollment_id` | integer | FK to program_enrollments |
| `program_id` | integer | FK to programs |
| `user_id` | integer | FK to users |
| `tfc_home_id` | integer | FK to tfc_homes |

**Key Relationships:**
- `has_many :tfc_forms` (tfc_forms)
- `has_many :tfc_form_trackers`
- `has_many :tfc_billing_assignments`
- `has_many :tfc_billing_registries` (through tfc_billing_assignments)

---

### `tfc_homes`
Foster home / placement facility.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `location_id` | integer | FK to locations |

**Key Relationships:**
- `has_many :tfc_parents`
- `has_many :tfc_assignments`
- `has_many :tfc_forms`
- `has_many :tfc_relations`
- `has_many :addresses` (polymorphic)
- `has_many :tfc_parent_form_assignments`
- `has_many :tfc_mileage_logs`
- `has_many :tfc_file_uploads`
- `has_many :tfc_daily_logs`
- `has_many :tfc_medication_administrations`

---

### `tfc_parents`
Foster parents (has_secure_password — can log in to parent portal).

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `location_id` | integer | FK to locations |
| `tfc_home_id` | integer | FK to tfc_homes |
| `deleted_by` | integer | FK to users |

**Key Relationships:**
- `has_one :person` (polymorphic identifiable — shares `people` table)
- `has_many :tfc_form_trackers`
- `has_many :tfc_signatures`
- `has_many :tfc_supervisions`
- `has_many :tfc_parent_form_assignments`
- `has_many :training_sessions` (polymorphic)
- `has_many :training_periods` (polymorphic)

---

### `tfc_forms`
Forms completed within TFC (by parents or staff).

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `client_id` | integer | FK to people (Client) |
| `program_id` | integer | FK to programs |
| `program_enrollment_id` | integer | FK to program_enrollments |
| `tfc_parent_id` | integer | FK to tfc_parents (started_by / closed_by) |
| `tfc_home_id` | integer | FK to tfc_homes |
| `tfc_template_id` | integer | FK to tfc_templates |
| `tfc_assignment_id` | integer | FK to tfc_assignments |

- `has_many :tfc_completed_pages`
- `has_many :tfc_addendums`
- `has_one :tfc_form_tracker`, `:tfc_form_signature`, `:tfc_daily_log`

---

### `tfc_billing_registries`
Billing records for TFC services.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `program_enrollment_id` | integer | FK to program_enrollments |
| `client_id` | integer | FK to people (Client) |
| `fee_id` | integer | FK to fees |
| `insurance_policy_id` | integer | FK to insurance_policies |
| `payor_id` | integer | FK to companies (Payor) |
| `diagnosis_id` | integer | FK to diagnoses |
| `authorization_id` | integer | FK to authorizations |
| `tfc_placement_level_id` | integer | FK to tfc_placement_levels |
| `tfc_assignment_level_id` | integer | FK to tfc_assignment_levels |

- `has_one :superbill` → `has_one :billcase`
- Delegates `:program` from program_enrollment

---

### `tfc_billing_assignments`
Join between tfc_assignments and tfc_billing_registries.

---

### `tfc_assignment_levels`
Care level for a TFC assignment (links to insurance).

| Column | Type | Notes |
|--------|------|-------|
| `insurance_policy_id` | integer | FK to insurance_policies |

---

### `tfc_placement_levels`
Placement level definitions (affects fee schedule).

---

### Other TFC Tables

| Table | Description |
|-------|-------------|
| `tfc_templates` | Form template definitions |
| `tfc_template_pages` | Pages within templates |
| `tfc_completed_pages` | Filled-in form pages |
| `tfc_completed_parent_pages` | Parent-filled form pages |
| `tfc_parent_forms` | Forms for parent portal |
| `tfc_parent_form_assignments` | Parent form assignments |
| `tfc_parent_form_signatures` | Parent electronic signatures |
| `tfc_relations` | Family relationships in home |
| `tfc_members` | Household members |
| `tfc_families` | Family records |
| `tfc_signatures` | Electronic signatures |
| `tfc_signature_requests` | Signature request workflows |
| `tfc_signature_containers` | Signature storage |
| `tfc_supervisions` | Parent supervision records |
| `tfc_mileage_logs` | Mileage tracking |
| `tfc_mileages` | Mileage detail |
| `tfc_daily_logs` | Daily log entries |
| `tfc_log_entries` | Log entry details |
| `tfc_medication_administrations` | Med admin tracking |
| `tfc_medication_records` | Med records |
| `tfc_file_uploads` | File attachments |
| `tfc_file_categories` | File categorization |
| `tfc_dis_crits` | Discharge criteria |
| `tfc_needs` | Client needs assessment |
| `tfc_matches` | Placement matching |
| `tfc_objective_achievements` | Treatment objectives |
| `tfc_objective_logs` | Objective progress |
| `tfc_addendums` | Form addendums |
| `tfc_form_intros` | Form introductions |
| `tfc_form_references` | Form references |
| `tfc_form_trackers` | Form tracking |
| `tfc_form_signatures` | Form signatures |

---

## Entity Relationship Summary

```
tfc_homes
  ├── N:1 location
  ├── 1:N tfc_parents → person (people, polymorphic)
  ├── 1:N tfc_assignments
  │     ├── N:1 client (people)
  │     ├── N:1 program_enrollment
  │     ├── 1:N tfc_forms → tfc_completed_pages
  │     └── N:N tfc_billing_registries (via tfc_billing_assignments)
  │           ├── N:1 fee, diagnosis, authorization
  │           ├── N:1 insurance_policy → payor
  │           └── 1:1 superbill → billcase
  └── 1:N tfc_daily_logs, tfc_medication_administrations
```
