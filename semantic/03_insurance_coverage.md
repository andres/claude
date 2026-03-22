# Domain 3: Insurance & Coverage

## Overview
Insurance coverage chain: Payor → Plan → Schedule → Fee.
Clients have InsurancePolicies linking them to Payors/Plans.
Authorizations track pre-authorization for services.

## Tables

### `insurance_policies`
Links a client to a payor and plan.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |
| `payor_id` | int(11) | FK to companies (Payor) |
| `plan_id` | int(11) | FK to plans |
| `relationship_id` | int(11) | FK to relationships (subscriber) |
| `group_number` | varchar(255) | Group number |
| `policy_number` | varchar(255) | Policy number |
| `deductible` | varchar(255) | Deductible amount |
| `copay` | decimal(8,2) | Copay amount |
| `notes` | varchar(255) | Policy notes |
| `valid_since` | date | Coverage start date |
| `expires_on` | datetime | Coverage expiration |
| `priority` | varchar(255) | Priority (primary/secondary/tertiary) |
| `medicaid_number` | varchar(255) | Medicaid number |
| `consumer_id` | varchar(255) | Consumer ID |
| `reference_number` | varchar(255) | Reference number |
| `medicaid_name_first` | varchar(255) | Medicaid first name |
| `medicaid_name_middle` | varchar(255) | Medicaid middle name |
| `medicaid_name_last` | varchar(255) | Medicaid last name |
| `date_of_birth` | date | Subscriber DOB |
| `group_copay` | decimal(8,2) | Group copay amount |
| `created_by` | int(11) | FK to users |
| `created_at` | datetime | Record creation |
| `updated_by` | int(11) | FK to users |
| `updated_at` | datetime | Last update |
| `deleted_by` | int(11) | FK to users |
| `deleted_at` | datetime | Soft delete |

**Key Relationships:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `belongs_to :payor` | companies | `payor_id` |
| `belongs_to :client` | people | `client_id` |
| `belongs_to :plan` | plans | `plan_id` |
| `belongs_to :relationship` | relationships | `relationship_id` |
| `has_many :authorizations` | authorizations | `insurance_policy_id` |
| `has_many :verifications` | verifications | `insurance_policy_id` |
| `has_many :cards` | pictures | polymorphic (picturable) |
| `has_many :tfc_assignment_levels` | tfc_assignment_levels | `insurance_policy_id` |
| `has_many :chc_orders` | chc_orders | `insurance_policy_id` |

---

### `plans`
Insurance plan / benefit configuration.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `name` | varchar(255) | Plan name |
| `schedule_id` | int(11) | FK to schedules |
| `payor_type` | varchar(255) | Payor classification |
| `claim_type` | varchar(255) | Claim type |
| `billing_mode` | varchar(100) | Billing mode (default: 'system_default') |
| `timely_filing_days` | int(11) | Timely filing days (default: 90) |
| `effective_from` | date | Effective start |
| `effective_until` | date | Effective end |
| `billed_amount` | decimal(12,2) | Billed amount |
| `ccbhc` | tinyint(1) | CCBHC plan flag |
| `ccbhc_npi` | varchar(255) | CCBHC NPI |
| `ahcccs` | tinyint(1) | AHCCCS flag |
| `incident_billing` | tinyint(1) | Incident billing flag |
| `address_1` | varchar(255) | Plan address line 1 |
| `address_2` | varchar(255) | Plan address line 2 |
| `city` | varchar(255) | City |
| `state` | varchar(255) | State |
| `zip` | varchar(255) | ZIP code |
| `phone` | varchar(255) | Phone |
| `fax` | varchar(255) | Fax |
| `note` | text | Plan notes |
| `contract_information` | text | Contract information |
| `created_at` | datetime | Record creation |
| `updated_at` | datetime | Last update |
| `deleted_at` | datetime | Soft delete |

**Key Relationships:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `belongs_to :schedule` | schedules | `schedule_id` |
| `has_many :insurance_policies` | insurance_policies | `plan_id` |
| `has_many :claims` | claims | `plan_id` |
| `has_and_belongs_to_many :payors` | payors_plans | join table |
| `has_and_belongs_to_many :billing_policies` | billing_policies_plans | join table |

