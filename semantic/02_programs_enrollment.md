# Domain 2: Programs & Enrollment

## Overview
Programs represent treatment programs (outpatient, residential, TFC, OTP, etc.).
Clients are enrolled in programs at specific locations. Enrollment is the central
operational unit linking a client to services.

## Tables

### `programs`
Treatment program definitions.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `name` | varchar(255) | Program name |
| `acronym` | varchar(255) | Program abbreviation |
| `description` | text | Program description |
| `guidelines` | mediumtext | Program guidelines |
| `active` | tinyint(1) | Active flag |
| `tfc` | tinyint(1) | Is TFC program |
| `adoption` | tinyint(1) | Is adoption program |
| `auto_enrollment` | tinyint(1) | Auto-enroll flag |
| `treatment_family` | tinyint(1) | Treatment family program |
| `inpatient` | tinyint(1) | Inpatient program flag |
| `otp` | tinyint(1) | OTP program flag |
| `beds` | tinyint(1) | Has beds flag |
| `enables_transportation` | tinyint(1) | Transportation enabled |
| `enables_mar` | tinyint(1) | MAR enabled |
| `director_id` | int(11) | FK to users |
| `manager_id` | int(11) | FK to users |
| `crew_team_id` | int(11) | FK to crew_teams |
| `payor_for_no_show_id` | int(11) | FK to companies (Payor) |
| `preferred_payor_id` | int(11) | FK to companies (Payor) |
| `ub04_doc_id` | int(11) | FK to users |
| `oasas_program_id` | varchar(255) | OASAS program ID |
| `created_at` | datetime | Record creation |
| `updated_at` | datetime | Last update |
| `deleted_at` | datetime | Soft delete |

**Key Relationships:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `has_many :program_enrollments` | program_enrollments | `program_id` |
| `has_many :clients` | people | through program_enrollments |
| `has_many :program_locations` | program_locations | `program_id` |
| `has_many :locations` | locations | through program_locations |
| `has_many :sections` | sections | `program_id` |
| `has_many :encounter_forms` | encounter_forms | `program_id` |
| `has_many :appointments` | appointments | `program_id` |
| `has_many :assignments` | assignments | `program_id` |
| `has_many :enrollment_levels` | enrollment_levels | `program_id` |
| `has_many :bundled_services` | bundled_services | `program_id` |
| `has_many :crew_teams` | crew_teams | `program_id` |
| `has_many :tfc_assignments` | tfc_assignments | `program_id` |
| `has_many :bundled_attendances` | bundled_attendances | `program_id` |
| `has_and_belongs_to_many :clforms` | clforms_programs | join table |
| `has_and_belongs_to_many :goals` | goals_programs | join table |
| `has_and_belongs_to_many :objectives` | objectives_programs | join table |
| `has_and_belongs_to_many :interventions` | interventions_programs | join table |
| `has_and_belongs_to_many :life_domains` | life_domains_programs | join table |
| `has_and_belongs_to_many :admission_reasons` | admission_reasons_programs | join table |
| `has_and_belongs_to_many :discharge_reasons` | discharge_reasons_programs | join table |

---

### `program_enrollments`
Central join between client, program, and location. Tracks enrollment lifecycle.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |
| `program_id` | int(11) | FK to programs |
| `location_id` | int(11) | FK to locations |
| `program_location_id` | int(11) | FK to program_locations |
| `user_id` | int(11) | FK to users (enrolling user) |
| `enrollment_id` | int(11) | FK to enrollments |
| `enrollment_level_id` | int(11) | FK to enrollment_levels |
| `primary_insurance_policy_id` | int(11) | FK to insurance_policies |
| `secondary_insurance_policy_id` | int(11) | FK to insurance_policies |
| `terciary_insurance_policy_id` | int(11) | FK to insurance_policies |
| `provider_id` | int(11) | FK to users (provider) |
| `encounter_form_id` | int(11) | FK to encounter_forms |
| `encounter_id` | int(11) | FK to encounters |
| `reviewed_by` | int(11) | FK to users |
| `requested_by` | int(11) | FK to users |
| `approved_by` | int(11) | FK to users |
| `denied_by` | int(11) | FK to users |
| `first_approver_id` | int(11) | FK to users |
| `second_approver_id` | int(11) | FK to users |
| `closed_by` | int(11) | FK to users |
| `approved_at` | datetime | Approval timestamp |
| `expires_at` | datetime | Expiration timestamp |
| `denied_at` | datetime | Denial timestamp |
| `requested_at` | datetime | Request timestamp |
| `effective_enrollment_date` | date | Effective enrollment date |
| `referral_date` | date | Referral date |
| `referral_status` | varchar(255) | Referral status |
| `closure_reason` | varchar(255) | Reason for closure |
| `reason_for_enrollment` | text | Enrollment reason |
| `referral_reason` | text | Referral reason |
| `referral_source` | varchar(255) | Referral source |
| `severity` | varchar(255) | Severity level |
| `successful_discharge` | tinyint(1) | Successful discharge flag |
| `auto_enrolled` | tinyint(1) | Auto-enrolled flag |
| `note` | text | Enrollment note |
| `handoff` | date | Handoff date |
| `created_by` | int(11) | FK to users |
| `created_at` | datetime | Record creation |
| `updated_by` | int(11) | FK to users |
| `updated_at` | datetime | Last update |
| `deleted_at` | datetime | Soft delete |

