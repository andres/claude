# Domain 8: Users & Staff

## Overview
Staff, providers, and system users. The `users` table has a `type` column but
STI is **explicitly disabled** (`self.inheritance_column = nil`).
Users have credentials, certifications, roles, and supervisions.

> **GOTCHA — How to get a user/staff member's name:** Users do NOT have name columns. Names are stored through the polymorphic `identifiable` link on the `people` table:
> ```sql
> SELECT u.id, u.login, u.title, n.first, n.last
> FROM users u
> JOIN people p ON p.identifiable_id = u.id AND p.identifiable_type = 'User'
> JOIN names n ON n.person_id = p.id AND n.deleted_at IS NULL
> WHERE u.deleted_at IS NULL
> ORDER BY n.id DESC;
> ```
> Note: Each user has ONE associated person record. The person record links to the names table.

## Tables

### `users`
Staff / provider / system user accounts.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `login` | varchar(255) | Login username |
| `email` | varchar(255) | Email address |
| `title` | varchar(255) | Job title |
| `type` | varchar(255) | **STI DISABLED** — column exists but not used for inheritance |
| `status_id` | int(11) | FK to statuses |
| `location_id` | int(11) | FK to locations |
| `supervised_by` | int(11) | FK self-ref to users (admin supervisor) |
| `clinically_supervised_by` | int(11) | FK self-ref to users (clinical supervisor) |
| `prescribing_doctor_id` | int(11) | FK self-ref to users |
| `defaultapptype_id` | int(11) | FK to appointment_types |
| `supervisor_template_id` | int(11) | FK to supervisor_templates |
| `date_of_hire` | date | Hire date |
| `date_of_termination` | date | Termination date |
| `reason_for_termination` | text | Termination reason |
| `last_login_at` | datetime | Last login timestamp |
| `driver` | tinyint(1) | Is transportation driver |
| `external` | tinyint(1) | External provider |
| `auditor` | tinyint(1) | Is auditor |
| `can_schedule` | tinyint(1) | Can schedule appointments |
| `can_prescribe_epcs` | tinyint(1) | Can prescribe controlled substances |
| `enable_video` | tinyint(1) | Video calls enabled |
| `quickapp` | tinyint(1) | Quick appointment enabled |
| `emrbear` | tinyint(1) | EMR Bear access |
| `notify_of_referrals` | tinyint(1) | Referral notifications |
| `ai_transcription_enabled` | tinyint(1) | AI transcription enabled |
| `ir_role` | varchar(35) | Incident reporting role |
| `ibhrs_number` | varchar(255) | IBHRS number |
| `custom_sig` | varchar(255) | Custom signature |
| `created_by` | int(11) | FK to users |
| `created_at` | datetime | Record creation |
| `updated_by` | int(11) | FK to users |
| `updated_at` | datetime | Last update |
| `deleted_by` | int(11) | FK self-ref |
| `deleted_at` | datetime | Soft delete |

**Key Relationships:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `has_one :person` | people | polymorphic (identifiable) |
| `has_one :provider_number` | provider_numbers | `user_id` |
| `has_many :credentials` | credentials | `user_id` |
| `has_many :certifications` | certifications | `user_id` |
| `has_many :user_roles` | user_roles | `user_id` |
| `has_many :roles` | roles | through user_roles |
| `has_many :appointments` | appointments | `user_id` |
| `has_many :encounters` | encounters | `user_id` |
| `has_many :encounter_forms` | encounter_forms (via user_id) |
| `has_many :supervisions` | supervisions | `user_id` |
| `has_many :assignments` | assignments | `user_id` |
| `has_many :fees` | fees | through fees_users |
| `has_many :eobs` | eobs | `user_id` |
| `has_many :prex_prescriptions` | prex_prescriptions | `user_id` |
| `has_many :otp_orders` | otp_orders | `user_id` |
| `has_and_belongs_to_many :auditables` | auditables_users | join |
| `has_and_belongs_to_many :crew_teams` | crew_teams_users | join |
| `has_and_belongs_to_many :tat_groups` | tat_drivers_tat_groups | join |

**Self-referential (supervisor chain):**
- `belongs_to :supervisor` (FK: supervised_by)
- `belongs_to :clinical_supervisor` (FK: clinically_supervised_by)
- `has_many :admin_supervisees` (inverse: supervised_by)

---

### `roles`
System role definitions.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `name` | varchar(255) | Role name |

### `user_roles`
Join between users and roles.

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | int(11) | FK to users |
| `role_id` | int(11) | FK to roles |

---

### `credentials`
Provider credentials / licenses.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `user_id` | int(11) | FK to users |
| `credential_type_id` | int(11) | FK to credential_types |
| `billing_level_id` | int(11) | FK to billing_levels |

### `credential_types`
Lookup for credential categories.

---

### `certifications`
Professional certifications.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `user_id` | int(11) | FK to users |
| `certification_type_id` | int(11) | FK to certification_types |
| `state_id` | int(11) | FK to us_states |

### `certification_types`
Lookup for certification categories.

---

### `provider_numbers`
NPI and other provider identifiers.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `user_id` | int(11) | FK to users |

---

### `supervisions`
Supervision records.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `user_id` | int(11) | FK to users |

- `has_and_belongs_to_many :payors` (supervisions_payors)
- `has_and_belongs_to_many :users` (supervisions_users)

---

### `activity_reports`
Staff activity/productivity reports.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `user_id` | int(11) | FK to users |
| `supervisor_id` | int(11) | FK to users |

---

## Entity Relationship Summary

```
users
  ├── 1:1 person (people, polymorphic identifiable)
  │     ├── 1:N names
  │     ├── 1:N phones
  │     └── 1:N addresses
  ├── 1:N credentials → credential_types, billing_levels
  ├── 1:N certifications → certification_types
  ├── 1:1 provider_number
  ├── N:N roles (via user_roles)
  ├── 1:N supervisions
  ├── self-ref: supervisor, clinical_supervisor
  ├── 1:N appointments (as provider)
  ├── 1:N encounters (as provider)
  ├── 1:N assignments (staff-to-client)
  └── N:N crew_teams, tat_groups, auditables
```
