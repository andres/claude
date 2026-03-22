# Domain 4: Appointments & Scheduling

## Overview
Appointment scheduling for client visits. Links clients, providers (users),
programs, locations, and can generate encounters and billing.

> **STATUS DERIVATION:** Appointments have NO `status` column. Status is derived
> from timestamp columns. See the STATUS DERIVATION section below `appointments`
> and `00_query_guide.md` for full details.

## Tables

### `appointments`
Central scheduling record.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |
| `user_id` | int(11) | FK to users (provider) |
| `appointment_type_id` | int(11) | FK to appointment_types |
| `program_enrollment_id` | int(11) | FK to program_enrollments |
| `location_id` | int(11) | FK to locations |
| `program_id` | int(11) | FK to programs |
| `activity_id` | int(11) | FK to activities |
| `schedresource_id` | int(11) | FK to schedresources |
| `crew_team_id` | int(11) | FK to crew_teams |
| `event_type_id` | int(11) | FK to event_types |
| `recursion_id` | int(11) | FK to recursions |
| `client_address_id` | int(11) | FK to addresses |
| `default_insurance_policy_id` | int(11) | FK to insurance_policies |
| `group_id` | int(11) | Group ID |
| `series_id` | int(11) | Series ID |
| `date_time_starts` | datetime | Appointment start time |
| `date_time_ends` | datetime | Appointment end time |
| `duration` | int(11) | Duration in minutes |
| `notes` | text | Appointment notes |
| `sms_at` | datetime | SMS reminder sent at |
| `created_at` | datetime | Record creation |
| `confirmed_at` | datetime | When confirmed |
| `cancelled_at` | datetime | When cancelled |
| `checked_in_at` | datetime | When checked in |
| `checked_out_at` | datetime | When checked out |
| `noshow_at` | datetime | When marked no-show |
| `deleted_at` | datetime | Soft delete |
| `updated_at` | datetime | Last update |
| `remote_cancelled_at` | datetime | Remote cancellation |
| `cancel_note` | varchar(255) | Cancellation note |
| `cancel_reason` | varchar(255) | Cancellation reason |
| `cancel_late` | tinyint(1) | Late cancellation flag |
| `noshow_reason` | varchar(255) | No-show reason |
| `detached` | tinyint(1) | Detached from series |
| `is_all_day` | tinyint(1) | All-day event |
| `skip_reminder` | tinyint(1) | Skip reminder |
| `out_of_office` | tinyint(1) | Out of office flag |
| `warn_overlap` | tinyint(1) | Warn on overlap |
| `credential_mismatch` | tinyint(1) | Credential mismatch flag |
| `color` | varchar(255) | Display color |
| `color_dark` | varchar(255) | Display color (dark) |
| `color_medium` | varchar(255) | Display color (medium) |
| `color_clear` | varchar(255) | Display color (clear) |
| `created_by` | int(11) | FK to users |
| `confirmed_by` | int(11) | FK to users |
| `cancelled_by` | int(11) | FK to users |
| `checked_in_by` | int(11) | FK to users |
| `checked_out_by` | int(11) | FK to users |
| `noshow_by` | int(11) | FK to users |
| `deleted_by` | int(11) | FK to users |

#### STATUS DERIVATION

Appointments have **NO `status` column**. Status is derived from timestamps:

| Derived Status | Condition |
|----------------|-----------|
| **Scheduled** | Created but `confirmed_at`, `cancelled_at`, `noshow_at`, `deleted_at` are all NULL |
| **Confirmed** | `confirmed_at` IS NOT NULL, `cancelled_at` IS NULL, `noshow_at` IS NULL, `deleted_at` IS NULL |
| **Checked In** | `checked_in_at` IS NOT NULL, `checked_out_at` IS NULL |
| **Completed** | `checked_out_at` IS NOT NULL |
| **Cancelled** | `cancelled_at` IS NOT NULL |
| **No-Show** | `noshow_at` IS NOT NULL |
| **Deleted** | `deleted_at` IS NOT NULL |

**"Valid" appointments** (used by DB index and most queries):
```sql
WHERE deleted_by IS NULL
  AND cancelled_at IS NULL
  AND noshow_at IS NULL
```

See `00_query_guide.md` for complete appointment query patterns.

**Key Relationships:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `belongs_to :client` | people | `client_id` |
| `belongs_to :user` | users | `user_id` |
| `belongs_to :appointment_type` | appointment_types | `appointment_type_id` |
| `belongs_to :program_enrollment` | program_enrollments | `program_enrollment_id` |
| `belongs_to :location` | locations | `location_id` |
| `belongs_to :program` | programs | `program_id` |
| `belongs_to :default_insurance_policy` | insurance_policies | `default_insurance_policy_id` |
| `has_one :encounter` | encounters | `appointment_id` |
| `has_one :crew_session` | crew_sessions | `appointment_id` |
| `has_one :travel_record` | travel_records | `appointment_id` |
| `has_one :video_call` | video_calls | `appointment_id` |
| `has_many :copays` | copays | `appointment_id` |
| `has_many :copay_requests` | copay_requests | `appointment_id` |
| `has_many :trackers` | trackers | `appointment_id` |
| `has_many :status_histories` | appointment_status_histories | `appointment_id` |
| `has_many :lilnotes` | lilnotes | polymorphic (lilnotable) |
| `has_many :reminder_messages` | reminder_messages | polymorphic (triggerable) |

---

### `appointment_types`
Configuration for appointment categories.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `user_id` | int(11) | FK to users |
| `form_id` | int(11) | FK to forms |

- `has_many :appointments`

---

### `activities`
Activity definitions linked to appointments.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `user_id` | int(11) | FK to users |
| `activity_type_id` | int(11) | FK to activity_types |

- `has_many :appointments`

---

### `activity_types`
Lookup for activity categories.

- `has_many :activities`

---

### `activity_groups` / `activity_templates`
Templates for predefined activity configurations.

- `activity_groups` → `has_many :activity_templates`
- `activity_templates` → `belongs_to :activity_group`, `belongs_to :activity_type`

---

### `recursions`
Recurring appointment patterns.

- Referenced by `appointments.recursion_id`

---

### `schedresources`
Scheduling resources (rooms, equipment).

- Referenced by `appointments.schedresource_id`
- `belongs_to :location`

---

### `appointment_status_histories`
Audit trail of appointment status changes.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `appointment_id` | int(11) | FK to appointments |

---

### `copays`
Client copayment at time of appointment.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |
| `user_id` | int(11) | FK to users |
| `appointment_id` | int(11) | FK to appointments |
| `copay_request_id` | int(11) | FK to copay_requests |
| `updated_by` | int(11) | FK to users |

- `has_many :copayments` (billing domain link)

---

## Entity Relationship Summary

```
appointments
  ├── N:1 client (people)
  ├── N:1 user (provider)
  ├── N:1 appointment_type → form
  ├── N:1 program_enrollment → program, location
  ├── N:1 location
  ├── N:1 program
  ├── N:1 default_insurance_policy
  ├── N:1 activity → activity_type
  ├── N:1 recursion (recurring series)
  ├── N:1 crew_team (group appointments)
  ├── 1:1 encounter → encounter_forms → superbill → billcase
  ├── 1:1 crew_session (group session)
  ├── 1:N copays → copayments
  └── 1:N appointment_status_histories
```
