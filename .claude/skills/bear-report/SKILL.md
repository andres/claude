---
name: bear-report
description: Generate formatted reports from Bear EHR data. Use when asked to create a report, build a dashboard, generate a summary, produce compliance documentation, or export findings about clients, billing, clinical, CCBHC, or operational data.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob
---

# Bear EHR Report Generator

Generate structured, professional markdown reports from the Bear EHR database.

## Data Sources

- **Database:** Bear MariaDB via MCP tools (`mcp__bear-db__execute_query`, `mcp__bear-db__get_table_info`)
- **Schema docs:** `/home/andres/code/claude/semantic/` (00-15 domain files)
- **Existing reports:** `/home/andres/code/claude/semantic/reports/` for reference format

## Report Workflow

1. **Clarify scope** — Ask what the report should cover (time range, programs, payors, etc.) if not specified
2. **Read semantic layer** — Load the relevant domain files before querying
3. **Query data** — Run all needed queries, verify columns with `get_table_info` when unsure
4. **Build report** — Structure as a professional markdown document
5. **Save report** — Write to `/home/andres/code/claude/semantic/reports/<report_name>.md`
6. **Offer PDF** — Ask if the user wants a PDF version

## Report Format

Every report must follow this structure:

```markdown
# Report Title — Bear EHR

> Generated: YYYY-MM-DD
> Data source: Bear staging/production DB (MariaDB)
> Period: [time range or "all time"]

---

## Table of Contents
[numbered list of sections]

---

## 1. Executive Summary
[3-5 bullet points with the most important findings]

## 2-N. Detail Sections
[tables, charts (ASCII if needed), analysis]

## N+1. Gap Analysis & Recommendations (if applicable)
[actionable items with priority]
```

## Report Types

### Clinical / Compliance Reports
- **CCBHC Quality Measures** — SAMHSA-aligned, see `reports/ccbhc_report.md` for reference format
- **Screening Completion Rates** — PHQ-9, AUDIT-C, SDOH, C-SSRS coverage
- **Suicide Risk Summary** — C-SSRS data, risk assessments, high-risk flags
- **Vitals Summary** — BP monitoring, BMI tracking, metabolic screening

### Financial Reports
- **Revenue by Procedure** — CPT codes, billed vs paid, collection rates
- **Payor Mix** — Insurance distribution, self-pay ratio
- **Aging / AR Report** — Outstanding balances by age bucket
- **CCBHC Per Diem Billing** — Trigger services, T1040 rollups, revenue leakage

### Operational Reports
- **Appointment Analytics** — Volume, no-show rates, cancellation reasons
- **Provider Productivity** — Visits per provider, billing per provider
- **Program Enrollment** — Census by program, enrollment trends
- **Insurance Card Compliance** — Policies missing card images

### Demographic Reports
- **Client Demographics** — Age, sex, location distribution
- **Diagnosis Mix** — ICD-10 categories, prevalence
- **Program Demographics** — Client profiles per program

## Query Rules

Follow all rules from the bear-query skill:

- **MariaDB syntax** — `CASE WHEN`, `CURDATE()`, `TIMESTAMPDIFF()`, `DATE_FORMAT()`
- **Soft deletes** — Always filter `deleted_at IS NULL`
- **Money** — `*_cents / 100.0` for dollar amounts
- **Names** — Join `names` table via `person_id`, get latest with `MAX(id)`
- **Staff names** — Join through `people` (polymorphic `identifiable_type = 'User'`) then `names`
- **STI** — `people.type = 'Client'`, `companies.type = 'Payor'`
- **Appointments** — Derive status from timestamps, no `status` column
- **Verify columns** — Use `get_table_info` before querying unfamiliar tables

## Formatting Rules

- Use markdown tables for all data displays
- Bold key metrics and totals
- Include SQL queries in collapsible sections or code blocks for reproducibility
- Add context/benchmarks where possible (e.g., "industry average no-show rate is 10-20%")
- Flag data quality issues explicitly
- Use `**$0**` formatting for dollar amounts
- Round percentages to 1 decimal place

## PDF Conversion

When the user wants PDF output:

```bash
md-to-pdf --launch-options '{"args":["--no-sandbox"]}' /home/andres/code/claude/semantic/reports/<filename>.md
```

$ARGUMENTS
