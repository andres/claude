# Domain 6: Billing & Revenue Cycle

## Overview
The billing pipeline: procedures (from encounters) generate charges on billcases.
Billcases are submitted as claims to payors. Responses (EOBs) create payments,
adjustments, denials, etc. against charges.

> **Money Column Convention:** ALL financial amounts are stored as integers in
> `*_cents` columns. Divide by 100.0 for dollar amounts:
> `amount_cents / 100.0 AS amount_dollars`. Never treat these as already-decimal values.

## Core Flow
```
Encounter → Superbill → Procedures → Charges → Billcase → Claim → ClaimBatch
                                                                      ↓
                                             EOB ← ClearingHouseResponse
                                              ↓
                              Payments, Adjustments, Denials, etc. → Charges
```

## Tables

### `billcases`
A billing case / invoice for a client visit. Central billing entity.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |
| `location_id` | int(11) | FK to locations |
| `program_id` | int(11) | FK to programs |
| `user_id` | int(11) | FK to users (creator) |
| `first_insurance_policy_id` | int(11) | FK to insurance_policies |
| `second_insurance_policy_id` | int(11) | FK to insurance_policies |
| `third_insurance_policy_id` | int(11) | FK to insurance_policies |
| `send_to_insurance_policy_id` | int(11) | FK to insurance_policies |
| `last_billed_insurance_policy_id` | int(11) | FK to insurance_policies |
| `billing_provider_id` | int(11) | FK to users |
| `performing_provider_id` | int(11) | FK to users |
| `referring_provider_id` | int(11) | FK to users |
| `deleted_by` | int(11) | FK to users |
| `claiming_user_id` | int(11) | FK to users |
| `rollup_billcase_id` | int(11) | FK self-ref (rollup parent) |
| `ccbhc_rollup_billcase_id` | int(11) | FK self-ref (CCBHC rollup) |
| `encounter_form_id` | int(11) | FK to encounter_forms |
| `appointment_id` | int(11) | FK to appointments |
| `bundled_registry_id` | int(11) | FK to bundled_registries |
| `first_payor_id` | int(11) | FK to companies (Payor) |
| `second_payor_id` | int(11) | FK to companies (Payor) |
| `third_payor_id` | int(11) | FK to companies (Payor) |
| `send_to_payor_id` | int(11) | FK to companies (Payor) |
| `xtreferral_id` | int(11) | FK to xtreferrals |
| `tfc_billing_registry_id` | int(11) | FK to tfc_billing_registries |
| `adoptive_family_id` | int(11) | FK to adoptive_families |
| `amount_cents` | int(11) | Total billed amount (divide by 100 for dollars) |
| `paid_cents` | int(11) | Total paid (divide by 100) |
| `balance_cents` | int(11) | Outstanding balance (divide by 100) |
| `deducted_cents` | int(11) | Deductible applied (divide by 100) |
| `adjusted_cents` | int(11) | Adjustments (divide by 100) |
| `copaid_cents` | int(11) | Copayments (divide by 100) |
| `writeoff_cents` | int(11) | Write-offs (divide by 100) |
| `client_paid_cents` | int(11) | Client payments (divide by 100) |
| `denied_cents` | int(11) | Denied amount (divide by 100) |
| `reducted_cents` | int(11) | Reductions (divide by 100) |
| `client_responsible_cents` | int(11) | Client responsibility (divide by 100) |
| `insurance_due_cents` | int(11) | Insurance due (divide by 100) |
| `client_due_cents` | int(11) | Client due (divide by 100) |
| `allowed_cents` | int(11) | Allowed amount (divide by 100) |
| `contracted_amount_cents` | int(11) | Contracted amount (divide by 100) |
| `contracted_balance_cents` | int(11) | Contracted balance (divide by 100) |
| `refunded_cents` | int(11) | Refunded (divide by 100) |
| `tax_cents` | int(11) | Tax (divide by 100) |
| `state` | varchar(255) | Enum: `'processed'`, `'unprocessed'`, `'not_valid'`, `'generation_error'` |
| `substate` | varchar(255) | Default: `'first'` |
| `date_of_service` | datetime | Date of service |
| `last_claim_status` | varchar(255) | Last claim status |
| `process_method` | varchar(255) | Processing method |
| `non_billable` | tinyint(1) | Non-billable flag |
| `billing_submitted` | tinyint(1) | Billing submitted flag |
| `manual_edit` | tinyint(1) | Manually edited |
| `create_claim` | tinyint(1) | Create claim flag |
| `first_claim` | datetime | First claim date |
| `first_pay_date` | date | First payment date |
| `admission_date` | datetime | Admission date |
| `claims_count` | int(11) | Counter cache |
| `charges_count` | int(11) | Counter cache |
| `eob_counter` | int(11) | EOB counter |
| `bill_type_code` | varchar(3) | Bill type code |
| `submission_mode` | varchar(10) | Submission mode |
| `claim_note_qualifier` | varchar(255) | Claim note qualifier |
| `claim_note` | varchar(255) | Claim note text |

