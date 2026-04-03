# NewBear

Specification and build playbook for the next-generation Bear EHR platform.

Bear has served behavioral health agencies for 15 years on Rails 5.2 / MariaDB / MongoDB.
NewBear reimagines the product for the AI-native era while preserving every byte of
production data across ~80 agencies.

**Deployment model:** Single-tenant (each agency = own instance + database).

## Document Structure

### Foundation

| Doc | Purpose |
|-----|---------|
| [00 Principles](00_principles.md) | Non-negotiable design principles and constraints |
| [01 Architecture](01_architecture.md) | Technical architecture, stack decisions, patterns |
| [02 Data Contract](02_data_contract.md) | Data migration rules, schema evolution, zero-loss guarantees |
| [03 Build Rules](03_build_rules.md) | How to define, build, test, and ship each module |
| [04 Domain Template](04_domain_template.md) | Template for defining each functional domain |
| [05 Interaction Standards](05_interaction_standards.md) | Validation, forms, buttons, loading, keyboard, voice feedback |

### Functional Domains (Existing - Reimagined)

| Doc | Domain | Bear Legacy |
|-----|--------|-------------|
| [10 Client Identity](10_client_identity.md) | Client identity, demographics, relationships | people, names, addresses, phones, emails, genders |
| [11 Care Programs](11_care_programs.md) | Programs, enrollment, pathways, levels of care | programs, program_enrollments, locations, sections |
| [12 Payer Management](12_payer_management.md) | Insurance, plans, eligibility, authorizations | insurance_policies, plans, schedules, fees, authorizations |
| [13 Scheduling](13_scheduling.md) | Appointments, availability, calendar, reminders | appointments, appointment_types, recursions |
| [14 Clinical Documentation](14_clinical_documentation.md) | Encounters, forms, notes, signatures | encounters, encounter_forms, forms, completed_pages |
| [15 Revenue Cycle](15_revenue_cycle.md) | Billing, claims, payments, AR, statements | billcases, charges, claims, eobs, payments |
| [16 Clinical Records](16_clinical_records.md) | Diagnoses, vitals, allergies, conditions | diagnoses, icds, vitals, medications, med_* MongoDB |
| [17 Workforce](17_workforce.md) | Staff, credentials, roles, supervision, scheduling | users, roles, credentials, certifications, supervisions |
| [18 Foster Care](18_foster_care.md) | TFC homes, parents, placements, billing | tfc_* tables |
| [19 Substance Use Treatment](19_substance_use.md) | OTP orders, dispensing, inventory, dosing | otp_* tables |
| [20 Care Logistics](20_care_logistics.md) | Transportation, drivers, fleet, routing | tat_* tables |
| [21 Group Services](21_group_services.md) | Group therapy, teams, attendance, notes | crew_* tables |
| [22 Residential](22_residential.md) | Bed management, admissions, census | spot_* tables |
| [23 Prescribing](23_prescribing.md) | eRx, EPCS, formulary, medication management | prex_* tables |
| [24 Diagnostics](24_diagnostics.md) | Lab orders, results, point-of-care testing | chc_*, lab_history_*, btnx_* tables |

### Functional Domains (New)

| Doc | Domain | Why |
|-----|--------|-----|
| [30 Client Portal](30_client_portal.md) | Self-service, intake, messaging, documents | Clients expect digital access |
| [31 AI Clinical Assist](31_ai_clinical_assist.md) | Scribe, documentation assist, coding suggestions | AI-native documentation |
| [32 AI Revenue Intelligence](32_ai_revenue_intelligence.md) | AI datalake for RCM, denial prediction, coding optimization, revenue forecasting | Revenue cycle is where AI has highest ROI |
| [33 AI Report Assist](33_ai_report_assist.md) | Natural language reporting, automated dashboards, regulatory report generation | Every agency needs reports, few have analysts |
| [34 Outcomes & Quality](34_outcomes_quality.md) | HEDIS, CCBHC, MIPS, custom measures, dashboards | Payers demand outcomes data |
| [35 Care Coordination](35_care_coordination.md) | Referrals, transitions, external providers, HIE | Behavioral health is collaborative |
| [36 Telehealth](36_telehealth.md) | Video, async messaging, remote monitoring | Post-COVID standard of care |
| [37 Consent & Privacy](37_consent_privacy.md) | 42 CFR Part 2, consent management, audit trail | Behavioral health has stricter rules than HIPAA |
| [38 Crisis & Safety](38_crisis_safety.md) | Safety plans, crisis protocols, risk assessment | Core to behavioral health mission |
| [39 SDOH](39_sdoh.md) | Social determinants screening, referrals, tracking | Whole-person care |
| [40 Interoperability](40_interoperability.md) | FHIR R4, C-CDA, ADT, SNOMED CT storage, RxNorm support, payer connectivity | Regulatory mandate + clinical data standards |
| [41 Analytics](41_analytics.md) | Embedded dashboards, ad-hoc reporting, data export | Native analytics, not bolt-on |
| [42 Workflow Engine](42_workflow_engine.md) | Rules, triggers, automations, task queues | Replace hardcoded Rails callbacks |
| [43 Audit & Compliance](43_audit_compliance.md) | Audit log, compliance checks, regulatory reporting | Every agency gets audited |
| [44 Notifications](44_notifications.md) | Alerts, reminders, escalations, channels | Unified notification system |

### Considerations (Not Committed)

| Doc | Topic | Notes |
|-----|-------|-------|
| [90 Multi-Tenancy](90_multi_tenancy.md) | Shared infrastructure, tenant isolation, migration path | Weighing pros/cons for future, not building now |
