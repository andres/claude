# Domain 1: People & Demographics

## Overview
Core identity tables for all people in the system: clients (patients), payors (insurance companies),
contacts, and their demographic attributes.

## Tables

### `people` (STI base)
Primary table for individuals. Uses Single Table Inheritance.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `type` | varchar(255) | STI discriminator: `'Client'` = behavioral health client |
| `sex` | varchar(255) | Biological sex |
| `date_of_birth` | date | DOB |
| `date_of_death` | date | Date of death (if deceased) |
| `state` | varchar(255) | Client state |
| `client_number` | varchar(255) | Unique client identifier number |
| `ssn` | varchar(255) | Social Security Number (sensitive) |
| `encrypted_ssn` | varchar(255) | Encrypted SSN |
| `ssn_na` | tinyint(1) | SSN not available flag |
| `pronoun` | varchar(255) | Preferred pronoun |
| `citizenship` | varchar(255) | Citizenship |
| `nationality` | varchar(255) | Nationality |
| `identifiable_type` | varchar(255) | Polymorphic: `'User'` or `'Tfc::Parent'` |
| `identifiable_id` | int(11) | FK to users or tfc_parents |
| `location_id` | int(11) | FK to locations (primary) |
| `secondary_location_id` | int(11) | FK to locations |
| `tertiary_location_id` | int(11) | FK to locations |
| `hidden` | tinyint(1) | Hidden/merged flag |
| `hidden_at` | datetime | When hidden |
| `hidden_by` | int(11) | FK to users (who hid) |
| `hidden_active_client_id` | int(11) | FK self-ref to people (merged client) |
| `hidden_search` | tinyint(1) | Hidden from search |
| `is_new` | tinyint(1) | New client flag |
| `is_new_to_provider` | tinyint(1) | New to provider flag |
| `returning` | tinyint(1) | Returning client flag |
| `treat_as_adult` | tinyint(1) | Treat minor as adult flag |
| `see_nurse` | tinyint(1) | Needs nurse flag |
| `has_paper_chart` | tinyint(1) | Has physical chart |
| `paper_chart_location` | varchar(255) | Where paper chart is stored |
| `pcp_auto_fax` | tinyint(1) | Auto-fax to PCP |
| `his_opt_in` | tinyint(1) | Health info sharing opt-in (default: 1) |
| `cause_of_death` | varchar(255) | Cause of death |
| `death_by_suicide` | tinyint(1) | Suicide flag (default: 0) |
| `cib_number` | varchar(255) | CIB number |
| `oasas_account_id` | varchar(255) | OASAS account ID |
| `stripe_customer_id` | varchar(255) | Stripe payment integration |
| `legacy_id` | int(11) | Legacy system ID |
| `string_legacy_id` | varchar(255) | Legacy system string ID |
| `practima_id` | varchar(255) | Practima integration ID |
| `merged_id` | varchar(255) | Merged record reference |
| `created_by` | int(11) | FK to users |
| `created_at` | datetime | Record creation |
| `updated_at` | datetime | Last update |
| `updated_by` | int(11) | FK to users |
| `deleted_at` | datetime | Soft delete |
| `deleted_by` | int(11) | FK to users |
| `permanency_type_id` | int(11) | FK to permanency_types |
| `pcp_id` | int(11) | FK to pcps |
| `pharmacy_id` | int(11) | FK to pharmacies |

**STI Subclass: Client** (`type = 'Client'`)
- Primary entity representing a behavioral health patient/client
- Has 100+ associations to clinical, billing, and program data

**Key Relationships from Client:**

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `has_many :billcases` | billcases | `client_id` |
| `has_many :appointments` | appointments | `client_id` |
| `has_many :insurance_policies` | insurance_policies | `client_id` |
| `has_many :program_enrollments` | program_enrollments | `client_id` |
| `has_many :programs` | programs | through program_enrollments |
| `has_many :payors` | companies | through insurance_policies |
| `has_many :encounters` | encounters | `client_id` |
| `has_many :encounter_forms` | encounter_forms | `client_id` |
| `has_many :diagnoses` | diagnoses | `client_id` |
| `has_many :medications` | medications | `client_id` |
| `has_many :prescriptions` | prescriptions | `client_id` |
| `has_many :consents` | consents | `client_id` |
| `has_many :relationships` | relationships | `client_id` |
| `has_many :families` | families | through relationships |
| `has_many :crew_memberships` | crew_memberships | `client_id` |
| `has_many :tfc_assignments` | tfc_assignments | `client_id` |
| `has_many :otp_verifications` | otp_verifications | `client_id` |
| `has_many :otp_dispensings` | otp_dispensings | `client_id` |
| `has_many :placements` | placements | `client_id` |
| `has_one :enrollment` | enrollments | `client_id` |
| `has_one :treatment_plan` | treatment_plans | `client_id` |