**Enum values:**
- `state`: `'processed'`, `'unprocessed'`, `'not_valid'`, `'generation_error'`

**Key Relationships:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `has_many :charges` | charges | `billcase_id` |
| `has_many :claims` | claims | `billcase_id` |
| `has_many :applied_taxes` | applied_taxes | `billcase_id` |
| `has_many :payments` | payments | through charges |
| `has_many :adjustments` | adjustments | through charges |
| `has_many :deductibles` | deductibles | through charges |
| `has_many :copayments` | copayments | through charges |
| `has_many :writeoffs` | writeoffs | through charges |
| `has_many :denials` | denials | through charges |
| `has_many :reductions` | reductions | through charges |
| `has_many :client_responsibilities` | client_responsibilities | through charges |
| `has_many :client_payments` | client_payments | through charges |
| `has_many :alloweds` | alloweds | through charges |
| `has_many :refund_payments` | refund_payments | `billcase_id` |
| `has_many :x12_transactions` | x12_transactions | `billcase_id` |
| `has_many :lilnotes` | lilnotes | polymorphic |
| `has_and_belongs_to_many :claim_batches` | claim_batches_billcases | join |
| `has_and_belongs_to_many :eobs` | billcases_eobs | join |
| `has_and_belongs_to_many :clearing_house_responses` | billcases_clearing_house_responses | join |
| `has_and_belongs_to_many :client_statements` | billcases_client_statements | join |

---

### `charges`
Individual charge line items on a billcase.