---

### `schedules`
Fee schedule — defines pricing.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |

**Key Relationships:**
- `has_many :plans`
- `has_many :fees`
- `has_many :charges` (through fees)

---

### `fees`
Fee/rate for a specific service code.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `schedule_id` | int(11) | FK to schedules |
| `billing_level_id` | int(11) | FK to billing_levels |
| `tfc_placement_level_id` | int(11) | FK to tfc_placement_levels |
| `procedure_code` | varchar(5) | CPT/HCPCS code |
| `description` | varchar(255) | Service description |
| `rate_cents` | int(11) | Rate in cents |
| `modifier_1` | varchar(6) | Procedure modifier 1 |
| `modifier_2` | varchar(6) | Procedure modifier 2 |
| `modifier_3` | varchar(6) | Procedure modifier 3 |
| `modifier_4` | varchar(6) | Procedure modifier 4 |
| `units` | int(11) | Default units |
| `unit_type` | varchar(255) | Unit type |
| `billable` | tinyint(1) | Is billable |
| `ccbhc_trigger` | tinyint(1) | CCBHC trigger service |
| `ccbhc_cap` | tinyint(1) | CCBHC per diem cap |
| `ccbhc_non_trigger` | tinyint(1) | CCBHC non-trigger |
| `revenue_code` | varchar(48) | Revenue code |
| `valid_from` | date | Effective start |
| `valid_until` | date | Effective end |
| `billing_category` | varchar(255) | Billing category |
| `authorization_required` | tinyint(1) | Auth required |
| `once_per_day` | tinyint(1) | Once per day limit |
| `max_per_year` | int(11) | Annual limit |
| `max_per_day` | int(11) | Daily limit |
| `minimum_time_to_bill` | int(11) | Min time (minutes) |
| `npi` | varchar(255) | Override NPI |
| `taxonomy` | varchar(255) | Taxonomy |
| `institutional` | tinyint(1) | Institutional billing |
| `created_at` | datetime | Record creation |
| `updated_at` | datetime | Last update |
| `deleted_at` | datetime | Soft delete |

**Key Relationships:**
- `belongs_to :schedule`
- `belongs_to :billing_level`
- `has_many :procedures`
- `has_many :charges`
- `has_many :nlm_value_sets` (SNOMED/CPT codes)
- `has_and_belongs_to_many :users` (fees_users)
- `has_and_belongs_to_many :specific_dxes` (ICD restrictions)

---

### `authorizations`
Pre-authorization for services from a payor.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |
| `user_id` | int(11) | FK to users |
| `insurance_policy_id` | int(11) | FK to insurance_policies |
| `provider_id` | int(11) | FK to users (rendering provider) |

**Key Relationships:**
- `belongs_to :client`, `:user`, `:insurance_policy`, `:provider`
- `has_many :procedures`
- `has_many :lilnotes` (polymorphic)
- `has_one :uploaded_document` (polymorphic)

---

### `verifications`
Insurance eligibility verification records.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `insurance_policy_id` | int(11) | FK to insurance_policies |

---

### `billing_levels`
Credential-based billing tiers.

- `has_many :credentials`
- `has_many :fees`

---

### `billing_policies`
Rules for billing behavior.

- `has_many :policy_sets`
- `has_and_belongs_to_many :plans` (billing_policies_plans)

---

### `billing_configurations`
Singleton organization-wide billing settings.

- `belongs_to :state` (UsState)
- `belongs_to :billing_state` (UsState)
- `belongs_to :sigform`

---

### `clearing_houses`
EDI clearinghouse for claim submission.

- `has_many :payors`

---

### `batch_groups`
Grouping for batch claim submission.

---

## Coverage Chain

```
Payor (companies, type='Payor')
  └── N:N plans (via payors_plans)
        └── N:1 schedule
              └── 1:N fees
                    └── 1:N procedures (on encounter)
                          └── N:N charges (on billcase)

Client (people, type='Client')
  └── 1:N insurance_policies
        ├── N:1 payor
        ├── N:1 plan → schedule → fees
        └── 1:N authorizations
```