---

### `companies` (STI base)
Companies/organizations. Uses Single Table Inheritance.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `name` | varchar(255) | Company name |
| `contact_name` | varchar(255) | Contact person |
| `type` | varchar(255) | STI: `'Payor'` = insurance payer |
| `active` | tinyint(1) | Active flag (default: 1) |
| `claim_type` | varchar(255) | Claim type code (e.g., '09' = self-pay) |
| `payor_type` | varchar(12) | Payor classification |
| `line_of_business` | varchar(255) | Line of business |
| `payers_id` | varchar(255) | External payer ID |
| `agency_number` | varchar(255) | Agency number |
| `taxonomy_code` | varchar(255) | Taxonomy code |
| `provider_number` | varchar(255) | Provider number |
| `is_healthxnet` | tinyint(1) | HealthXNet integration flag |
| `taxable` | tinyint(1) | Taxable flag |
| `out_of_network` | tinyint(1) | Out of network flag |
| `handles_cob` | tinyint(1) | Coordination of benefits |
| `requires_admission_date` | tinyint(1) | Requires admission date |
| `tax_id_required` | tinyint(1) | Tax ID required |
| `batch_group_id` | int(11) | FK to batch_groups |
| `clearing_house_id` | int(11) | FK to clearing_houses |
| `created_by` | int(11) | FK to users |
| `created_at` | datetime | Record creation |
| `updated_by` | int(11) | FK to users |
| `updated_at` | datetime | Last update |
| `deleted_by` | int(11) | FK to users |
| `deleted_at` | datetime | Soft delete |

**STI Subclass: Payor** (`type = 'Payor'`)
- Insurance payer / funding source

| Association | Target Table | FK / Join |
|-------------|-------------|-----------|
| `has_many :insurance_policies` | insurance_policies | `payor_id` |
| `has_many :claims` | claims | `payor_id` |
| `has_many :payments` | payments | `payor_id` |
| `has_many :adjustments` | adjustments | `payor_id` |
| `has_many :deductibles` | deductibles | `payor_id` |
| `has_many :copayments` | copayments | `payor_id` |
| `has_many :writeoffs` | writeoffs | `payor_id` |
| `has_many :denials` | denials | `payor_id` |
| `has_many :reductions` | reductions | `payor_id` |
| `has_many :client_responsibilities` | client_responsibilities | `payor_id` |
| `has_many :insbillers` | insbillers | `payor_id` |
| `has_and_belongs_to_many :plans` | payors_plans | join table |
| `has_and_belongs_to_many :supervisions` | supervisions_payors | join table |
| `belongs_to :batch_group` | batch_groups | `batch_group_id` |
| `belongs_to :clearing_house` | clearing_houses | `clearing_house_id` |

**Scopes for Payor:**
- `active` — `companies.active IS TRUE`
- `self_pay` — `name = 'self' OR name = 'self pay' OR claim_type = '09'`
- `currents` — `deleted_at IS NULL`

---

### `names`
Person name records (supports name history).

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `first` | varchar(255) | First name |
| `middle` | varchar(255) | Middle name |
| `last` | varchar(255) | Last name |
| `last_prefix` | varchar(255) | Last name prefix (e.g., "de", "van") |
| `last_suffix` | varchar(255) | Last name suffix (e.g., "Jr", "III") |
| `alias` | varchar(255) | Alias/nickname |
| `preferred` | varchar(255) | Preferred name |
| `maiden` | varchar(255) | Maiden name |
| `person_id` | int(11) | FK to people |
| `created_at` | datetime | Record creation |
| `created_by` | int(11) | FK to users |
| `updated_at` | datetime | Last update |
| `deleted_at` | datetime | Soft delete |
| `deleted_by` | int(11) | FK to users |

> **GOTCHA:** Multiple name records per person (name history). To get current name, use the record with the highest `id`: `JOIN names n ON n.person_id = p.id AND n.deleted_at IS NULL ORDER BY n.id DESC LIMIT 1` or subquery with `MAX(n.id)`

---

### `addresses`
Polymorphic address records.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `street_1` | varchar(255) | Street line 1 |
| `street_2` | varchar(255) | Street line 2 |
| `city` | varchar(255) | City |
| `zip` | varchar(255) | ZIP code |
| `county` | varchar(255) | County |
| `country` | varchar(255) | Country |
| `province` | varchar(255) | Province |
| `state_id` | int(11) | FK to us_states |
| `latitude` | varchar(255) | Latitude |
| `longitude` | varchar(255) | Longitude |
| `addressable_type` | varchar(255) | Polymorphic: 'Person', 'Location', 'Tfc::Home' |
| `addressable_id` | int(11) | FK to parent |
| `address_type` | varchar(255) | 'Home', 'Postal', 'Physical visit', 'Primary home', 'Temporary', 'Vacation home' |
| `label` | varchar(255) | Address label |
| `note` | varchar(255) | Note |
| `hipaa_permission` | tinyint(1) | HIPAA consent flag |
| `created_at` | datetime | Record creation |
| `deleted_at` | datetime | Soft delete |

