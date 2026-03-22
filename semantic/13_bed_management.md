# Domain 13: Bed Management (Spot)

## Overview
Residential bed tracking for inpatient/residential programs.
Locations have areas, areas have rooms, rooms have beds.
Clients are assigned to beds or have reservations.

**Table prefix:** `spot_`

## Tables

### `spot_areas`
Named area/wing within a location.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `location_id` | integer | FK to locations |

- `has_many :spot_rooms`
- `has_many :spot_beds` (through spot_rooms)
- `has_many :spot_assignments` (through spot_beds)
- `has_many :spot_reservations` (through spot_beds)

---

### `spot_rooms`
Room within an area.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `spot_area_id` | integer | FK to spot_areas |
| `location_id` | integer | FK to locations |

- `has_many :spot_beds`

---

### `spot_beds`
Individual bed within a room.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `spot_room_id` | integer | FK to spot_rooms |
| `location_id` | integer | FK to locations |

- `has_many :spot_assignments`
- `has_many :spot_reservations`

---

### `spot_assignments`
Active client-to-bed assignment.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `spot_bed_id` | integer | FK to spot_beds |
| `client_id` | integer | FK to people (Client) |
| `program_enrollment_id` | integer | FK to program_enrollments |

---

### `spot_reservations`
Future bed reservation.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `spot_bed_id` | integer | FK to spot_beds |
| `client_id` | integer | FK to people (Client) |
| `user_id` | integer | FK to users |

---

## Entity Relationship Summary

```
locations
  └── 1:N spot_areas
        └── 1:N spot_rooms
              └── 1:N spot_beds
                    ├── 1:N spot_assignments
                    │     ├── N:1 client (people)
                    │     └── N:1 program_enrollment
                    └── 1:N spot_reservations
                          ├── N:1 client (people)
                          └── N:1 user
```
