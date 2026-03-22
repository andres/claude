# Domain 5: Encounters & Clinical Forms

## Overview
The clinical documentation engine. An appointment generates an encounter, which contains
encounter_forms (instances of form templates). Each encounter_form has completed pages,
a superbill for billing, and links to clinical data (diagnoses, procedures, etc.).

## Tables

### `encounters`
A clinical visit / encounter.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `user_id` | int(11) | FK to users (provider) |
| `client_id` | int(11) | FK to people (Client) |
| `appointment_id` | int(11) | FK to appointments |
| `referring_provider_id` | int(11) | FK to users |
| `client_policy_id` | int(11) | FK to insurance_policies |
| `created_by` | int(11) | FK to users |
| `deleted_by` | int(11) | FK to users |
| `dos` | date | Date of service |
| `time_ended` | datetime | When ended |
| `duration` | int(11) | Duration in minutes |
| `created_at` | datetime | Record creation |
| `deleted_at` | datetime | Soft delete |

**Key Relationships:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `belongs_to :user` | users | `user_id` |
| `belongs_to :client` | people | `client_id` |
| `belongs_to :appointment` | appointments | `appointment_id` |
| `has_many :encounter_forms` | encounter_forms | `encounter_id` |
| `has_many :forms` | forms | through encounter_forms |
| `has_many :diagnoses` | diagnoses | `encounter_id` |
| `has_many :chronicles` | chronicles | `encounter_id` |

---

### `encounter_forms`
Instance of a form within an encounter. This is the **central clinical record** --
it connects the encounter to the form template, client, program, and generates billing.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `encounter_id` | int(11) | FK to encounters |
| `form_id` | int(11) | FK to forms |
| `client_id` | int(11) | FK to people (Client) |
| `user_id` | int(11) | FK to users (current provider) |
| `started_by` | int(11) | FK to users |
| `closed_by` | int(11) | FK to users |
| `program_id` | int(11) | FK to programs |
| `program_enrollment_id` | int(11) | FK to program_enrollments |
| `crew_session_id` | int(11) | FK to crew_sessions |
| `state` | varchar(255) | Enum: `'started'`, `'completed'`, `'signed'` |
| `started_at` | datetime | When started |
| `closed_at` | datetime | When closed |
| `written_dos` | datetime | Written date of service |
| `elapsed_time` | int(11) | Time spent (seconds) |
| `parsed_at` | datetime | When parsed/printed |
| `current_page` | int(11) | Current page number |
| `timely_fashion` | varchar(255) | Timeliness flag |
| `next_due_date` | date | Next due date |
| `day_completion` | int(11) | Day completion counter |
| `created_at` | datetime | Record creation |
| `updated_at` | datetime | Last update |

**Enum values:**
- `state`: `'started'`, `'completed'`, `'signed'`

**Key Relationships:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `belongs_to :encounter` | encounters | `encounter_id` |
| `belongs_to :form` | forms | `form_id` |
| `belongs_to :client` | people | `client_id` |
| `belongs_to :user` | users | `user_id` |
| `belongs_to :program` | programs | `program_id` |
| `belongs_to :program_enrollment` | program_enrollments | `program_enrollment_id` |
| `has_one :superbill` | superbills | `encounter_form_id` |
| `has_one :printed_printable` | printables | polymorphic (documentable) |
| `has_one :tracker` | trackers | `encounter_form_id` |
| `has_many :completed_pages` | completed_pages | `encounter_form_id` |
| `has_many :form_pages` | form_pages | through form |
| `has_many :procedures` | procedures | through superbill |
| `has_many :fees` | fees | through procedures |
| `has_many :med_transmissions` | med_transmissions | `encounter_form_id` |
| `has_many :clinical_rule_registries` | clinical_rule_registries | `encounter_form_id` |

**Page Associations (70+ has_one):**
Each encounter_form has one instance of various clinical page types:
- `treatment_plan`, `sesnote`, `present_person`, `psychiatric_evaluation`
- `diagnosis_history`, `medication_history`, `vital`, `mental_status`
- Plus many more domain-specific page types

**MongoDB (Mongoid) Documents:**
- `med_diagnoses`, `med_medications`, `med_clinical_notes`, `med_assessments`
- `med_vital_extensions`, `med_problems`, `med_procedures`, etc.

---

### `forms`
Form template definitions.

