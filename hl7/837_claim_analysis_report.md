# 837P Claim File Analysis Report

**Date:** March 24, 2026
**Prepared For:** Helping Hand Behavioral Health
**Subject:** Clearinghouse Rejection Analysis — Claim EB4

---

## 1. Overview

An 837 Professional (837P) claim file submitted to clearinghouse CLAIM.MD (Receiver ID: 855757606) was returned with errors. This report documents a segment-by-segment analysis of the file, identifies formatting and data errors, and provides recommended corrections.

**Claim Summary:**

| Field | Value |
|---|---|
| Patient Control # | EB4 |
| Subscriber | DOE, JANE |
| Payer | Aetna Better Health of New Jersey (Medicaid) |
| Billing Provider | Helping Hand Behavioral Health |
| Billing Provider NPI | 1568512010 |
| Service Date | 03/18/2026 |
| Procedure Code | H0035 — Mental Health Partial Hospitalization |
| Total Charge | $104.40 (5 units) |
| Diagnosis | F20.0 — Paranoid Schizophrenia |

---

## 2. Issues Found

### 2.1 CRITICAL — GS02: Application Sender Code is a Placeholder

**Segment:**
```
GS*HC*NEEDS CODE*MD*20260324*1128*177436613*X*005010X222A1~
```

**Problem:** GS02 (Application Sender's Code) contains the literal text `NEEDS CODE`. This is a placeholder value and is not a valid sender identifier. The clearinghouse will reject the file at the envelope level before even parsing the claim content.

**Fix:** Replace `NEEDS CODE` with the assigned application sender code provided by the clearinghouse or trading partner agreement.

---

### 2.2 CRITICAL — NM1\*82: Rendering Provider Name Format Invalid

**Segment:**
```
NM1*82*1*HHB*HELPING HAND BEHAVIORAL HEALTH****XX*1568512010~
```

**Problem:** The entity type qualifier is `1` (Person), but the name fields contain what appears to be an organization name. In NM1 segments with entity type `1`:
- NM103 = Last Name
- NM104 = First Name

Currently NM103 = `HHB` and NM104 = `HELPING HAND BEHAVIORAL HEALTH`, which is not a valid individual name.

**Fix (Option A):** If the rendering provider is an individual clinician, replace with their actual name:
```
NM1*82*1*LASTNAME*FIRSTNAME****XX*INDIVIDUAL_NPI~
```

**Fix (Option B):** If the rendering provider is the organization itself, change entity type to `2`:
```
NM1*82*2*HELPING HAND BEHAVIORAL HEALTH*****XX*1568512010~
```

> **Note:** Most payers require the rendering provider to be an individual (type `1`) with their personal NPI for behavioral health services.

---

### 2.3 HIGH — ISA15: Interchange Set to Test Mode

**Segment:**
```
ISA*00*          *00*          *ZZ*223342993      *ZZ*855757606      *260324*1128*^*00501*177436613*0*T*:~
```

**Problem:** ISA15 = `T` (Test). Production submissions must use `P` (Production). Some clearinghouses will accept test files but route them to a test environment and never forward them to the payer, or will reject them outright.

**Fix:** Change ISA15 from `T` to `P` for production submissions.

---

### 2.4 HIGH — N4 (Subscriber): City/Zip Code Mismatch

**Segment:**
```
N4*CLAYTON*NJ*07504~
```

**Problem:** The subscriber city is listed as `CLAYTON, NJ`, but zip code `07504` corresponds to Paterson, NJ. The correct zip code for Clayton, NJ is `08312`.

This mismatch can cause the claim to fail payer address validation or subscriber eligibility matching.

**Fix:** Verify the subscriber's address and correct either the city or the zip code:
- If the subscriber lives in Clayton, NJ: change zip to `08312` (or `083121500` with +4)
- If the subscriber lives in Paterson, NJ (07504): change city to `PATERSON`

---

### 2.5 MEDIUM — CLM05: Facility Type Code May Be Incorrect

**Segment:**
```
CLM*EB4*104.4***53:B:1*Y*A*Y*Y~
```

**Problem:** Place of Service code `53` designates a Community Mental Health Center (CMHC). If Helping Hand Behavioral Health is not certified as a CMHC, this code is incorrect and may cause the claim to deny at the payer level.

**Common alternatives:**
| Code | Description |
|---|---|
| 11 | Office |
| 12 | Home |
| 53 | Community Mental Health Center |
| 57 | Non-residential Substance Abuse Treatment Facility |

**Fix:** Verify the provider's facility type classification and use the appropriate code.

---

### 2.6 VERIFY — NM1\*IL: Subscriber Member ID Length

**Segment:**
```
NM1*IL*1*DOE*JANE****MI*012345678911~
```

**Problem:** The Medicaid member ID `012345678911` is 12 digits. Aetna Better Health of NJ Medicaid IDs are typically 10–11 characters. An incorrect member ID will result in a subscriber not found / eligibility denial.

**Action:** Confirm the member ID is correct per the subscriber's Medicaid card or eligibility verification response.

---

### 2.7 VERIFY — NM1\*PR: Payer ID

**Segment:**
```
NM1*PR*2*AETNA BETTER HEALTH OF NEW JERSEY*****PI*46320~
```

**Action:** Confirm that payer ID `46320` is the correct electronic payer ID for Aetna Better Health of New Jersey at your clearinghouse (CLAIM.MD). Payer IDs can vary by clearinghouse.

---

## 3. Segments With No Issues Detected

| Segment | Description | Status |
|---|---|---|
| ST / BHT | Transaction Set Header | OK |
| NM1\*41 | Submitter Name | OK |
| NM1\*40 | Receiver Name | OK |
| NM1\*85 / N3 / N4 / REF | Billing Provider | OK (verify zip +4) |
| SBR | Subscriber Information | OK |
| DMG | Subscriber Demographics | OK |
| HI | Diagnosis Code (F20.0) | OK — valid ICD-10 |
| NM1\*77 / N3 / N4 | Service Facility Location | OK |
| LX / SV1 / DTP | Service Line Detail | OK |
| REF\*6R | Line Item Control Number | OK |
| SE / GE / IEA | Trailer Segments | OK |

---

## 4. Recommended Action Plan

1. **Immediately fix** GS02 — replace `NEEDS CODE` with the correct sender code
2. **Immediately fix** NM1\*82 — use the individual rendering provider's name and NPI, or correct entity type
3. **Change** ISA15 from `T` to `P` for production
4. **Correct** subscriber zip code (`07504` should likely be `08312` for Clayton, NJ)
5. **Verify** facility type code `53` is appropriate for the provider
6. **Verify** member ID and payer ID with the payer or through eligibility check
7. **Resubmit** the corrected claim file

---

*Report generated on March 24, 2026 — Helping Hand Behavioral Health 837P Claim Review*
