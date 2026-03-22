# Domain 12: Group Sessions (Crew)

## Overview
Group therapy session management. Teams define group configurations,
memberships track enrolled clients, sessions represent actual group meetings,
and attendances track who showed up.

**Table prefix:** `crew_`

## Tables

### `crew_teams`
Group therapy team / configuration.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `form_id` | integer | FK to forms |
| `program_id` | integer | FK to programs |
| `user_id` | integer | FK to users (group leader) |
| `auto_program_id` | integer | FK to programs |
| `auto_location_id` | integer | FK to locations |

**Key Relationships:**
- `has_many :crew_memberships`
- `has_many :crew_sessions`
- `has_many :appointments`
- `has_many :chronicles`
- `has_and_belongs_to_many :users` (crew_teams_users — co-leaders)

---

### `crew_memberships`
Client enrollment in a group.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `crew_team_id` | integer | FK to crew_teams |
| `client_id` | integer | FK to people (Client) |
| `payor_id` | integer | FK to companies (Payor) |

- `has_many :crew_attendances`
- `has_many :crew_reminders`

---

### `crew_sessions`
Actual group session occurrence.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `crew_team_id` | integer | FK to crew_teams |
| `appointment_id` | integer | FK to appointments |
| `form_id` | integer | FK to forms |
| `user_id` | integer | FK to users |

- `has_many :crew_attendances`
- `has_many :crew_comments`
- `has_many :encounter_forms`
- `has_many :chronicles`

---

### `crew_attendances`
Individual attendance record within a session.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `crew_membership_id` | integer | FK to crew_memberships |
| `crew_session_id` | integer | FK to crew_sessions |
| `checked_in_by` | integer | FK to users |
| `checked_out_by` | integer | FK to users |
| `no_show_by` | integer | FK to users |
| `canceled_by` | integer | FK to users |
| `no_show_insurance_policy_id` | integer | FK to insurance_policies |

- `has_many :crew_notes`
- Delegates `:client` from crew_membership

---

### Other Crew Tables

| Table | Description |
|-------|-------------|
| `crew_comments` | Session comments |
| `crew_notes` | Per-attendance clinical notes |
| `crew_reminders` | Appointment reminders for members |
| `crew_teams_users` | HABTM join: teams ↔ users (co-leaders) |

---

## Entity Relationship Summary

```
crew_teams
  ├── N:1 program, form, user (leader)
  ├── N:N users (co-leaders, via crew_teams_users)
  ├── 1:N crew_memberships
  │     ├── N:1 client (people)
  │     ├── N:1 payor
  │     └── 1:N crew_attendances
  │           ├── N:1 crew_session
  │           └── 1:N crew_notes
  └── 1:N crew_sessions
        ├── N:1 appointment
        ├── 1:N crew_attendances
        ├── 1:N encounter_forms (per-client documentation)
        └── 1:N crew_comments
```