> **GOTCHA: The form name column is `title`, NOT `name`. Use `forms.title` in all queries.**

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `title` | varchar(255) | **Form name (NOT `name`!)** |
| `instructions` | text | Form instructions |
| `is_intake` | tinyint(1) | Is intake form |
| `required` | tinyint(1) | Required form |
| `signature_required` | tinyint(1) | Signature required |
| `telemed` | tinyint(1) | Telemed-eligible |
| `front_desk` | tinyint(1) | Front desk form |
| `needs_review` | tinyint(1) | Needs supervisor review |
| `md_eval` | tinyint(1) | Medical evaluation form |
| `non_clinical` | tinyint(1) | Non-clinical form |
| `compressed` | tinyint(1) | Compressed display |
| `restricted_note` | tinyint(1) | 42 CFR Part 2 restricted |
| `show_admission` | tinyint(1) | Show admission fields |
| `show_discharge` | tinyint(1) | Show discharge fields |
| `for_no_show` | tinyint(1) | No-show form |
| `for_cancellation` | tinyint(1) | Cancellation form |
| `auto_close_current_program` | tinyint(1) | Auto-close current enrollment |
| `auto_close_all_programs` | tinyint(1) | Auto-close all enrollments |
| `due_from_enrollment` | int(11) | Days due after enrollment |
| `recurse_every` | int(11) | Recurrence interval |
| `default_appointment_time` | int(11) | Default appt duration |
| `pcp_form_id` | int(11) | FK to forms (PCP fax) |
| `due_after_form_id` | int(11) | FK to forms (self-ref) |
| `auto_enroll_program_id` | int(11) | FK to programs |
| `auto_close_program_id` | int(11) | FK to programs |

**Key Relationships:**
- `has_many :encounter_forms`
- `has_many :form_pages` → `has_many :pages` (through form_pages)
- `has_many :section_forms` → `has_many :sections` → `has_many :programs`
- `has_many :supervisions`
- `has_many :apptypes` (appointment types)
- `has_many :bundled_services`
- `has_and_belongs_to_many :on_complete_notifies` (users, via notify_form_user_completes)

---

### `pages`
Page definitions (building blocks of forms).

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |

- `has_many :form_pages` → `has_many :forms` (through form_pages)
- `has_one :page_extension`

---

### `form_pages`
Join between forms and pages (with ordering).

| Column | Type | Notes |
|--------|------|-------|
| `form_id` | int(11) | FK to forms |
| `page_id` | int(11) | FK to pages |
| `cmodel_id` | int(11) | FK to cmodels |

---

### `completed_pages`
Filled-in page instance within an encounter_form.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `encounter_form_id` | int(11) | FK to encounter_forms |

---

### `superbills`
Billing summary generated from an encounter_form.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `encounter_form_id` | int(11) | FK to encounter_forms |

- `has_many :procedures`
- Links to `billcase` through charge generation

---

### `procedures`
Individual service line items on a superbill.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `superbill_id` | int(11) | FK to superbills |
| `fee_id` | int(11) | FK to fees |
| `diagnosis_id` | int(11) | FK to diagnoses |
| `authorization_id` | int(11) | FK to authorizations |
| `place_of_service_id` | int(11) | FK to place_of_services |
| `tat_tracker_id` | int(11) | FK to tat_trackers |
| `encounter_form_id` | int(11) | FK to encounter_forms |

**Key Relationships:**
- `belongs_to :superbill`, `:fee`, `:diagnosis`, `:authorization`
- `has_and_belongs_to_many :charges` (charges_procedures)
- `has_one :used_unit`
- `has_many :nlm_value_sets` (through fee)

---

### `place_of_services`
CMS Place of Service codes.

- Referenced by procedures and charges

---

## Entity Relationship Summary

```
appointment
  └── 1:1 encounter
        ├── 1:N encounter_forms
        │     ├── N:1 form (template)
        │     │     └── 1:N form_pages → pages
        │     ├── 1:N completed_pages
        │     ├── 1:1 superbill
        │     │     └── 1:N procedures
        │     │           ├── N:1 fee (from schedule)
        │     │           ├── N:1 diagnosis
        │     │           ├── N:1 authorization
        │     │           └── N:N charges (billing)
        │     ├── 1:1 treatment_plan (page)
        │     ├── 1:1 diagnosis_history (page)
        │     └── 1:1 [70+ other page types]
        └── 1:N diagnoses
```
