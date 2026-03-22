# Bear DB Natural Language Query Guide

Reference for translating natural language questions into SQL against the Bear MariaDB database.
**DB Engine:** MariaDB 10.2.29 (use MySQL syntax, NOT PostgreSQL).

## How to Get Names

Names are stored in a separate `names` table, NOT on `people` or `users`.

### Names Table Columns
`first`, `middle`, `last`, `last_prefix`, `last_suffix`, `alias`, `preferred`, `maiden`, `person_id`

### Multiple Name Records
A person can have multiple name records (name history). Always get the **latest** name using `MAX(id)` or `ORDER BY id DESC LIMIT 1`.

### Client Names
Clients are `people` records with `type = 'Client'`. Join directly via `person_id`:

```sql
SELECT n.first, n.last
FROM names n
WHERE n.person_id = <people.id>
  AND n.deleted_at IS NULL
ORDER BY n.id DESC LIMIT 1;
```

Full example — list active clients with names:
```sql
SELECT p.id, n.first, n.last
FROM people p
JOIN names n ON n.person_id = p.id AND n.deleted_at IS NULL
WHERE p.type = 'Client' AND p.deleted_at IS NULL AND (p.hidden IS NULL OR p.hidden = 0)
  AND n.id = (SELECT MAX(n2.id) FROM names n2 WHERE n2.person_id = p.id AND n2.deleted_at IS NULL);
```

### Staff / Provider Names
Users do NOT have names directly. You must join through `people` using the polymorphic relationship:

```sql
SELECT u.id AS user_id, n.first, n.last
FROM users u
JOIN people p ON p.identifiable_id = u.id AND p.identifiable_type = 'User'
JOIN names n ON n.person_id = p.id AND n.deleted_at IS NULL
WHERE u.deleted_at IS NULL
  AND n.id = (SELECT MAX(n2.id) FROM names n2 WHERE n2.person_id = p.id AND n2.deleted_at IS NULL);
```

## How to Link Appointment to Billing

The chain from appointment to billing:

```
appointment → encounter (appointment_id)
            → encounter_forms (encounter_id)
            → superbill (encounter_form_id)
            → billcase (encounter_form_id)
```

**Shortcut:** `billcases.appointment_id` directly links to `appointments.id` — use this for simpler queries.

```sql
-- Billcases for a specific appointment
SELECT b.*
FROM billcases b
WHERE b.appointment_id = <appointment_id> AND b.deleted_at IS NULL;

-- Full chain (when you need encounter/form details too)
SELECT a.id AS appt_id, e.id AS encounter_id, ef.id AS form_id, bc.id AS billcase_id, bc.state
FROM appointments a
JOIN encounters e ON e.appointment_id = a.id
JOIN encounter_forms ef ON ef.encounter_id = e.id
JOIN billcases bc ON bc.encounter_form_id = ef.id
WHERE a.deleted_at IS NULL AND bc.deleted_at IS NULL;
```

## How to Get Service Code for a Billcase

Service/procedure codes live on the `charges` table (denormalized) or can be looked up via `fees`.

```sql
-- Option 1: Direct from charges (denormalized procedure_code column)
SELECT c.procedure_code, c.amount_cents
FROM charges c
WHERE c.billcase_id = <billcase_id> AND c.deleted_at IS NULL;

-- Option 2: Through fees table
SELECT f.procedure_code, c.amount_cents
FROM charges c
JOIN fees f ON c.fee_id = f.id
WHERE c.billcase_id = <billcase_id> AND c.deleted_at IS NULL;
```

## Enum Values for Critical Columns

| Table.Column | Values | Notes |
|---|---|---|
| `people.sex` | `'male'`, `'female'`, `'unknown'` | **lowercase** |
| `people.type` | `'Client'` | **PascalCase** |
| `companies.type` | `'Payor'` | **PascalCase** |
| `billcases.state` | `'processed'`, `'unprocessed'`, `'not_valid'`, `'generation_error'` | lowercase |
| `encounter_forms.state` | `'started'`, `'completed'`, `'signed'` | lowercase |
| `addresses.address_type` | `'Home'`, `'Postal'`, `'Physical visit'`, `'Primary home'`, `'Temporary'`, `'Vacation home'` | mixed case |
| `addresses.addressable_type` | `'Person'`, `'Location'`, `'Tfc::Home'` | PascalCase |
| `program_enrollments.referral_status` | `'Wait List'`, `'Active'`, `'closed'`, `'waitlist'`, `'approved'`, `'Suspended for LOC'`, `'pending'`, `'Priority'`, `'Enrolled'` | **inconsistent casing in data** |

## Status Pattern Reference

Most Bear entities do NOT have a `status` column. Instead, they use timestamp-based or state-machine patterns:

