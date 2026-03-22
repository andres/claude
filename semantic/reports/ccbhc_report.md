# CCBHC Report — Bear EHR (SAMHSA-Aligned)

> Generated from Bear staging DB (MariaDB). All queries are production-ready.
> Aligned with SAMHSA CCBHC Certification Criteria (2024 update) and Quality Measures Technical Specifications.
>
> Sources:
> - [SAMHSA CCBHC Quality Measures Guidance](https://www.samhsa.gov/communities/certified-community-behavioral-health-clinics/guidance-and-webinars)
> - [SAMHSA CCBHC Certification Criteria](https://www.samhsa.gov/communities/certified-community-behavioral-health-clinics/ccbhc-certification-criteria)
> - [SimiTree FAQ: New CCBHC Quality Measures](https://simitreehc.com/simitree-blog/faq-guide-to-new-and-revised-ccbhc-quality-measures/)
> - [Qualifacts: SAMHSA New CCBHC Criteria](https://www.qualifacts.com/resources/samhsa-releases-new-ccbhc-criteria/)

---

## Table of Contents

1. [CCBHC Configuration](#1-ccbhc-configuration)
2. [SAMHSA Quality Measures — Clinic-Collected (Required)](#2-clinic-collected-required-measures)
3. [SAMHSA Quality Measures — Clinic-Collected (Optional)](#3-clinic-collected-optional-measures)
4. [SAMHSA Quality Measures — State-Collected](#4-state-collected-measures)
5. [Service Volume & Per Diem Billing](#5-service-volume--per-diem-billing)
6. [Client Demographics & Diagnosis Mix](#6-client-demographics--diagnosis-mix)
7. [Service Delivery by Location](#7-service-delivery-by-location)
8. [Revenue Summary](#8-revenue-summary)
9. [Operational Queries for Production](#9-operational-queries-for-production)
10. [Gap Analysis & Recommendations](#10-gap-analysis--recommendations)

---

## 1. CCBHC Configuration

### CCBHC Plan
| Plan ID | Name | CCBHC NPI |
|---------|------|-----------|
| 33 | BCBS CCBHC | (not set) |

### Fee Schedule — CCBHC-Tagged Services

| Type | CPT | Description | Rate |
|------|-----|-------------|------|
| **Per Diem (cap)** | T1040 | CCBHC Per Diem | $250.00 |
| **Trigger** | 90791 | Psychiatric diagnostic evaluation | $0 (per diem) |
| **Trigger** | 90837 | Psychotherapy with family member - 60 min | $0 (per diem) |
| **Trigger** | 99214 | Established 45-59 Minutes | $0 (per diem) |
| **Trigger** | H2015 | CCSS In Office | $0 (per diem) |
| **Trigger** | H0015 | IOP psychotherapy (SUD) | $0 (per diem) |
| **Trigger** | H0038 | Peer Support Group | $0 (per diem) |
| **Non-trigger** | 90785 | Interactive complexity (add-on) | $25.00 |

> **CCBHC PPS Model:** Trigger services generate a T1040 per diem billcase at $250/day/client. Non-trigger services are billed separately via FFS. Trigger service charges are $0 — revenue flows through the per diem.

### DB Columns Supporting CCBHC
| Table | Column | Purpose |
|-------|--------|---------|
| `fees` | `ccbhc_trigger` | Flags services that trigger a per diem |
| `fees` | `ccbhc_cap` | Flags the per diem fee itself (T1040) |
| `fees` | `ccbhc_non_trigger` | Flags non-trigger add-on services |
| `billcases` | `ccbhc_rollup_billcase_id` | Links child billcases to rollup parent |
| `charges` | `ccbhc_rollup_charge_id` | Links child charges to rollup parent |
| `charges` | `ccbhc_rollup` | Boolean: charge has been rolled up |
| `plans` | `ccbhc` | Marks plan as CCBHC |
| `plans` | `ccbhc_npi` | CCBHC-specific NPI for claims |

```sql
-- Query: All CCBHC-tagged fees
SELECT id, procedure_code, description, rate_cents / 100.0 AS rate,
  ccbhc_cap, ccbhc_trigger, ccbhc_non_trigger
FROM fees
WHERE ccbhc_cap = 1 OR ccbhc_trigger = 1 OR ccbhc_non_trigger = 1
ORDER BY ccbhc_cap DESC, ccbhc_trigger DESC;
```

---

## 2. Clinic-Collected Required Measures

Per SAMHSA 2024 updated criteria, CCBHCs must collect and report 5 required measures starting CY2025. Data collection should have commenced by July 1, 2024.

### 2.1 I-SERV — Time to Services (Initial Service Response)

**What it measures:** Three access timeliness metrics:
- Days from new service request to initial evaluation
- Days from first contact to first clinical service
- Response time for crisis service requests

**Bear DB data available:**

| Timeliness Metric | Value |
|-------------------|-------|
| Avg days to first appointment (after enrollment) | **41.4 days** |
| Within same day | 322 (14.1%) |
| Within 7 days | 507 (22.3%) |
| Within 10 business days | 622 (27.3%) |
| Within 14 days | 759 (33.3%) |
| Within 30 days | 1,162 (51.0%) |
| Sample size (enrollments with ≤365 day window) | 2,277 |

> **SAMHSA target:** Initial evaluation within 10 business days of first contact. Currently **27.3%** meet this — significant gap.

```sql
-- Query: I-SERV — Days from enrollment to first appointment
SELECT
  COUNT(*) AS total,
  SUM(CASE WHEN days_to_eval <= 1 THEN 1 ELSE 0 END) AS within_1_day,
  SUM(CASE WHEN days_to_eval <= 7 THEN 1 ELSE 0 END) AS within_7_days,
  SUM(CASE WHEN days_to_eval <= 10 THEN 1 ELSE 0 END) AS within_10_biz_days,
  SUM(CASE WHEN days_to_eval <= 14 THEN 1 ELSE 0 END) AS within_14_days,
  SUM(CASE WHEN days_to_eval <= 30 THEN 1 ELSE 0 END) AS within_30_days,
  ROUND(AVG(days_to_eval), 1) AS avg_days
FROM (
  SELECT pe.client_id, pe.id AS pe_id,
    DATEDIFF(MIN(a.date_time_starts), pe.created_at) AS days_to_eval
  FROM program_enrollments pe
  JOIN appointments a ON a.client_id = pe.client_id
    AND a.date_time_starts >= pe.created_at
    AND a.deleted_at IS NULL AND a.cancelled_at IS NULL
  WHERE pe.approved_at IS NOT NULL
  GROUP BY pe.client_id, pe.id
  HAVING days_to_eval >= 0 AND days_to_eval <= 365
) sub;
```

---

### 2.2 DEP-REM-6 — Depression Remission at Six Months

**What it measures:** Percentage of clients aged 12+ with a diagnosis of major depression (F32.x/F33.x) who achieve remission (PHQ-9 score < 5) within 6 months.

**Numerator:** Clients with PHQ-9 score < 5 at 6-month follow-up
**Denominator:** Clients aged 12+ with F32/F33 diagnosis and baseline PHQ-9 ≥ 5

**Bear DB data available:**

| Element | Value | Source |
|---------|-------|--------|
| Clients with depression (F32/F33) | **123** | `diagnoses` + `icds` |
| PHQ-9 screening forms | **Depression Screening (PHQ)** (form #250) + **NEW-CBPIR Depression Screening (PHQ-9)** (form #277) | `forms` |
| PHQ screenings completed | 11 completions / 6 unique clients | `encounter_forms` |
| Clients on antidepressants (co-measure) | 55 | `medications` |

> **Gap:** PHQ-9 completion rate is very low (6 clients screened vs. 123 with depression dx). The PHQ-9 score value itself is stored in MongoDB (`med_assessments`) or `completed_pages`, not directly queryable via SQL. Need to verify where the actual score is stored.

```sql
-- Query: Depression denominator — clients with F32/F33
SELECT COUNT(DISTINCT d.client_id) AS clients_with_depression
FROM diagnoses d JOIN icds i ON d.icd_id = i.id
WHERE (i.code LIKE 'F32%' OR i.code LIKE 'F33%')
AND d.client_id IN (SELECT id FROM people WHERE type = 'Client' AND deleted_at IS NULL);

-- Query: PHQ-9 screenings completed
SELECT f.title, COUNT(DISTINCT ef.id) AS completions, COUNT(DISTINCT ef.client_id) AS unique_clients
FROM encounter_forms ef JOIN forms f ON ef.form_id = f.id
WHERE f.id IN (250, 277) AND ef.state = 'completed'
GROUP BY f.title;
```

---

### 2.3 CDF-AD / CDF-CH — Screening for Clinical Depression and Follow-Up Plan

**What it measures:** Percentage of clients aged 12+ (CDF-AD for adults, CDF-CH for adolescents) screened for depression using a standardized tool (PHQ-9/PHQ-A) with a documented follow-up plan for positive screens.

**Numerator:** Clients screened + follow-up plan documented if positive
**Denominator:** All clients aged 12+ with an encounter during measurement period

**Bear DB forms available:**
| Form | ID | Completions | Unique Clients |
|------|----|-------------|----------------|
| Depression Screening (PHQ) | 250 | 9 | 4 |
| NEW-CBPIR Depression Screening (PHQ-9) | 277 | 2 | 2 |
| **Total** | | **11** | **6** |

```sql
-- Query: CDF screening rate
SELECT
  (SELECT COUNT(DISTINCT ef.client_id) FROM encounter_forms ef WHERE ef.form_id IN (250, 277) AND ef.state = 'completed') AS screened,
  (SELECT COUNT(DISTINCT ef2.client_id) FROM encounter_forms ef2 WHERE ef2.state = 'completed') AS total_clients_with_encounters,
  ROUND(
    (SELECT COUNT(DISTINCT ef3.client_id) FROM encounter_forms ef3 WHERE ef3.form_id IN (250, 277) AND ef3.state = 'completed') /
    (SELECT COUNT(DISTINCT ef4.client_id) FROM encounter_forms ef4 WHERE ef4.state = 'completed') * 100, 1
  ) AS screening_rate_pct;
```

---

### 2.4 ASC — Unhealthy Alcohol Use: Screening & Brief Counseling

**What it measures:** Percentage of clients aged 18+ screened for unhealthy alcohol use using a validated tool (e.g., AUDIT-C) and who received brief counseling if screen was positive.

**Bear DB forms available:**
| Form | ID | Completions | Unique Clients |
|------|----|-------------|----------------|
| AUDIT-C | 393 | 3 | 1 |
| Modified Single Alcohol Screening (M-SASQ) | 484 | 0 | 0 |
| Brief Alcohol Withdrawal Scale (BAWS) | 374 | 2 | 1 |
| Clinical Institute Withdrawal Assessment (CIWA) | 376 | 2 | 1 |
| Substance Use Assessment | 138 | 11 | 5 |

```sql
-- Query: ASC — Alcohol screening completions
SELECT f.title, COUNT(DISTINCT ef.id) AS completions, COUNT(DISTINCT ef.client_id) AS unique_clients
FROM encounter_forms ef JOIN forms f ON ef.form_id = f.id
WHERE f.id IN (393, 484, 374, 376, 138) AND ef.state = 'completed'
GROUP BY f.title ORDER BY completions DESC;
```

---

### 2.5 SDOH — Screening for Social Drivers of Health

**What it measures:** Percentage of clients screened for social determinants of health (housing, food insecurity, transportation, utilities, safety) using a standardized tool, with follow-up on identified needs.

**Bear DB status:** **No dedicated SDOH screening form found in the forms table.**

> **Gap:** This is a required measure. Bear needs an SDOH screening form (e.g., AHC HRSN, PRAPARE, or custom) added to the clinical documentation workflow.

```sql
-- Query: Check for SDOH-related forms
SELECT id, title FROM forms
WHERE title LIKE '%SDOH%' OR title LIKE '%social det%' OR title LIKE '%social driver%'
   OR title LIKE '%housing%' OR title LIKE '%PRAPARE%' OR title LIKE '%HRSN%';
```

---

## 3. Clinic-Collected Optional Measures

These were previously required but became optional in the 2024 update. Bear has forms to support most of them.

### 3.1 TSC — Tobacco Use: Screening & Cessation
**Status:** No dedicated tobacco screening form found. Could be embedded in intake or assessment forms.

### 3.2 SRA-A / SRA-C — Suicide Risk Assessment
**Bear forms available:**
| Form | ID | Completions | Unique Clients |
|------|----|-------------|----------------|
| Suicide Screening (Columbia) | 228 | 2 | 2 |
| CSSRS Screening | 256 | 2 | 2 |

### 3.3 WCC-CH — Weight Assessment and Counseling (Children/Adolescents)
**Bear forms:** Vital Signs (form #102) — 8 completions, 3 clients. Weight data likely captured here.

### 3.4 CBP-AD — Controlling High Blood Pressure
**Bear forms:** Vital Signs (form #102) captures BP. No separate hypertension tracking.

```sql
-- Query: All screening form completions
SELECT f.title, COUNT(DISTINCT ef.id) AS completions, COUNT(DISTINCT ef.client_id) AS unique_clients
FROM encounter_forms ef JOIN forms f ON ef.form_id = f.id
WHERE f.id IN (228, 256, 102, 229, 253)
AND ef.state = 'completed'
GROUP BY f.title ORDER BY completions DESC;
```

---

## 4. State-Collected Measures

These are calculated by the state from claims/encounter data submitted by the CCBHC. Bear provides the source data; the state calculates the rates.

### 4.1 Medication Management Measures

| Measure | ID | Description | Bear Population |
|---------|----|-------------|-----------------|
| Antidepressant Medication Management | **AMM-AD** | Clients with new depression episode who remain on antidepressants for acute (84 days) and continuation (180 days) phases | 123 depression clients, 55 on meds |
| Adherence to Antipsychotic Medications (Schizophrenia) | **SAA-AD** | Clients with schizophrenia who maintain ≥80% PDC on antipsychotics | 8 schizophrenia clients |
| Follow-Up Care for Children on ADHD Medication | **ADD-CH** | Children newly prescribed ADHD meds with follow-up visits | 276 ADHD clients |
| Pharmacotherapy for Opioid Use Disorder | **OUD-AD** | Clients with OUD diagnosis receiving pharmacotherapy (methadone, buprenorphine, naltrexone) | 25 OUD clients, 18 on OTP meds (38 orders) |

```sql
-- Query: AMM-AD denominator — depression clients with medications
SELECT COUNT(DISTINCT m.client_id) AS depression_clients_on_meds
FROM medications m WHERE m.client_id IN (
  SELECT DISTINCT d.client_id FROM diagnoses d JOIN icds i ON d.icd_id = i.id
  WHERE i.code LIKE 'F32%' OR i.code LIKE 'F33%'
);

-- Query: SAA-AD denominator
SELECT COUNT(DISTINCT d.client_id) AS schizophrenia_clients
FROM diagnoses d JOIN icds i ON d.icd_id = i.id
WHERE i.code LIKE 'F20%' OR i.code LIKE 'F25%';

-- Query: OUD-AD — OUD clients on pharmacotherapy
SELECT COUNT(DISTINCT o.client_id) AS clients_on_otp_meds, COUNT(*) AS total_orders
FROM otp_orders o WHERE o.deleted_by_id IS NULL;
```

### 4.2 Follow-Up Measures

| Measure | ID | Description | Data Source in Bear |
|---------|----|-------------|---------------------|
| Follow-Up After Hospitalization (Mental Illness) | **FUH-AD / FUH-CH** | 7-day and 30-day follow-up visit after MH inpatient discharge | `appointments` + discharge encounter forms |
| Follow-Up After ED Visit (Alcohol/Drug) | **FUA-AD / FUA-CH** | 7-day and 30-day follow-up after SUD-related ED visit | `appointments` + `diagnoses` |
| Follow-Up After ED Visit (Mental Illness) | **FUM-AD / FUM-CH** | 7-day and 30-day follow-up after MH-related ED visit | `appointments` + `diagnoses` |
| Initiation & Engagement of SUD Treatment | **IET-AD** | Initiation (14 days) and engagement (2+ services in 34 days) after new SUD episode | `appointments` + `diagnoses` + `encounter_forms` |
| Plan All-Cause Readmissions | **PCR-AD** | 30-day all-cause readmission rate | Claims data — `billcases` + `claims` |

```sql
-- Query: FUH proxy — clients with residential/inpatient encounter forms
SELECT f.title, COUNT(DISTINCT ef.client_id) AS clients
FROM encounter_forms ef JOIN forms f ON ef.form_id = f.id
WHERE f.title LIKE '%discharge%' OR f.title LIKE '%residential%'
   OR f.title LIKE '%inpatient%' OR f.title LIKE '%crisis%'
GROUP BY f.title;

-- Query: IET-AD denominator — new SUD episodes
SELECT COUNT(DISTINCT d.client_id) AS sud_clients
FROM diagnoses d JOIN icds i ON d.icd_id = i.id
WHERE i.code LIKE 'F10%' OR i.code LIKE 'F11%' OR i.code LIKE 'F12%'
   OR i.code LIKE 'F13%' OR i.code LIKE 'F14%' OR i.code LIKE 'F15%'
   OR i.code LIKE 'F16%' OR i.code LIKE 'F19%';
```

### 4.3 Other State Measures

| Measure | ID | Description | Bear Data |
|---------|----|-------------|-----------|
| HbA1c Control for Diabetes | **HBD-AD** | Diabetic clients with HbA1c < 9% | 0 diabetes clients (E10-E13) in staging |
| Patient Experience of Care Survey | **PEC** | Adult satisfaction survey | Requires external survey tool |
| Youth/Family Experience of Care Survey | **YFEC** | Youth/family satisfaction survey | Requires external survey tool |
| Metabolic Monitoring (Antipsychotic Rx) | **APP-CH / APM-CH** | BMI/metabolic screening for children on antipsychotics | `vitals` + `medications` |

---

## 5. Service Volume & Per Diem Billing

### Trigger Services Delivered

| CPT | Service | Charges | Unique Clients |
|-----|---------|---------|----------------|
| 90837 | Psychotherapy (family, 60 min) | 4 | 3 |
| 99214 | Established visit 45-59 min | 3 | 1 |
| H2015 | CCSS In Office | 3 | 1 |
| H0015 | IOP psychotherapy (SUD) | 2 | 1 |
| 90791 | Psychiatric diagnostic eval | 1 | 1 |
| **Total** | | **13** | **5** |

### Per Diem (T1040) Billing by Month

| Month | Billcases | Unique Clients | Billed | Paid |
|-------|-----------|----------------|--------|------|
| Apr 2025 | 1 | 1 | $750 | $0 |
| Nov 2025 | 2 | 2 | $500 | $0 |
| **Total** | **3** | **3** | **$1,250** | **$0** |

### Rollup Summary
- **2 rollup billcases** (parent per diem cases)
- **11 charges** linked to CCBHC rollups, **7 rolled up**

---

## 6. Client Demographics & Diagnosis Mix

### CCBHC Client Demographics
| Metric | Value |
|--------|-------|
| Total CCBHC clients served | 5 |
| Male | 3 |
| Female | 2 |
| Average age | 42.5 years |

### Organization-Wide Diagnosis Mix (CCBHC-Relevant)

| Category | ICD-10 | Clients | CCBHC Relevance |
|----------|--------|---------|-----------------|
| Trauma/PTSD | F43.x | **374** | Crisis services, trauma-informed care |
| ADHD | F90.x | **276** | ADD-CH measure (children on meds) |
| Depression | F32-F33 | **123** | DEP-REM-6, CDF, AMM-AD measures |
| Alcohol Use Disorder | F10.x | **115** | ASC, IET-AD, FUA measures |
| Anxiety | F40-F41 | **104** | Screening, treatment engagement |
| Opioid Use Disorder | F11.x | **25** | OUD-AD, OTP services |
| Bipolar | F31.x | **24** | Medication management |
| Other SUD | F12-F19 | **14** | IET-AD measure |
| Schizophrenia | F20/F25 | **8** | SAA-AD measure |

```sql
-- Query: Diagnosis mix by CCBHC-relevant category
SELECT
  CASE
    WHEN i.code LIKE 'F32%' OR i.code LIKE 'F33%' THEN 'Depression (F32-F33)'
    WHEN i.code LIKE 'F41%' OR i.code LIKE 'F40%' THEN 'Anxiety (F40-F41)'
    WHEN i.code LIKE 'F43%' THEN 'Trauma/PTSD (F43)'
    WHEN i.code LIKE 'F31%' THEN 'Bipolar (F31)'
    WHEN i.code LIKE 'F20%' OR i.code LIKE 'F25%' THEN 'Schizophrenia (F20/F25)'
    WHEN i.code LIKE 'F10%' THEN 'Alcohol Use Disorder (F10)'
    WHEN i.code LIKE 'F11%' THEN 'Opioid Use Disorder (F11)'
    WHEN i.code LIKE 'F12%' OR i.code LIKE 'F13%' OR i.code LIKE 'F14%'
      OR i.code LIKE 'F15%' OR i.code LIKE 'F16%' OR i.code LIKE 'F19%' THEN 'Other SUD (F12-F19)'
    WHEN i.code LIKE 'F90%' THEN 'ADHD (F90)'
    ELSE 'Other'
  END AS dx_category,
  COUNT(DISTINCT d.client_id) AS clients
FROM diagnoses d JOIN icds i ON d.icd_id = i.id
GROUP BY dx_category ORDER BY clients DESC;
```

---

## 7. Service Delivery by Location

| Location | Billcases | Unique Clients |
|----------|-----------|----------------|
| Albuquerque | 3 | 3 |
| Healthy Office | 3 | 2 |
| Santa Fe | 2 | 2 |

---

## 8. Revenue Summary

| Metric | Amount |
|--------|--------|
| Total CCBHC billed (per diem) | $1,250 |
| Total CCBHC paid | $0 |
| Per diem rate | $250/day |
| Per diem days billed | 5 |
| Collection rate | 0% (staging) |

---

## 9. Operational Queries for Production

### Daily CCBHC Dashboard
```sql
SELECT DISTINCT bc.client_id, p.client_number,
  f.procedure_code, f.description, bc.date_of_service
FROM charges ch
JOIN fees f ON ch.fee_id = f.id
JOIN billcases bc ON ch.billcase_id = bc.id
JOIN people p ON p.id = bc.client_id
WHERE f.ccbhc_trigger = 1 AND bc.deleted_at IS NULL
  AND DATE(bc.date_of_service) = CURDATE();
```

### Monthly CCBHC Trend
```sql
SELECT DATE_FORMAT(bc.date_of_service, '%Y-%m') AS month,
  SUM(CASE WHEN f.ccbhc_cap = 1 THEN 1 ELSE 0 END) AS per_diem_charges,
  SUM(CASE WHEN f.ccbhc_trigger = 1 THEN 1 ELSE 0 END) AS trigger_charges,
  COUNT(DISTINCT bc.client_id) AS unique_clients,
  SUM(CASE WHEN f.ccbhc_cap = 1 THEN ch.amount_cents ELSE 0 END) / 100.0 AS per_diem_billed
FROM charges ch
JOIN fees f ON ch.fee_id = f.id
JOIN billcases bc ON ch.billcase_id = bc.id
WHERE (f.ccbhc_trigger = 1 OR f.ccbhc_cap = 1) AND bc.deleted_at IS NULL
GROUP BY month ORDER BY month;
```

### Revenue Leakage: Trigger Without Per Diem
```sql
SELECT DISTINCT t.client_id, p.client_number, t.dos
FROM (
  SELECT DISTINCT bc.client_id, DATE(bc.date_of_service) AS dos
  FROM charges ch JOIN fees f ON ch.fee_id = f.id
  JOIN billcases bc ON ch.billcase_id = bc.id
  WHERE f.ccbhc_trigger = 1 AND bc.deleted_at IS NULL
) t
LEFT JOIN (
  SELECT DISTINCT bc2.client_id, DATE(bc2.date_of_service) AS dos
  FROM charges ch2 JOIN fees f2 ON ch2.fee_id = f2.id
  JOIN billcases bc2 ON ch2.billcase_id = bc2.id
  WHERE f2.procedure_code = 'T1040' AND bc2.deleted_at IS NULL
) pd ON pd.client_id = t.client_id AND pd.dos = t.dos
JOIN people p ON p.id = t.client_id
WHERE pd.client_id IS NULL;
```

### I-SERV Monitoring (Weekly)
```sql
SELECT
  DATE_FORMAT(pe.created_at, '%Y-%u') AS week,
  COUNT(*) AS new_enrollments,
  SUM(CASE WHEN sub.days_to_eval <= 10 THEN 1 ELSE 0 END) AS eval_within_10_days,
  ROUND(AVG(sub.days_to_eval), 1) AS avg_days_to_eval
FROM program_enrollments pe
LEFT JOIN (
  SELECT pe2.id AS pe_id, DATEDIFF(MIN(a.date_time_starts), pe2.created_at) AS days_to_eval
  FROM program_enrollments pe2
  JOIN appointments a ON a.client_id = pe2.client_id
    AND a.date_time_starts >= pe2.created_at
    AND a.deleted_at IS NULL AND a.cancelled_at IS NULL
  GROUP BY pe2.id
  HAVING days_to_eval >= 0
) sub ON sub.pe_id = pe.id
WHERE pe.created_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY week ORDER BY week;
```

### CCBHC vs Non-CCBHC Comparison
```sql
SELECT
  'CCBHC' AS cohort,
  COUNT(DISTINCT a.client_id) AS clients_with_appts,
  COUNT(*) AS total_appts,
  ROUND(SUM(CASE WHEN a.noshow_at IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS noshow_pct
FROM appointments a
WHERE a.deleted_at IS NULL AND a.cancelled_at IS NULL
AND a.client_id IN (
  SELECT DISTINCT bc.client_id FROM charges ch
  JOIN fees f ON ch.fee_id = f.id JOIN billcases bc ON ch.billcase_id = bc.id
  WHERE (f.ccbhc_trigger = 1 OR f.ccbhc_cap = 1) AND bc.deleted_at IS NULL
)
UNION ALL
SELECT 'All Clients', COUNT(DISTINCT client_id), COUNT(*),
  ROUND(SUM(CASE WHEN noshow_at IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 1)
FROM appointments WHERE deleted_at IS NULL AND cancelled_at IS NULL;
```

---

## 10. Gap Analysis & Recommendations

### Required Measure Readiness

| Measure | ID | Data Available | Ready? | Gap |
|---------|----|---------------|--------|-----|
| Time to Services | I-SERV | `program_enrollments` + `appointments` | **Partial** | Need to distinguish "new request" vs enrollment date; crisis response time not tracked |
| Depression Remission | DEP-REM-6 | PHQ-9 forms exist (#250, #277) | **Partial** | PHQ-9 score not in SQL-queryable field; only 6 clients screened vs 123 with dx |
| Depression Screening | CDF-AD/CH | PHQ-9 forms exist | **Partial** | Low completion rate; follow-up plan documentation unclear |
| Alcohol Screening | ASC | AUDIT-C form exists (#393) | **Partial** | Only 1 client screened; brief counseling documentation not linked |
| SDOH Screening | SDOH | **No form exists** | **No** | Need to create SDOH screening form (PRAPARE, AHC HRSN, or custom) |

### Priority Actions

1. **Create SDOH screening form** — This is required and completely missing. Recommend using the [PRAPARE tool](https://www.nachc.org/resource/prapare/) or CMS [AHC HRSN](https://innovation.cms.gov/innovation-models/ahcm) as the base.

2. **Increase PHQ-9 screening rate** — 6 screened vs 123 with depression dx = 4.9% rate. Embed PHQ-9 as a required page in intake and follow-up forms.

3. **Increase AUDIT-C screening rate** — Only 1 client screened. Add AUDIT-C to all intake assessments for clients 18+.

4. **Track PHQ-9 scores in structured data** — Verify whether PHQ-9 total score is stored in a SQL-queryable column (e.g., in `completed_pages` or a dedicated table) or only in MongoDB. If MongoDB-only, consider adding a PostgreSQL/MariaDB column for reporting.

5. **Define crisis response tracking** — I-SERV requires crisis response time measurement. Currently no structured field tracks time-from-crisis-call-to-response.

6. **Set up PEC/YFEC survey workflow** — Patient/family experience surveys are state-collected but require a survey tool (e.g., MHSIP, YSS-F). No survey infrastructure detected in Bear.

7. **Configure CCBHC NPI** — Plan #33 (BCBS CCBHC) has `ccbhc_npi = NULL`. This is needed for claims submission under the CCBHC PPS.

### Data Infrastructure Notes

| Need | Current State | Recommendation |
|------|--------------|----------------|
| PHQ-9 scores | Likely in MongoDB `med_assessments` or `completed_pages` | Add MariaDB column or reporting view |
| AUDIT-C scores | In `completed_pages` via form #393 | Same as above |
| Crisis call timestamps | Not tracked | Add `crisis_contact_at` to program_enrollments or new table |
| SDOH responses | No form exists | Create form + ensure structured data capture |
| PEC/YFEC surveys | No survey tool | Integrate external survey (SurveyMonkey, Qualtrics) or build in Bear |