> **GOTCHA:** `charges.procedure_code` is denormalized from `fees` -- you can query it
> directly without joining to `fees`. But for the service **description**, join to `fees`.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `billcase_id` | int(11) | FK to billcases (counter_cache: charges_count) |
| `diagnosis_id` | int(11) | FK to diagnoses |
| `authorization_id` | int(11) | FK to authorizations |
| `fee_id` | int(11) | FK to fees |
| `place_of_service_id` | int(11) | FK to place_of_services |
| `performing_provider_id` | int(11) | FK to users |
| `billing_provider_id` | int(11) | FK to users |
| `tat_tracker_id` | int(11) | FK to tat_trackers |
| `location_id` | int(11) | FK to locations |
| `encounter_form_id` | int(11) | FK to encounter_forms |
| `rollup_charge_id` | int(11) | FK self-ref |
| `ccbhc_rollup_charge_id` | int(11) | FK self-ref |
| `procedure_code` | varchar(255) | CPT/HCPCS code (denormalized from fees) |
| `modifier_1` | varchar(6) | Procedure modifier 1 |
| `modifier_2` | varchar(6) | Procedure modifier 2 |
| `modifier_3` | varchar(6) | Procedure modifier 3 |
| `modifier_4` | varchar(6) | Procedure modifier 4 |
| `date_from` | date | Service date start |
| `date_to` | date | Service date end |
| `units` | decimal(10,2) | Units billed |
| `amount_cents` | int(11) | Charge amount (divide by 100) |
| `paid_cents` | int(11) | Paid (divide by 100) |
| `balance_cents` | int(11) | Balance (divide by 100) |
| `rate_cents` | int(11) | Rate (divide by 100) |
| `deducted_cents` | int(11) | Deductible (divide by 100) |
| `adjusted_cents` | int(11) | Adjustments (divide by 100) |
| `copaid_cents` | int(11) | Copayments (divide by 100) |
| `writeoff_cents` | int(11) | Write-offs (divide by 100) |
| `client_paid_cents` | int(11) | Client payments (divide by 100) |
| `denied_cents` | int(11) | Denied (divide by 100) |
| `reducted_cents` | int(11) | Reductions (divide by 100) |
| `client_responsible_cents` | int(11) | Client responsibility (divide by 100) |
| `insurance_due_cents` | int(11) | Insurance due (divide by 100) |
| `client_due_cents` | int(11) | Client due (divide by 100) |
| `allowed_cents` | int(11) | Allowed amount (divide by 100) |
| `contracted_amount_cents` | int(11) | Contracted amount (divide by 100) |
| `contracted_balance_cents` | int(11) | Contracted balance (divide by 100) |
| `refunded_cents` | int(11) | Refunded (divide by 100) |
| `tax_cents` | int(11) | Tax (divide by 100) |
| `edited_rate_cents` | int(11) | Edited rate (divide by 100) |
| `active` | tinyint(1) | Active flag |
| `rollup` | tinyint(1) | Rolled up flag |
| `ccbhc_rollup` | tinyint(1) | CCBHC rolled up |
| `institutional` | tinyint(1) | Institutional billing |
| `manual_create` | tinyint(1) | Manually created |
| `revenue_code` | varchar(48) | Revenue code |
| `diagnosis_code` | varchar(255) | Diagnosis code (denormalized) |
| `note` | text | Note |
| `process_result` | varchar(255) | Process result |

**Key Relationships:**
- `has_many` for each transaction type: payments, deductibles, adjustments, copayments, writeoffs, client_payments, denials, reductions, client_responsibilities, alloweds, refund_payments
- `has_and_belongs_to_many :procedures` (charges_procedures)
- `has_many :claim_services`
- `has_many :x12_transactions`

---

### `claims`
Submitted claim to a payor.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `billcase_id` | int(11) | FK to billcases (counter_cache: claims_count) |
| `insurance_policy_id` | int(11) | FK to insurance_policies |
| `payor_id` | int(11) | FK to companies (Payor) |
| `plan_id` | int(11) | FK to plans |
| `client_id` | int(11) | FK to people (Client) |
| `clearing_house_id` | int(11) | FK to clearing_houses |
| `user_id` | int(11) | FK to users |
| `claim_batch_id` | int(11) | FK to claim_batches (counter_cache: claims_count) |
| `claim_batch_status_id` | int(11) | FK to claim_batch_statuses |
| `location_id` | int(11) | FK to locations |

**Key Relationships:**
- `has_many :claim_services` → `has_many :charges` (through claim_services)
- `has_many :payments`
- `has_many :payor_claim_responses`

---

### `claim_services`
Line items on a claim, linking to charges.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `claim_id` | int(11) | FK to claims |
| `charge_id` | int(11) | FK to charges |
| `performing_provider_id` | int(11) | FK to users |
| `billing_provider_id` | int(11) | FK to users |
| `location_id` | int(11) | FK to locations |
| `place_of_service` | int(11) | FK to place_of_services |

- `has_many :service_adjudications` (claim_adjudications)

---