### Appointments (timestamp-based)
Appointment status is derived from which `*_at` timestamp is set:

| Derived Status | Condition |
|---------------|-----------|
| Scheduled (pending) | `created_at IS NOT NULL AND confirmed_at IS NULL AND cancelled_at IS NULL AND noshow_at IS NULL AND deleted_at IS NULL` |
| Confirmed | `confirmed_at IS NOT NULL AND cancelled_at IS NULL AND noshow_at IS NULL AND deleted_at IS NULL` |
| Checked In | `checked_in_at IS NOT NULL AND checked_out_at IS NULL` |
| Checked Out / Completed | `checked_out_at IS NOT NULL` |
| Cancelled | `cancelled_at IS NOT NULL AND deleted_at IS NULL` |
| No-Show | `noshow_at IS NOT NULL AND deleted_at IS NULL` |
| Deleted | `deleted_at IS NOT NULL` |

**"Valid" appointments** (composite index `valid_apps`): `deleted_by IS NULL AND cancelled_at IS NULL AND noshow_at IS NULL`

### Program Enrollments (timestamp-based)
| Derived Status | Condition |
|---------------|-----------|
| Pending | `approved_at IS NULL AND denied_at IS NULL` |
| Active / Current | `approved_at IS NOT NULL AND (expires_at IS NULL OR expires_at > NOW())` |
| Expired | `expires_at IS NOT NULL AND expires_at <= NOW()` |
| Denied | `denied_at IS NOT NULL` |
| Closed | `closed_by IS NOT NULL` |

### Billcases (state column)
Column: `state` (varchar)
| Value | Meaning |
|-------|---------|
| `processed` | Fully processed (3,260) |
| `unprocessed` | Pending processing (699) |
| `not_valid` | Validation failed (63) |
| `generation_error` | Error during generation (17) |

### Encounter Forms (state column)
Column: `state` (varchar)
| Value | Meaning |
|-------|---------|
| `started` | In progress (1,287) |
| `completed` | Finished (5,332) |
| `signed` | Signed off (9) |

### Clients / People (soft-delete + hidden)
| Filter | Condition |
|--------|-----------|
| Active clients | `type = 'Client' AND deleted_at IS NULL AND (hidden IS NULL OR hidden = 0)` |
| All clients (incl. deleted) | `type = 'Client'` |
| Hidden/merged | `hidden = 1` or `hidden_active_client_id IS NOT NULL` |

## Common Query Patterns

### Counting / Demographics
```sql
-- How many clients do I have?
SELECT COUNT(*) FROM people WHERE type = 'Client';

-- How many active (non-deleted, non-hidden) clients?
SELECT COUNT(*) FROM people WHERE type = 'Client' AND deleted_at IS NULL AND (hidden IS NULL OR hidden = 0);

-- Clients by sex
SELECT sex, COUNT(*) FROM people WHERE type = 'Client' GROUP BY sex;

-- Clients by age range
SELECT
  CASE
    WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 18 THEN 'Under 18'
    WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 18 AND 25 THEN '18-25'
    WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 26 AND 40 THEN '26-40'
    WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 41 AND 64 THEN '41-64'
    ELSE '65+'
  END AS age_range,
  COUNT(*) AS count
FROM people WHERE type = 'Client' AND date_of_birth IS NOT NULL
GROUP BY age_range;

-- Clients by location
SELECT l.name, COUNT(*) FROM people p JOIN locations l ON p.location_id = l.id WHERE p.type = 'Client' GROUP BY l.name;
```

### Programs & Enrollment
```sql
-- Clients per program (active enrollments)
SELECT pr.name, COUNT(DISTINCT pe.client_id)
FROM program_enrollments pe
JOIN programs pr ON pe.program_id = pr.id
WHERE pe.approved_at IS NOT NULL AND (pe.expires_at IS NULL OR pe.expires_at > NOW())
GROUP BY pr.name;

-- Active programs
SELECT name FROM programs WHERE active = 1;
```

### Appointments
```sql
-- Appointments today
SELECT COUNT(*) FROM appointments WHERE DATE(date_time_starts) = CURDATE() AND deleted_at IS NULL;

-- Appointments this month
SELECT COUNT(*) FROM appointments WHERE date_time_starts >= DATE_FORMAT(NOW(), '%Y-%m-01') AND deleted_at IS NULL;

-- No-show rate
SELECT
  COUNT(*) AS total,
  SUM(CASE WHEN noshow_at IS NOT NULL THEN 1 ELSE 0 END) AS noshows,
  ROUND(SUM(CASE WHEN noshow_at IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS noshow_pct
FROM appointments WHERE deleted_at IS NULL;

-- Appointments per provider (with provider name)
SELECT u.id, n.first, n.last, COUNT(*) AS appt_count
FROM appointments a
JOIN users u ON a.user_id = u.id
JOIN people p ON p.identifiable_id = u.id AND p.identifiable_type = 'User'
JOIN names n ON n.person_id = p.id AND n.deleted_at IS NULL
  AND n.id = (SELECT MAX(n2.id) FROM names n2 WHERE n2.person_id = p.id AND n2.deleted_at IS NULL)
WHERE a.deleted_at IS NULL
GROUP BY u.id, n.first, n.last ORDER BY appt_count DESC;
```