**Key Relationships:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `belongs_to :client` | people | `client_id` |
| `belongs_to :program` | programs | `program_id` |
| `belongs_to :location` | locations | `location_id` |
| `belongs_to :enrollment_level` | enrollment_levels | `enrollment_level_id` |
| `has_many :encounter_forms` | encounter_forms | `program_enrollment_id` |
| `has_many :appointments` | appointments | `program_enrollment_id` |
| `has_many :assignments` | assignments | `program_enrollment_id` |
| `has_many :trackers` | trackers | `program_enrollment_id` |
| `has_many :bundled_attendances` | bundled_attendances | `program_enrollment_id` |
| `has_many :tfc_assignments` | tfc_assignments | `program_enrollment_id` |
| `has_many :spot_assignments` | spot_assignments | `program_enrollment_id` |
| `has_many :unit_counters` | unit_counters | `program_enrollment_id` |
| `has_many :sections` | sections | through program |
| `has_many :crew_memberships` | crew_memberships | through program |

**Scopes:** `current`, `expired`, `pending`, `approved`, `denied`, `ever_used`, `otp`, `transportation`, `with_treatment_family`

---

### `locations`
Physical sites / facilities.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `name` | varchar(255) | Location name |
| `address_1` | varchar(255) | Street line 1 |
| `address_2` | varchar(255) | Street line 2 |
| `city` | varchar(255) | City |
| `zip` | varchar(255) | ZIP code |
| `county` | varchar(255) | County |
| `state_id` | int(11) | FK to us_states |
| `npi` | varchar(255) | NPI number |
| `tax_id` | varchar(255) | Tax ID |
| `time_zone` | varchar(255) | Time zone |
| `billing_name` | varchar(60) | Billing name |
| `facility_name` | varchar(60) | Facility name |
| `medicaid_id` | varchar(255) | Medicaid ID |
| `clia_number` | varchar(255) | CLIA number |
| `dea_number` | varchar(255) | DEA number |
| `phone_1` | varchar(255) | Phone 1 |
| `phone_2` | varchar(255) | Phone 2 |
| `phone_3` | varchar(255) | Phone 3 |
| `minor_age` | int(11) | Minor age threshold (default: 18) |
| `fips_county` | varchar(255) | FIPS county code |
| `oasas_provider_id` | varchar(255) | OASAS provider ID |
| `responsible_id` | int(11) | FK to users |
| `place_of_service_id` | int(11) | FK to place_of_services |
| `tat_rule_id` | int(11) | FK to tat_rules |
| `track_sigforms` | tinyint(1) | Sigform tracking flag |
| `serves_otp` | tinyint(1) | OTP location flag |
| `created_at` | datetime | Record creation |
| `updated_at` | datetime | Last update |
| `deleted_at` | datetime | Soft delete |

**Key Relationships:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `has_many :program_locations` | program_locations | `location_id` |
| `has_many :programs` | programs | through program_locations |
| `has_many :appointments` | appointments | `location_id` |
| `has_many :clients` | people | `location_id` |
| `has_many :assignments` | assignments | `location_id` |
| `has_many :tfc_homes` | tfc_homes | `location_id` |
| `has_many :otp_pumps` | otp_pumps | `location_id` |
| `has_many :otp_meds` | otp_meds | `location_id` |
| `has_many :otp_bottles` | otp_bottles | `location_id` |
| `has_many :spot_areas` | spot_areas | `location_id` |
| `has_many :addresses` | addresses | polymorphic |
| `has_and_belongs_to_many :taxes` | locations_taxes | join table |
| `has_and_belongs_to_many :supervisions` | locations_supervisions | join table |

---

### `program_locations`
Join between programs and locations.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `program_id` | int(11) | FK to programs |
| `location_id` | int(11) | FK to locations |
| `ub04_doc_id` | int(11) | FK to users |
| `inactivated_at` | datetime | Soft deactivation |

---

### `enrollment_levels`
Level of care within a program enrollment.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `program_id` | int(11) | FK to programs |

---

### `enrollments`
Master enrollment record for a client.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |

---

### `sections`
Subdivisions within a program (groups of forms).

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `program_id` | int(11) | FK to programs |

**Key Relationships:**
- `has_many :section_forms` → `has_many :forms` (through section_forms)
- `has_many :sigforms`, `donesigforms`, `sigtrackers`

---

### `assignments`
Staff-to-client assignments within a program.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `user_id` | int(11) | FK to users |
| `client_id` | int(11) | FK to people (Client) |
| `program_enrollment_id` | int(11) | FK to program_enrollments |
| `program_id` | int(11) | FK to programs |
| `location_id` | int(11) | FK to locations |
| `assignment_type_id` | int(11) | FK to assignment_types |

---

## Enum Values

- **`program_enrollments.referral_status`**: `'Wait List'`, `'Active'`, `'closed'`, `'waitlist'`, `'approved'`, `'Suspended for LOC'`, `'pending'`, `'Priority'`, `'Enrolled'`
- **`program_enrollments.closure_reason`**: `''`, `'discharged'`, `'Completed'`, `'Moved out of area'`, `'Completed Treatment'`, `'Non-Compliance'`, `'Banned'`, `'Denial'`

---

## Entity Relationship Summary

```
programs
  ├── N:N locations (via program_locations)
  ├── 1:N program_enrollments
  │     ├── N:1 clients (people)
  │     ├── N:1 locations
  │     ├── 1:N encounter_forms
  │     ├── 1:N appointments
  │     ├── 1:N assignments
  │     └── 0:3 insurance_policies (pri/sec/ter)
  ├── 1:N sections → section_forms → forms
  ├── 1:N enrollment_levels
  └── N:N goals, objectives, interventions (via join tables)

locations
  ├── 1:N program_locations → programs
  ├── 1:N appointments
  ├── 1:N tfc_homes
  ├── 1:N otp_pumps, otp_meds, otp_bottles
  └── 1:N spot_areas → spot_rooms → spot_beds
```
