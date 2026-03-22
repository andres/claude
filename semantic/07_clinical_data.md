# Domain 7: Clinical Data

## Overview
Clinical records: diagnoses (ICD codes), medications, prescriptions, and related
clinical documentation stored in both MariaDB and MongoDB.

## Tables

### `diagnoses`
Client diagnosis records (MariaDB).

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |
| `icd_id` | int(11) | FK to icds |
| `icd_string` | varchar(255) | ICD code string (denormalized) |
| `axis` | int(11) | DSM axis (legacy) |
| `position` | int(11) | Display order / priority |
| `dx_type` | varchar(1) | Diagnosis type |
| `severity` | varchar(255) | Severity |
| `rule_out` | tinyint(1) | Rule-out diagnosis |
| `tainted` | tinyint(1) | Tainted flag |
| `note` | varchar(255) | Note |
| `diagnosis_history_id` | int(11) | FK to diagnosis_histories |
| `encounter_form_id` | int(11) | FK to encounter_forms |
| `medical_condition_id` | int(11) | FK to medical_conditions |
| `endorsed_by` | int(11) | FK to users |
| `created_by` | int(11) | FK to users |
| `updated_by` | int(11) | FK to users |
| `deleted_by` | int(11) | FK to users |
| `created_at` | datetime | Record creation |
| `deleted_at` | datetime | Soft delete |
| `deleted_status` | varchar(255) | Reason for deletion |
| `deleted_note` | text | Deletion note |

> **GOTCHA:** `diagnoses.icd_string` is denormalized — it contains the ICD code string. But for the full description, join to the `icds` table.

**Key Relationships:**
- `belongs_to :client`, `:icd`, `:diagnosis_history`, `:encounter_form`
- `has_many :procedures`
- `has_many :fees` (through procedures)

---

### `icds`
ICD-10 diagnosis code reference table.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `code` | varchar(255) | ICD-10 code |
| `description` | varchar(255) | Description |

- `has_many :diagnoses`
- `has_many :icd_descriptions`
- `has_many :nlm_value_sets` (polymorphic)

---

### `diagnosis_histories`
History of diagnoses per client.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |

---

### `medications`
Medication records for clients.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |

---

### `prescriptions`
Prescription orders (non-eRx).

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |

---

### `administered_meds`
Medication administration records.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `medication_id` | int(11) | FK to medications |
| `med_administration_log_id` | int(11) | FK to med_administration_logs |
| `encounter_form_id` | int(11) | FK to encounter_forms |

---

### `immunizations` / `immunization_histories`
Vaccination records.

---

### `vitals`
Patient vital signs.

---

### `allergies` (`reported_allergies`)
Allergy records per client.

---

### `medical_conditions`
Active medical conditions.

---

## MongoDB Collections (Mongoid)

These are stored in MongoDB, not MariaDB. They use `belongs_to_record` (custom Mongoid macro)
to reference MariaDB records by ID.

| Collection | Description | References |
|-----------|-------------|------------|
| `med_medications` | CCDA medication records | client_id, encounter_form_id, user_id |
| `med_diagnoses` | CCDA diagnosis records | client_id, encounter_form_id |
| `med_clinical_notes` | Clinical notes | client_id, encounter_form_id, user_id |
| `med_assessments` | Assessment records | client_id, encounter_form_id, user_id |
| `med_vital_extensions` | Extended vital data | client_id, encounter_form_id |
| `med_problems` | Problem list | client_id, encounter_form_id |
| `med_procedures` | Procedure records | client_id, encounter_form_id |
| `med_care_plans` | Care plan records | client_id, encounter_form_id |
| `med_social_histories` | Social history | client_id, encounter_form_id |
| `med_referrals` | Referral records | client_id, encounter_form_id |

**Note:** MongoDB collections use string-based IDs and reference MariaDB integer IDs.
Cross-database joins are not possible at the SQL level — application code bridges the gap.

---

## Entity Relationship Summary

```
diagnoses
  ├── N:1 client (people)
  ├── N:1 icd (ICD-10 codes)
  ├── N:1 encounter_form
  └── 1:N procedures → charges → billcases

medications
  └── N:1 client (people)
      └── 1:N administered_meds
            └── N:1 encounter_form

[MongoDB collections]
  └── references client_id, encounter_form_id (cross-DB)
```