### `claim_adjudications`
EOB adjudication line items.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `claim_service_id` | int(11) | FK to claim_services |
| `adjustable_type` | varchar(255) | Polymorphic: Payment, Adjustment, Denial, etc. |
| `adjustable_id` | int(11) | FK to polymorphic target |

---

### `claim_batches`
Batch of claims for submission.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `user_id` | int(11) | FK to users |
| `clearing_house_id` | int(11) | FK to clearing_houses |
| `batch_group_id` | int(11) | FK to batch_groups |
| `claims_count` | int(11) | Counter cache |

- `has_and_belongs_to_many :billcases` (claim_batches_billcases)
- `has_and_belongs_to_many :payors` (claim_batches_payors)
- `has_many :claims`
- `has_many :claim_batch_statuses`

---

### `eobs` (Explanation of Benefits)
Payment response from payor.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `payor_id` | int(11) | FK to companies (Payor) |
| `user_id` | int(11) | FK to users |
| `eight35_upload_id` | int(11) | FK to eight35_uploads (835 file) |
| `original_eob_id` | int(11) | FK self-ref (duplicate detection) |

**Key Relationships:**
- `has_many` for all transaction types: payments, deductibles, adjustments, copayments, writeoffs, denials, reductions, client_responsibilities, alloweds
- `has_many :x12_transactions`, `x12_provider_adjustments`
- `has_and_belongs_to_many :clearing_house_responses`, `:billcases`

---

### Transaction Types (all share same pattern)

Each of these tables records a specific type of financial transaction against a charge:

| Table | Description |
|-------|-------------|
| `payments` | Insurance payments received |
| `deductibles` | Deductible amounts applied |
| `adjustments` | Contractual/other adjustments |
| `copayments` | Copayment amounts |
| `writeoffs` | Written-off amounts |
| `denials` | Denied amounts |
| `reductions` | Reduced amounts |
| `client_responsibilities` | Patient responsibility amounts |
| `alloweds` | Allowed amounts |
| `refund_payments` | Refund/takeback amounts |
| `client_payments` | Direct client payments |

**Common columns for all transaction types:**

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `charge_id` | int(11) | FK to charges |
| `eob_id` | int(11) | FK to eobs |
| `payor_id` | int(11) | FK to companies (Payor) |
| `insurance_policy_id` | int(11) | FK to insurance_policies |
| `claim_id` | int(11) | FK to claims |
| `created_by` | int(11) | FK to users |

Most also have: `has_one :x12_*` (polymorphic transactable)

---

### `x12_transactions` (STI)
EDI X12 transaction records.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `type` | varchar(255) | STI discriminator |
| `transactable_type` | varchar(255) | Polymorphic |
| `transactable_id` | int(11) | Polymorphic FK |

---

### `applied_taxes`
Tax applied to a billcase.

- `belongs_to :billcase`, `:tax`

---

## Entity Relationship Summary

```
billcases
  ├── N:1 client, location, program
  ├── 0:3 insurance_policies (1st/2nd/3rd)
  ├── 1:N charges
  │     ├── N:1 fee, diagnosis, authorization
  │     ├── N:N procedures (charges_procedures)
  │     ├── 1:N payments
  │     ├── 1:N adjustments
  │     ├── 1:N deductibles
  │     ├── 1:N copayments
  │     ├── 1:N writeoffs
  │     ├── 1:N denials
  │     ├── 1:N reductions
  │     ├── 1:N client_responsibilities
  │     ├── 1:N alloweds
  │     ├── 1:N client_payments
  │     └── 1:N claim_services → claims
  ├── 1:N claims
  │     ├── N:1 payor, plan, insurance_policy
  │     ├── 1:N claim_services → claim_adjudications
  │     └── N:1 claim_batch
  ├── N:N claim_batches
  ├── N:N eobs
  └── 1:N applied_taxes

eobs
  ├── N:1 payor
  ├── 1:N payments, adjustments, denials, etc.
  └── N:N clearing_house_responses → billcases
```
