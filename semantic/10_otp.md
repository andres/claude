# Domain 10: Opioid Treatment Program (OTP)

## Overview
Manages opioid treatment: medication orders, dispensing (methadone/buprenorphine),
bottle/pump inventory, verifications, and dosing schedules.

**Table prefix:** `otp_`

## Tables

### `otp_orders`
Medication orders for OTP clients.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `client_id` | integer | FK to people (Client) |
| `user_id` | integer | FK to users (ordering provider) |
| `program_enrollment_id` | integer | FK to program_enrollments |
| `program_id` | integer | FK to programs |
| `location_id` | integer | FK to locations |
| `ancillary_id` | integer | FK to users |
| `signed_by_id` | integer | FK to users |
| `deleted_by_id` | integer | FK to users |
| `otp_drug_id` | integer | FK to otp_drugs |
| `insurance_policy_id` | integer | FK to insurance_policies |
| `otp_verification_id` | integer | FK to otp_verifications |

- `has_many :otp_doses`
- `has_many :otp_holds`

---

### `otp_dispensings`
Individual dispensing events.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `client_id` | integer | FK to people (Client) |
| `user_id` | integer | FK to users (dispensing nurse) |
| `location_id` | integer | FK to locations |
| `received_by_id` | integer | FK to users |
| `lost_by_id` | integer | FK to users |
| `otp_dose_id` | integer | FK to otp_doses |
| `otp_order_id` | integer | FK to otp_orders |
| `otp_drug_id` | integer | FK to otp_drugs |
| `otp_pump_id` | integer | FK to otp_pumps |
| `otp_load_id` | integer | FK to otp_loads |
| `otp_bottle_id` | integer | FK to otp_bottles |
| `otp_med_id` | integer | FK to otp_meds |

- `has_many :otp_dispensing_statuses`
- `has_one :otp_printout`

---

### `otp_verifications`
Client identity/eligibility verification.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `user_id` | integer | FK to users |
| `client_id` | integer | FK to people (Client) |

- `has_many :otp_orders`

---

### `otp_bottles`
Medication bottle inventory.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `otp_drug_id` | integer | FK to otp_drugs |
| `location_id` | integer | FK to locations |
| `created_by_id` | integer | FK to users |
| `updated_by_id` | integer | FK to users |
| `discarded_by` | integer | FK to users |

- `has_many :otp_loads`, `:otp_dispensings`, `:otp_reconciliation_details`
- `has_many :otp_bottle_transfers` (in/out)

---

### `otp_pumps`
Dispensing pump devices.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `location_id` | integer | FK to locations |

- `has_many :otp_loads`

---

### `otp_meds`
Medication inventory (non-bottle, e.g., tablets).

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `otp_drug_id` | integer | FK to otp_drugs |
| `location_id` | integer | FK to locations |

- `has_many :otp_dispensings`

---

### Other OTP Tables

| Table | Description |
|-------|-------------|
| `otp_drugs` | Drug definitions (methadone, buprenorphine, etc.) |
| `otp_doses` | Dose definitions within an order |
| `otp_loads` | Pump load events (bottle → pump) |
| `otp_holds` | Dispensing holds |
| `otp_holidays` | Clinic holiday schedules |
| `otp_settings` | OTP configuration |
| `otp_dispensing_statuses` | Dispensing workflow statuses |
| `otp_dispensing_reinventories` | Reinventory events |
| `otp_bottle_transfers` | Bottle transfer between locations |
| `otp_pump_statuses` | Pump status tracking |
| `otp_reconciliation_reports` | Inventory reconciliation |
| `otp_reconciliation_details` | Reconciliation line items |
| `otp_reconciliation_dispensings` | Dispensing reconciliation |
| `otp_resolutions` | Discrepancy resolutions |
| `otp_prefill_auths` | Pre-fill authorizations |
| `otp_prime_events` | Pump prime events |
| `otp_printouts` | Dispensing printouts |
| `otp_order_imports` | Order import records |
| `otp_verification_imports` | Verification import records |
| `otp_ancillaries` | Ancillary staff records |
| `otp_attendings` | Attending physician records |
| `otp_billers` | OTP billing records |
| `otp_biller_trackers` | Billing tracking |
| `otp_billing_activities` | Billing activity log |
| `otp_documentations` | Documentation records |

---

## Entity Relationship Summary

```
otp_orders
  ├── N:1 client (people)
  ├── N:1 user (provider)
  ├── N:1 otp_drug
  ├── N:1 otp_verification
  ├── N:1 insurance_policy
  ├── 1:N otp_doses
  │     └── 1:N otp_dispensings
  │           ├── N:1 otp_pump
  │           ├── N:1 otp_bottle
  │           ├── N:1 otp_med
  │           ├── N:1 otp_load
  │           └── 1:N otp_dispensing_statuses
  └── 1:N otp_holds

otp_bottles / otp_meds
  ├── N:1 otp_drug
  ├── N:1 location
  └── inventory chain: loads → pumps → dispensings
```
