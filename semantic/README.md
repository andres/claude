# Bear Semantic Layer

Semantic layer documentation for the Bear application (Ruby on Rails 5.2).
Designed for use with AWS semantic layer tooling (e.g., Amazon DataZone, Athena, QuickSight).

## Application Overview

Bear is a behavioral health / human services EHR (Electronic Health Record) system.
- **Framework:** Ruby on Rails 5.2, ActiveRecord + Mongoid (MongoDB for clinical documents)
- **Database:** MariaDB 10.2.29 (1,014 tables), MongoDB (med_* collections)
- **DB Engine:** MariaDB (MySQL-compatible syntax — no PostgreSQL-specific features like FILTER, ARRAY_AGG, etc.)
- **Key Patterns:** Single Table Inheritance (STI), polymorphic associations, HABTM join tables
- **Soft Deletes:** Most tables use `deleted_at` (datetime) for soft deletes
- **Status Patterns:** Many entities use timestamp columns instead of status enums (see Query Guide)

## Query Guide

See **[Natural Language Query Guide](00_query_guide.md)** for translating plain English questions into SQL,
including status pattern reference, common query templates, and MariaDB syntax caveats.

## Domain Groups

| # | Domain | File | Core Tables | Description |
|---|--------|------|-------------|-------------|
| 0 | [Query Guide](00_query_guide.md) | `00` | — | NL-to-SQL patterns, status derivation, caveats |
| 1 | [People & Demographics](01_people_demographics.md) | `01` | people, companies, addresses, phones, emails, names | Clients, payors, contacts, demographics |
| 2 | [Programs & Enrollment](02_programs_enrollment.md) | `02` | programs, program_enrollments, locations, sections | Programs, enrollment, sites |
| 3 | [Insurance & Coverage](03_insurance_coverage.md) | `03` | insurance_policies, plans, schedules, authorizations | Payer contracts, auth management |
| 4 | [Appointments & Scheduling](04_appointments_scheduling.md) | `04` | appointments, appointment_types, activities, recursions | Scheduling and calendar |
| 5 | [Encounters & Forms](05_encounters_forms.md) | `05` | encounters, encounter_forms, forms, pages, superbills | Clinical documentation engine |
| 6 | [Billing & Revenue Cycle](06_billing_revenue.md) | `06` | billcases, charges, claims, payments, eobs | Claims, payments, AR |
| 7 | [Clinical Data](07_clinical_data.md) | `07` | diagnoses, icds, medications, prescriptions | Dx, meds, clinical records |
| 8 | [Users & Staff](08_users_staff.md) | `08` | users, roles, credentials, certifications | Staff, providers, credentials |
| 9 | [TFC](09_tfc.md) | `09` | tfc_* | Treatment Foster Care |
| 10 | [OTP](10_otp.md) | `10` | otp_* | Opioid Treatment Program |
| 11 | [Transportation](11_transportation.md) | `11` | tat_* | Client transportation |
| 12 | [Group Sessions](12_crew_groups.md) | `12` | crew_* | Group therapy sessions |
| 13 | [Bed Management](13_bed_management.md) | `13` | spot_* | Residential bed tracking |
| 14 | [Prescriptions (eRx)](14_prescriptions_erx.md) | `14` | prex_* | Electronic prescribing |
| 15 | [Labs](15_labs.md) | `15` | chc_*, lab_history_* | Laboratory orders & results |

## STI (Single Table Inheritance) Tables

| Table | Type Column | Known Subtypes |
|-------|-------------|----------------|
| `people` | `type` | `Client` (behavioral health client) |
| `companies` | `type` | `Payor` (insurance payer) |
| `documents` | `type` | `Collateral`, `UploadedDocument` |
| `pictures` | `type` | `Client::Document`, `Card`, `FacePicture` |
| `users` | `type` (disabled) | STI disabled via `self.inheritance_column = nil` |
| `genders` | `type` | TBD |
| `printables` | `type` | `PrintedPrintable` |
| `configuration_parameters` | `type` | TBD |
| `x12_transactions` | `type` | TBD |

## Key Polymorphic Associations

| Association Name | Column Pair | Used By |
|-----------------|-------------|---------|
| `addressable` | `addressable_type`, `addressable_id` | Person, Company, Location, Tfc::Home |
| `phonable` | `phonable_type`, `phonable_id` | Person, Company |
| `emailable` | `emailable_type`, `emailable_id` | Person, Company |
| `identifiable` | `identifiable_type`, `identifiable_id` | Person → User, Person → Tfc::Parent |
| `lilnotable` | `lilnotable_type`, `lilnotable_id` | Appointment, Client, InsurancePolicy, Authorization, ProgramEnrollment |
| `documentable` | `documentable_type`, `documentable_id` | Document (base), PrintedPrintable |
| `picturable` | `picturable_type`, `picturable_id` | Picture, Card, FacePicture |
| `triggerable` | `triggerable_type`, `triggerable_id` | ReminderMessage, EmailHistory |
| `transactable` | `transactable_type`, `transactable_id` | X12Transaction |
| `adjustable` | `adjustable_type`, `adjustable_id` | Claim::Adjudication |

## HABTM Join Tables (No Model)

These tables exist only to support `has_and_belongs_to_many` relationships:

| Join Table | Left | Right |
|-----------|------|-------|
| `payors_plans` | companies (Payor) | plans |
| `claim_batches_billcases` | claim_batches | billcases |
| `claim_batches_payors` | claim_batches | companies (Payor) |
| `billcases_eobs` | billcases | eobs |
| `billcases_clearing_house_responses` | billcases | clearing_house_responses |
| `billcases_client_statements` | billcases | client_statements |
| `clearing_house_responses_eobs` | clearing_house_responses | eobs |
| `charges_procedures` | charges | procedures (via superbill) |
| `auditables_users` | auditables | users |
| `auditables_payors` | auditables | companies (Payor) |
| `auditables_programs` | auditables | programs |
| `supervisions_users` | supervisions | users |
| `supervisions_payors` | supervisions | companies (Payor) |
| `locations_supervisions` | locations | supervisions |
| `locations_taxes` | locations | taxes |
| `clforms_programs` | clforms | programs |
| `goals_programs` | goals | programs |
| `objectives_programs` | objectives | programs |
| `interventions_programs` | interventions | programs |
| `life_domains_programs` | life_domains | programs |
| `admission_reasons_programs` | admission_reasons | programs |
| `discharge_reasons_programs` | discharge_reasons | programs |
| `billing_policies_plans` | billing_policies | plans |
| `fees_users` | fees | users |
| `bundled_services_payors` | bundled_services | companies (Payor) |
| `crew_teams_users` | crew_teams | users |
| `tat_drivers_tat_groups` | users | tat_groups |
| `notify_form_user_completes` | forms | users |