---

### `phones`
Polymorphic phone records.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `number` | varchar(255) | Phone number |
| `extension` | varchar(255) | Extension |
| `phonable_type` | varchar(255) | Polymorphic: 'Person', 'Company' |
| `phonable_id` | int(11) | FK to parent |
| `home` | tinyint(1) | Home phone flag |
| `mobile` | tinyint(1) | Mobile flag |
| `work` | tinyint(1) | Work flag |
| `home_fax` | tinyint(1) | Home fax flag |
| `work_fax` | tinyint(1) | Work fax flag |
| `reminder` | tinyint(1) | Use for reminders |
| `call_preference` | varchar(255) | Call preference |
| `note` | varchar(255) | Note |
| `relationship_id` | int(11) | FK to relationships |
| `hipaa_permission` | tinyint(1) | HIPAA consent |
| `created_by` | int(11) | FK to users |
| `created_at` | datetime | Record creation |
| `deleted_by` | int(11) | FK to users |
| `deleted_at` | datetime | Soft delete |

---

### `emails`
Polymorphic email records.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `email` | varchar(255) | Email address |
| `email_type` | varchar(255) | Email type |
| `emailable_type` | varchar(255) | Polymorphic type |
| `emailable_id` | int(11) | FK to parent |
| `hipaa_permission` | tinyint(1) | HIPAA consent (default: 1) |
| `hipaa_ok` | tinyint(1) | HIPAA OK flag (default: 1) |
| `created_by` | int(11) | FK to users |
| `created_at` | datetime | Record creation |
| `deleted_by` | int(11) | FK to users |
| `deleted_at` | datetime | Soft delete |
| `updated_by` | int(11) | FK to users |

---

### `genders` (STI)
| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `person_id` | int(11) | FK to people |
| `gender_type_id` | int(11) | FK to gender_types |
| `type` | varchar(255) | STI discriminator |

### `gender_types`
Lookup table for gender options.

### `civil_statuses`
| Column | Type | Notes |
|--------|------|-------|
| `person_id` | int(11) | FK to people |
| `civil_status_type_id` | int(11) | FK to civil_status_types |

### `civil_status_types`
Lookup table for marital/civil status.

---

### `relationships`
Links clients to family members / responsible parties.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| `client_id` | int(11) | FK to people (Client) |
| `person_id` | int(11) | FK to people |
| `family_id` | int(11) | FK to families |
| `created_by` | int(11) | FK to users |
| `emrbear_client_id` | int(11) | FK to people (if family member is also a client) |
| `us_state_id` | int(11) | FK to us_states |

### `families`
Family grouping table.

| Column | Type | Notes |
|--------|------|-------|
| `id` | int(11) | PK |
| Relationships via `relationships` table |

---

### `taggables` / `tags`
Tagging system for people.

| Column | Type | Notes |
|--------|------|-------|
| `person_id` | int(11) | FK to people |
| `tag_id` | int(11) | FK to tags |

---

## Enum Values

- **`people.sex`**: `'male'`, `'female'`, `'unknown'`
- **`people.type`**: `'Client'`
- **`companies.type`**: `'Payor'`
- **`addresses.addressable_type`**: `'Person'`, `'Location'`, `'Tfc::Home'`
- **`addresses.address_type`**: `'Home'`, `'Postal'`, `'Physical visit'`, `'Primary home'`, `'Temporary'`, `'Vacation home'`

---

## Entity Relationship Summary

```
people (Client)
  ├── 1:N addresses (polymorphic)
  ├── 1:N phones (polymorphic)
  ├── 1:N emails (polymorphic)
  ├── 1:N names (last name is the current name)
  ├── 1:N genders → gender_types (last one is the current)
  ├── 1:N civil_statuses → civil_status_types (last one is the current one)
  ├── 1:N relationships → families
  │                      → people (family member)
  ├── 1:N taggables → tags
  └── 1:1 person ← users (identifiable polymorphic)

companies (Payor)
  ├── 1:N addresses (polymorphic)
  ├── 1:N phones (polymorphic)
  ├── 1:N emails (polymorphic)
  ├── N:N plans (via payors_plans)
  └── N:1 clearing_houses
```