### Billing
```sql
-- Revenue overview (total billed vs paid)
SELECT
  SUM(amount_cents) / 100.0 AS total_billed,
  SUM(paid_cents) / 100.0 AS total_paid,
  SUM(balance_cents) / 100.0 AS total_balance
FROM billcases WHERE deleted_at IS NULL;

-- Billcases by state
SELECT state, COUNT(*) FROM billcases GROUP BY state;

-- Unpaid billcases
SELECT COUNT(*), SUM(balance_cents) / 100.0 AS outstanding
FROM billcases WHERE balance_cents > 0 AND deleted_at IS NULL;

-- Revenue by procedure code
SELECT c.procedure_code, COUNT(*) AS charge_count, SUM(c.amount_cents) / 100.0 AS total
FROM charges c
JOIN billcases b ON c.billcase_id = b.id
WHERE c.deleted_at IS NULL AND b.deleted_at IS NULL
GROUP BY c.procedure_code ORDER BY total DESC;
```

### Encounters & Forms
```sql
-- Encounter forms by state
SELECT state, COUNT(*) FROM encounter_forms GROUP BY state;

-- Encounters per month
SELECT DATE_FORMAT(created_at, '%Y-%m') AS month, COUNT(*)
FROM encounters GROUP BY month ORDER BY month DESC LIMIT 12;
```

### Staff
```sql
-- Active staff count
SELECT COUNT(*) FROM users WHERE deleted_at IS NULL;

-- Staff by role
SELECT r.name, COUNT(*) FROM user_roles ur JOIN roles r ON ur.role_id = r.id GROUP BY r.name;

-- Staff list with names
SELECT u.id, n.first, n.last, u.email
FROM users u
JOIN people p ON p.identifiable_id = u.id AND p.identifiable_type = 'User'
JOIN names n ON n.person_id = p.id AND n.deleted_at IS NULL
  AND n.id = (SELECT MAX(n2.id) FROM names n2 WHERE n2.person_id = p.id AND n2.deleted_at IS NULL)
WHERE u.deleted_at IS NULL;
```

### Insurance / Payors
```sql
-- Active payors
SELECT name FROM companies WHERE type = 'Payor' AND active = 1 AND deleted_at IS NULL;

-- Clients per payor
SELECT c.name, COUNT(DISTINCT ip.client_id)
FROM insurance_policies ip
JOIN companies c ON ip.payor_id = c.id
WHERE ip.deleted_at IS NULL
GROUP BY c.name;
```

## Important Caveats

1. **MariaDB syntax** — Use `CASE WHEN` instead of `FILTER(WHERE)`, `CURDATE()` instead of `CURRENT_DATE`, `TIMESTAMPDIFF()` for date math
2. **Soft deletes** — Always filter `deleted_at IS NULL` unless counting historical data
3. **STI tables** — Always filter `type = 'Client'` on `people`, `type = 'Payor'` on `companies`
4. **Hidden clients** — `hidden = 1` means merged or hidden; exclude with `(hidden IS NULL OR hidden = 0)`
5. **Money columns** — All financial amounts stored as `*_cents` (integer) — divide by 100 for dollars
6. **Names are in a separate table** — Client names are in the `names` table, not `people` — join via `person_id`. Always get the latest name record (MAX id).
7. **User names are NOT on the users table** — Must join through `people` (polymorphic: `identifiable_id` + `identifiable_type = 'User'`) then to `names`. See "How to Get Names" section.
8. **Polymorphic joins** — Always include both `*_type` and `*_id` columns in joins
9. **Forms table uses `title` NOT `name`** — The `forms` table column for the form name is `title`, not `name`
10. **`tinyint(1)` is MariaDB boolean** — Use `= 1` for true and `= 0` for false. Do NOT use `IS TRUE` / `IS FALSE` syntax.
11. **Charges have denormalized `procedure_code`** — The `charges` table has a `procedure_code` column directly — you can query it without joining to the `fees` table
12. **Enum casing is inconsistent** — Some enums use lowercase (`'male'`), some PascalCase (`'Client'`, `'Payor'`), some mixed (`program_enrollments.referral_status`). Always match exact casing. See "Enum Values" section.
