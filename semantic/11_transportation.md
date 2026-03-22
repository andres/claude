# Domain 11: Transportation (TAT)

## Overview
Client transportation management: requisitions, trip tracking, driver groups,
agency management, and billing integration.

**Table prefix:** `tat_`

## Tables

### `tat_requisitions`
Transportation request / order.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `client_id` | integer | FK to people (Client) |
| `user_id` | integer | FK to users |
| `case_manager_id` | integer | FK to users |
| `relationship_id` | integer | FK to relationships |
| `insurance_policy_id` | integer | FK to insurance_policies |
| `from_address_id` | integer | FK to addresses |
| `to_address_id` | integer | FK to addresses |
| `tat_agency_id` | integer | FK to tat_agencies |
| `parent_id` | integer | FK self-ref (return trip) |

- `has_many :tat_trackers`
- `has_many :tat_occurrences`
- `has_one :child_requisition` (inverse parent)

---

### `tat_trackers`
Trip tracking / actual transport records.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `client_id` | integer | FK to people (Client) |
| `relationship_id` | integer | FK to relationships |
| `insurance_policy_id` | integer | FK to insurance_policies |
| `tat_agency_id` | integer | FK to tat_agencies |
| `tat_occurrence_id` | integer | FK to tat_occurrences |
| `tat_requisition_id` | integer | FK to tat_requisitions |
| `tat_driving_id` | integer | FK to tat_drivings |
| `from_address_id` | integer | FK to addresses |
| `to_address_id` | integer | FK to addresses |

- `has_many :tat_driving_actions`
- `has_one :tat_vehicle` (through tat_driving)
- Links to billing via `procedures.tat_tracker_id` and `charges.tat_tracker_id`

---

### `tat_groups`
Driver groups.

- `has_and_belongs_to_many :users` (tat_drivers, via tat_drivers_tat_groups)
- `has_many :tat_drivings` (through drivers)

---

### `tat_drivings`
Driver shift / driving session.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `user_id` | integer | FK to users (driver) |

---

### Other TAT Tables

| Table | Description |
|-------|-------------|
| `tat_agencies` | Transportation agencies |
| `tat_occurrences` | Trip occurrence instances |
| `tat_driving_actions` | GPS/action log entries |
| `tat_vehicles` | Vehicle inventory |
| `tat_rules` | Billing/routing rules |
| `tat_rule_zips` | ZIP code routing |
| `tat_breaks` | Driver break records |
| `tat_endshifts` | End of shift records |
| `tat_client_agencies` | Client-agency assignments |
| `tat_user_agencies` | Driver-agency assignments |
| `tat_billers` | Billing integration |
| `tat_billers_fail_encounter_forms` | Failed billing EFs |
| `tat_billers_success_encounter_forms` | Successful billing EFs |

---

## Entity Relationship Summary

```
tat_requisitions
  ├── N:1 client, user, insurance_policy
  ├── N:1 from_address, to_address
  ├── N:1 tat_agency
  ├── 1:1 child_requisition (return trip)
  ├── 1:N tat_occurrences
  └── 1:N tat_trackers
        ├── N:1 tat_driving → user (driver)
        └── → charges (billing via tat_tracker_id)

tat_groups
  └── N:N users (drivers)
        └── 1:N tat_drivings → tat_trackers
```
