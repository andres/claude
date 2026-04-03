---
stylesheet: https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.2.0/github-markdown.min.css
body_class: markdown-body
css: |-
  @page { margin: 30mm 20mm 25mm 20mm; size: letter; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; font-size: 11pt; line-height: 1.5; color: #24292f; }
  h1 { font-size: 24pt; border-bottom: 2px solid #1a7f37; padding-bottom: 8px; margin-top: 0; }
  h2 { font-size: 16pt; border-bottom: 1px solid #d0d7de; padding-bottom: 6px; page-break-after: avoid; }
  h3 { font-size: 13pt; page-break-after: avoid; }
  h4 { font-size: 11pt; page-break-after: avoid; }
  table { border-collapse: collapse; width: 100%; margin: 12px 0; font-size: 10pt; page-break-inside: avoid; }
  th { background-color: #f6f8fa; font-weight: 600; text-align: left; padding: 8px 12px; border: 1px solid #d0d7de; }
  td { padding: 8px 12px; border: 1px solid #d0d7de; vertical-align: top; }
  tr:nth-child(even) { background-color: #f6f8fa; }
  code { background-color: #eff1f3; padding: 2px 6px; border-radius: 3px; font-size: 9.5pt; }
  pre { background-color: #f6f8fa; padding: 12px; border-radius: 6px; font-size: 9.5pt; }
  .high { color: #cf222e; font-weight: 700; }
  .medium { color: #bf8700; font-weight: 700; }
  .low { color: #1a7f37; font-weight: 700; }
  blockquote { border-left: 4px solid #0969da; padding: 8px 16px; margin: 16px 0; background: #ddf4ff; }
  .cover { text-align: center; padding: 80px 0 40px 0; }
  .cover h1 { border: none; font-size: 28pt; }
  .meta { color: #57606a; font-size: 10pt; margin-top: 40px; }
  hr { border: none; border-top: 2px solid #d0d7de; margin: 24px 0; }
  ul, ol { margin: 8px 0; }
  li { margin: 4px 0; }
  .page-break { page-break-before: always; }
---

<div class="cover">

# Bear EHR — ABA Billing Gap Analysis

**NY Applied Behavior Analysis Policy Manual (Oct 2025)**
**vs Bear EHR Current Capabilities**

<div class="meta">

| | |
|---|---|
| **Prepared for** | EMR-Bear Development Team |
| **Source Policy** | eMedNY Provider Policy Manual — Applied Behavior Analysis, Updated October 1, 2025 |
| **Date** | March 24, 2026 |
| **Version** | 1.2 |

</div>
</div>

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [What Bear Already Supports](#2-what-bear-already-supports)
3. [Gaps That Need to Be Addressed](#3-gaps-that-need-to-be-addressed)
   - 3.1 Supervision Time & Caseload Report
   - 3.2 Age Eligibility Enforcement
   - 3.3 Referral Validity Period Tracking
   - 3.4 ABA Treatment Plan Form
   - 3.5 Group Session Size Enforcement
   - 3.6 Session Note Documentation
   - 3.7 MMC vs FFS Billing Distinction
   - 3.8 Record Retention Policy
4. [ABA Treatment Plan — Detailed Gap Analysis](#4-aba-treatment-plan-form--detailed-gap-analysis)
5. [ABA CPT Codes Reference](#5-aba-cpt-codes-reference)
6. [ABA NPI Routing Reference](#6-aba-npi-routing-reference)
7. [Priority Implementation Order](#7-priority-implementation-order)
8. [Next Steps](#8-next-steps)

---

<div class="page-break"></div>

## 1. Executive Summary

The Bear EHR has solid foundational billing infrastructure that can support ABA services. The billing pipeline (charges, claims, EOBs, X12, clearinghouses) is mature, and several critical ABA requirements — credential types, supervision relationships, NPI configurability, diagnosis-restricted fees, and billing policy enforcement — are already accommodated by the platform's existing flexibility.

This analysis is based on the eMedNY Applied Behavior Analysis Provider Policy Manual (effective October 1, 2025) which governs NY Medicaid fee-for-service and Managed Care billing for ABA services provided to members under 21 with an Autism Spectrum Disorder (ASD) or Rett Syndrome diagnosis.

> **Key finding:** Bear's architecture already covers the core billing mechanics for ABA. The `credential_types` table accommodates LBA/CBAA provider classifications. The `Supervision` model (with payor and location scoping) supports LBA supervisory chains. `BillingPolicy`/`PolicySet` can enforce ABA-specific procedure + diagnosis rules per plan. Fee-level `billing_level_id` restricts CPT codes to appropriate credential tiers. NPI routing is fully configurable via `Claim::FillClaim` and `billing_configuration.billing_mode`. The remaining gaps are: a supervision time/caseload compliance **report**, ABA-specific clinical **forms** (treatment plan, session notes), and billing **validation rules** (age, referral expiration, group size).

---

## 2. What Bear Already Supports

| ABA Requirement | Bear Capability | Status |
|---|---|---|
| CPT codes 97151–97158 | `fees.procedure_code` accepts any 5-char code; `fees.minimum_time_to_bill` enforces 15-min threshold | Configure as fee schedule entries |
| Billing / Rendering / Supervising provider on claims | `billcase` and `charge` have `billing_provider_id`, `performing_provider_id`, `referring_provider_id`; claims have `f_17_provider_type` | Works today |
| **LBA/CBAA credential types** | `credential_types` lookup table exists — add LBA, CBAA, ABA Technician as records. `credentials` links user → credential_type → billing_level → payor | **Configure — no code changes** |
| **Fee-to-credential-level restriction** | `fees.billing_level_id` ties each CPT code to a credential tier. ABA fees can be restricted so only LBA- or CBAA-level providers generate charges | **Configure per fee** |
| **Supervision relationships (LBA → CBAA/Tech)** | `Supervision` model with HABTM `supervisors`, scoped by `payors` and `locations`. `users.clinically_supervised_by` provides direct supervisor chain. Validates no self-supervision or circular references | **Works today** |
| **NPI routing per provider role** | NPI fields on claims are highly configurable — `billing_configuration.billing_mode` (organization/provider/provider_location) controls NPI source; `Claim::FillClaim` populates f_* fields from provider credentials | **Works today** |
| **Billing policy enforcement** | `BillingPolicy` → `PolicySet` → `PolicyProcedure` + `ICD` combinations, scoped per plan. Can enforce ABA-specific procedure + diagnosis rules at the plan level | **Configure per plan** |
| Referral tracking | `xtreferrals` model with referrer, NPI, date, `provider_type` (referring / supervising) | Works today |
| Prior authorization with units | `authorizations` with `procedure_quantity`, `amount_cents`, `valid_from/until`, `fee_list` (comma-separated CPT codes), `remaining_units()`, `expired?()` | Works today |
| Diagnosis-restricted fees | `fees.specific_dxes` (HABTM with ICD codes) + `Procedure#validate_specific_dx()` enforces diagnosis match at billing time | Works today |
| 15-minute unit billing | `fees.unit_type` supports "minutes", `fees.units` = 15 | Configure per fee |
| Place of service | Full POS code table; `fees.place_of_service` stores comma-separated allowed POS codes per fee | Works today |
| Treatment plans | `tp/` module with goals, objectives, interventions, progress tracking, program-scoped assignments | Works today |
| Group sessions | `crew_teams` → `crew_sessions` → `crew_attendances` → per-client `encounter_forms` with individual superbills | Works today |
| Fee utilization limits | `fees.max_per_day`, `fees.max_per_year`, `fees.once_per_day`, `fees.minimum_time_to_bill` | Works today |
| ABA program enrollment | `programs` + `program_enrollments` — ABA as a program with client enrollment, insurance policy attachment, location scoping | Configure as new program |

---

<div class="page-break"></div>

## 3. Gaps That Need to Be Addressed

### 3.1 Supervision Time & Caseload Report — <span class="high">HIGH</span>

While Bear's supervision system supports the LBA-to-CBAA/technician relationships, the ABA policy imposes specific **quantitative supervision requirements** that need a dedicated report to track and justify compliance.

**Caseload limits:**
- An LBA can supervise **no more than 6 individuals total** (any combination of CBAAs and unlicensed technicians)
- Examples: 1 CBAA + 5 technicians = 6 (at cap), 6 CBAAs + 0 technicians = 6 (at cap)

**Time requirements per supervisee per calendar month:**
- Supervision must be **5% minimum** of the hours the technician/CBAA spends providing ABA services
- At least **2 face-to-face, real-time contacts** (phone/email/text do not count)
- The LBA must **observe the supervisee providing services** in at least 1 of those contacts
- One of the two monthly contacts may occur in a small-group meeting

**Data sources available in Bear for the report:**
- **Supervisee service hours:** `encounter_forms` joined through `superbills` → `procedures` (units × 15 min) where `encounter_forms.user_id` = supervisee and `programs.id` = ABA program, grouped by calendar month
- **Supervisor identity:** `supervisions` table (HABTM `supervisors`) or `users.clinically_supervised_by`
- **Credential type:** `credentials` → `credential_types` per user — identifies LBA vs CBAA vs technician
- **Supervision encounters:** `encounter_forms` where `user_id` = LBA and `client_id` matches supervisee's caseload, filtered to supervision-relevant form types
- **Group vs individual contacts:** `crew_sessions` (group) vs direct encounter_forms (individual)
- **CPT 97155 qualification:** `charges.procedure_code = '97155'` on encounters where both LBA and technician are documented

**What the report needs to show:**
- Per LBA: current supervisee count (vs. 6 cap), with credential type breakdown (CBAA vs technician)
- Per supervisee per month: total ABA service hours delivered, total supervision hours received, supervision percentage (vs. 5% minimum)
- Per supervisee per month: count and type of face-to-face contacts (individual vs. group), observation flag
- Compliance status flags: at-risk (approaching thresholds) and non-compliant (below minimums)
- CPT 97155 sessions that qualify toward the 5% (only when LBA directs technician in a new/modified protocol)

> **Needed:** A supervision time and caseload compliance report that aggregates encounter data by LBA and supervisee, calculates supervision percentages, and flags non-compliance. The underlying data exists across `encounter_forms`, `supervisions`, `credentials`, and `crew_sessions` — the gap is the report aggregation and compliance dashboard, not the data capture. This is critical for audit readiness and for justifying the time and workload allocation of CBAAs.

### 3.2 Age Eligibility Enforcement — <span class="medium">MEDIUM</span>

ABA services under NY Medicaid are only covered for members **under 21 years of age**. The `people.date_of_birth` field is available on all clients, but there is no age-based eligibility check anywhere in the billing pipeline — not on `fees`, `procedures`, `superbills`, or `billcases`. The superbill-to-billcase conversion (`Superbill::BillcaseConverter`) validates insurance policy dates, authorization, and diagnosis, but does not check client age against any fee-level constraint.

> **Needed:** A `maximum_age` field on `fees` (or a validation in the superbill conversion flow) that rejects/flags billcases where the client's age at date of service is 21 or older. The check should compute age from `people.date_of_birth` against `billcase.date_of_service`.

### 3.3 Referral Validity Period Tracking — <span class="medium">MEDIUM</span>

ABA referrals are valid for **no more than 2 years**. The `xtreferrals` model has `referral_date` but no `expiration_date` or `valid_until` field. Note: while `authorizations` have robust expiration tracking (`valid_until`, `expired?()`, `about_to_expire?()`), the `xtreferrals` model has no equivalent — referral expiration is not enforced anywhere in the billing pipeline.

The referral must also capture specific information per policy:

- Age of the patient
- ASD or Rett Syndrome diagnosis
- Date of initial diagnosis
- Co-morbid diagnosis (if applicable)
- Symptom severity level / level of support
- Statement that the patient needs ABA services
- DSM-5 Diagnostic Checklist for ASD diagnoses

The referring provider must be a **NYS-licensed and NYS Medicaid-enrolled** physician, psychologist, psychiatric nurse practitioner, pediatric nurse practitioner, or physician assistant.

> **Needed:** Expiration date on referrals + validation that prevents billing ABA services against an expired referral + structured fields for the required referral content.

### 3.4 ABA-Specific Treatment Plan Form — <span class="medium">MEDIUM</span>

Bear has a robust treatment plan module, but ABA treatment plans require specific structured elements not present in the existing forms. See **Section 4** for the full detailed gap analysis.

### 3.5 Group Session Size Enforcement — <span class="low">LOW-MEDIUM</span>

CPT codes 97154 and 97158 (group treatment) are limited to **max 8 individuals**. The `crew_teams` → `crew_memberships` → `crew_sessions` → `crew_attendances` pipeline creates per-client `encounter_forms` with individual superbills, which is correct for ABA group billing. However, there is no attendance cap validation — `crew_attendances` can be created for any number of clients per `crew_session`. CPT codes 97156 and 97157 (family guidance) have specific face-to-face requirements with guardians/caregivers not currently modeled.

> **Needed:** Validation on `crew_attendances` count per `crew_session` when the associated fee is 97154 or 97158, enforcing the 8-patient maximum. This could be a `before_create` callback on `Crew::Attendance` or a validation on `Crew::Session`.

### 3.6 Session Note / Progress Note Documentation — <span class="medium">MEDIUM</span>

Beyond the treatment plan, the policy (Section 8.3) requires clinical documentation for every ABA session that includes:

- Total hours of service per week
- Provision of services by LBA, CBAA, and/or technician (who delivered what)
- Location(s) of services (office, residence, community)
- Specific goals addressed and associated data to determine progress
- Data recorded using the collection method specified in the treatment plan

Bear's encounter forms can capture session notes, but there is no ABA-specific session note template that enforces structured data collection tied to treatment plan goals.

> **Needed:** An ABA session note form/page type that links to the client's active ABA treatment plan goals and requires structured data entry per goal per session.

### 3.7 MMC vs FFS Billing Distinction — <span class="low">LOW-MEDIUM</span>

ABA services were carved into the Medicaid Managed Care (MMC) benefit package effective **January 1, 2023**. This means:

- For **FFS members**: bill NYS Medicaid directly using the ABA fee schedule
- For **MMC members**: bill the member's specific managed care plan, which may have its own rates, prior authorization requirements, and billing procedures

Bear already supports multiple payors and plans on `insurance_policies`, but there is no ABA-specific logic to route claims differently based on FFS vs MMC status or to flag when an MMC member's plan should be contacted for coverage/billing guidance.

> **Needed:** Awareness-level enhancement — ensure ABA billing workflows check the client's insurance type and surface appropriate guidance for MMC members.

### 3.8 Record Retention Policy Flag — <span class="low">LOW</span>

ABA records must be kept for a **minimum of 6 years** and, for minors, **until the patient turns 22 years of age** (whichever is later). Bear does not currently have a service-specific retention policy flag.

> **Needed:** A retention policy attribute on ABA-related records (or program-level configuration) that prevents premature archival/purging.

---

<div class="page-break"></div>

## 4. ABA Treatment Plan Form — Detailed Gap Analysis

### 4.1 Bear's Current Treatment Plan Structure

Bear has a sophisticated TP system with a reusable hierarchy:

```
Problem (ICD-linked)
  ├── Goals
  │     ├── Objectives (state machine: new → met/partially_met/not_met/deferred/continued)
  │     └── Interventions
  └── Symptoms/Risks (with assessment levels)
```

Per-client assignments track progress via `Outcome` records, support due dates, program-based scoping, and life domain mapping. The `assigned_objectives` have quantitative from/to tracking with configurable unit types.

There is also an existing `AppliedBehaviorResult` page model — but it is minimal, only capturing an ABA yes/no flag, referral info, provider names/NPIs, and a diagnosis code. This is a **referral documentation page**, not a treatment plan.

### 4.2 Gaps by Section

#### A. Behavioral Assessment Section — No Current Equivalent

The ABA treatment plan must document the **assessment methodology and results** before any goals are set. The assessment itself is a billable service (CPT 97151).

| Required Field | Bear Equivalent | Gap |
|---|---|---|
| Assessment methodology (ABC log, FBA, behavioral observation, self-monitoring, inventory) | None — TP starts at Problem assignment | New section needed |
| Results of assessment | None | New field |
| Standardized assessments used (adaptive behavior scales, symptom inventories, aggression ratings) | None | New field |
| Results of standardized assessment | None | New field |

#### B. Operationally Defined Target Behaviors — Partially Mapped

| Required Field | Bear Equivalent | Gap |
|---|---|---|
| Operationally defined target behavior (increase or decrease) | `assigned_goal.client_goal` (free text) | Needs structured direction: increase / decrease / maintain |
| Baseline data in objective terms (frequency, intensity, duration) | `assigned_objective.from_quantity` + `from_type` | Partially works — unit types limited |
| Current data in same method as baseline | `outcome.current_quantity` + `current_type` | Same limitation on types |
| Date of goal introduction | `assigned_goal.created_at` | Works but not a user-facing field |
| Sampling method for ongoing data collection | None | New field needed |
| Expected frequency of data collection | None | New field needed |

Bear's `objective.default_unit_type` options are: *1-10 scale, percent, times per day/week/month, episode*. ABA needs more granular behavioral measurement types: **rate (per hour), duration (minutes), latency (seconds), interval recording percentage, frequency count**.

#### C. Mastery & Generalization Criteria — Not Present

| Required Field | Bear Equivalent | Gap |
|---|---|---|
| Criterion for mastery per goal | `assigned_objective.to_quantity` (single target number) | New structured fields needed |
| Maintenance criteria | None | New field |
| Generalization criteria | None | New field |
| Conditions/context for performance | None | New field |
| Instructional procedure per goal | `assigned_intervention` (named, not described) | Needs structured procedure description |

#### D. Background & Referral Context — Partially Mapped

| Required Field | Bear Equivalent | Gap |
|---|---|---|
| Reason for referral | `xtreferral.source_note` | Could work |
| Background info (psychosocial, family, educational, medical history) | Scattered across intake forms | New section or cross-reference |
| Client strengths | None on TP | New field |
| Current educational/therapeutic services | None on TP | New field |
| Response to current services & barriers | None on TP | New field |
| Treatment setting | POS on charge, not on TP | New field on TP |
| Plan for coordination with other providers | None | New field |
| Plans for transition and discharge | `discharge_review` exists but is retrospective | New prospective section |

#### E. Caregiver/Family Training Goals — Not Present

| Required Field | Bear Equivalent | Gap |
|---|---|---|
| Parent/caregiver training goals | None — goals are client-focused | New goal type or flag |
| Generalization of skills to home/community | None | Part of caregiver training section |

This maps to CPT 97156 (family guidance) and 97157 (multi-family guidance). The treatment plan should explicitly identify which goals involve caregiver training so billing for these codes can be linked.

#### F. 6-Month Mandatory Review Cycle — Partially Mapped

| Required Field | Bear Equivalent | Gap |
|---|---|---|
| TP updated every 6 months minimum | `encounter_form.next_due_date` + form recurrence | Can be configured but needs enforcement |
| Updated goals and data | `goal_review` model exists | Works |
| Relevant changes in history | None structured | New field on review |
| Shared with referring provider | None tracked | New field (date shared) |

The policy also requires that initial treatment plans and updates be **shared with the referring provider** and, as necessary, other care providers (primary care, PT, OT, speech).

<div class="page-break"></div>

### 4.3 Proposed ABA Treatment Plan Form Structure

#### Section 1: Client Background
- Reason for referral (text)
- Referral date + referring provider (pull from `xtreferral`)
- ASD/Rett diagnosis with date of initial diagnosis (pull from `diagnoses`)
- Severity level / level of support (dropdown: Level 1 / Level 2 / Level 3)
- Comorbid diagnoses (multi-select from client's dx history)
- Client strengths (text)
- Psychosocial / family / educational / medical history summary (text)
- Current services being received (text)
- Response to current services and barriers to treatment (text)

#### Section 2: Behavioral Assessment
- Assessment date(s)
- Assessment methodology (multi-select: ABC log, functional behavior assessment, behavioral observation/sampling, self-monitoring/self-report, inventory, other)
- Assessment methodology description (text per method)
- Standardized assessments used (multi-entry: assessment name + score + date)
- Assessment results summary (text)

#### Section 3: Target Behaviors & Goals

For each target behavior (extends Bear's `assigned_problem` → `assigned_goal`):

- Operationally defined target behavior (text)
- Direction: increase / decrease / maintain (enum)
- Baseline data: value + unit (frequency / rate / duration / latency / interval %)
- Date of introduction
- Data collection method (dropdown: frequency count, rate recording, duration recording, latency recording, interval recording, time sampling, permanent product)
- Expected collection frequency (e.g., "every session", "3x/week")
- Current data: value + unit (same measurement as baseline)
- Mastery criterion (text, e.g., "80% across 3 consecutive sessions with 2 different therapists")
- Maintenance criterion (text)
- Generalization criterion (text)
- Instructional procedure (text — the teaching method)
- Conditions/context for performance (text)

#### Section 4: Caregiver Training Goals
- Caregiver training goal (text)
- Target skills for caregiver (text)
- Generalization plan (text)
- Links to CPT 97156/97157 billing

#### Section 5: Service Delivery Plan
- Recommended hours per week (numeric)
- Breakdown by provider type: LBA direct hours, CBAA hours, technician hours
- Treatment setting(s) (multi-select: home, clinic, community, school — noting school is not Medicaid-reimbursable)
- Estimated duration of treatment (months)

#### Section 6: Coordination & Discharge
- Other providers involved (multi-entry: name, role, contact)
- Coordination plan (text)
- Transition criteria (text)
- Discharge criteria (text)

#### Section 7: Review (Every 6 Months)
- Review date
- Updated goals and data (per goal: current data, status change, goal modifications)
- Changes in psychosocial / family / educational / medical history
- Reviewer signature (LBA)
- Shared with referring provider (date)

### 4.4 Implementation Approach

**Option A: New page type** — Create an `aba_treatment_plan` page model (like `applied_behavior_result` but much richer) that lives alongside the existing TP. Sections 1–2 and 4–7 are new fields; Section 3 extends the existing `assigned_goal`/`assigned_objective` system with ABA-specific columns.

**Option B: Extend existing TP** — Add ABA-specific fields to `assigned_goals`, `assigned_objectives`, and `treatment_plans` (with flags to show/hide based on program type). This keeps everything in one TP system but adds complexity to the existing code.

> **Recommendation:** Option A is cleaner. The existing TP system is behavioral-health-generic and already complex (17 models under `tp/`). An ABA-specific page would let you build the exact form the policy requires without retrofitting the general TP structure.

---

<div class="page-break"></div>

## 5. ABA CPT Codes Reference

| CPT Code | Description | Unit | Who Delivers | Who Bills |
|---|---|---|---|---|
| **97151** | Behavior identification assessment — administered by LBA, face-to-face with patient and/or caregiver, including non-face-to-face analysis and report preparation | 15 min | LBA | LBA |
| **97152** | Behavior identification-supporting assessment — administered by technician under LBA direction, face-to-face with patient | 15 min | Technician | LBA |
| **97153** | Adaptive behavior treatment by protocol — administered by technician under LBA direction, face-to-face, one patient | 15 min | Technician | LBA |
| **97154** | Group adaptive behavior treatment by protocol — administered by technician under LBA direction, face-to-face, **2+ patients (max 8)** | 15 min | Technician | LBA |
| **97155** | Adaptive behavior treatment with protocol modification — administered by LBA, may include simultaneous technician direction, face-to-face, one patient | 15 min | LBA | LBA |
| **97156** | Family adaptive behavior treatment guidance — administered by LBA, face-to-face with guardian(s)/caregiver(s), **with or without patient present** | 15 min | LBA | LBA |
| **97157** | Multiple-family group adaptive behavior treatment guidance — administered by LBA, face-to-face with **multiple sets of guardians/caregivers, without patient** | 15 min | LBA | LBA |
| **97158** | Group adaptive behavior treatment with protocol modification — administered by LBA, face-to-face, **multiple patients (max 8)** | 15 min | LBA | LBA |

**Billing Rules:**

- **97156 & 97157:** Can only be billed when the service is delivered as part of the child's treatment plan
- **97154 & 97158:** Can only be billed for group sessions of **no more than 8 individuals**
- **97155 & the 5% rule:** May count toward the 5% supervision minimum **only** when the LBA joins the patient and technician during a treatment session to direct the technician in implementing a **new or modified treatment protocol**
- All codes are billed in **15-minute increments**
- All ABA services require an **ASD or Rett Syndrome diagnosis** (DSM-5) and the client must be **under 21 years of age**

---

## 6. ABA NPI Routing Reference

Bear's NPI fields are highly configurable and can accommodate all ABA provider role scenarios. The table below documents the correct NPI mapping for reference during configuration:

| Service Delivered By | Billing NPI | Supervising NPI | Rendering NPI |
|---|---|---|---|
| LBA directly | LBA | — | LBA |
| CBAA (supervised by LBA) | Supervising LBA | Supervising LBA | CBAA |
| Unlicensed technician | Supervising LBA | Supervising LBA | Supervising LBA |
| LBA limited permit holder | Supervising LBA | Supervising LBA | Supervising LBA |

**Key rules:**
- For CBAAs, the CBAA's own NPI appears **only** in the Rendering Provider field. Billing and Supervising always use the supervising LBA's NPI.
- For unlicensed technicians and LBA limited permit holders, **all three NPI fields** use the supervising LBA's NPI.
- CBAAs cannot bill Medicaid directly — the supervising LBA's NPI must be used for billing.
- LBAs can bill for services provided by non-enrolled unlicensed aides in their multi-disciplinary team.

---

<div class="page-break"></div>

## 7. Priority Implementation Order

| Priority | Item | Type | Rationale |
|---|---|---|---|
| **1** | ABA fee schedule setup (97151–97158, ICD restrictions, 15-min units) | Configuration | Core billing — can proceed immediately, no code changes |
| **2** | LBA/CBAA/Technician credential types | Configuration | Add credential types to accommodate ABA provider roles |
| **3** | Supervision relationships (LBA → supervisees) | Configuration | Set up LBA-to-CBAA and LBA-to-technician supervisory assignments |
| **4** | NPI routing per provider role | Configuration | Configure billing/rendering/supervising NPIs per the routing table in Section 6 |
| **5** | Supervision time & caseload compliance report | **New development** | Critical for audit readiness — justifies CBAA time/load and tracks 5%/2-contact minimums |
| **6** | Referral expiration tracking (2-year validity + required fields) | New development | Billing prerequisite — services without valid referral are not covered |
| **7** | Age eligibility validation (under 21) | New development | Prevents billing for ineligible clients |
| **8** | ABA treatment plan form with structured fields | New development | Clinical documentation requirement; claims may be audited |
| **9** | ABA session note template | New development | Per-session documentation linked to treatment plan goals |
| **10** | Group session size enforcement (max 8 for 97154/97158) | New development | Edge case validation |
| **11** | MMC vs FFS routing awareness | Enhancement | Guidance-level enhancement |
| **12** | Record retention policy flag | Enhancement | Low urgency; administrative |

> **Note:** Items 1–4 are configuration tasks that can proceed immediately with no code changes. Item 5 (supervision report) is the highest-priority new development, as it is required to demonstrate compliance during audits and to justify the time allocation and caseload of CBAAs working under LBA supervision.

---

## 8. Next Steps

1. **Configure fee schedules** — Set up ABA fee schedule with CPT 97151–97158, attach ASD/Rett ICD restrictions via `specific_dxes`, configure 15-minute units. This can start immediately.

2. **Configure credential types and supervision** — Add LBA, CBAA, and ABA Technician credential types. Set up supervisory relationships in the existing supervision system. Configure NPI routing per the reference table in Section 6.

3. **Build supervision time & caseload report** — This is the first required development item. The report should aggregate encounter data by LBA and supervisee, calculate supervision percentages against service hours, track face-to-face contact counts, and flag non-compliance. This is essential for justifying CBAA workload and audit readiness.

4. **Build ABA treatment plan form** — Design the page type per Section 4.3, decide on Option A vs B, and build incrementally (background section first, then goals, then reviews).

5. **Validate with stakeholders** — Confirm which Bear agencies will be providing ABA services and whether they bill FFS, MMC, or both.

6. **Pilot and iterate** — Start with a single agency, validate claim acceptance with eMedNY / clearinghouse, and refine configuration based on real rejection data.
