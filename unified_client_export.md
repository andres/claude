# Unified Client Export System

## Background

We have several overlapping export implementations scattered across the codebase. This ticket consolidates them into a single shell-executable solution under `app/lib/export/clients/`.

Existing files reviewed — do not reuse directly, but use as reference for logic and patterns:

| File | What to take from it |
|------|----------------------|
| `lib/utilities/export.rb` | **Primary reference** — most complete implementation; covers all document types, demographics, billing documents, statements, collaterals, TFC |
| `app/lib/modules/reports/clients/export/client_information.rb` | CSV field list and row-building logic (`ToRow`, `CommonMethods`) |
| `lib/exporter/client_exporter_bis.rb` | Adds `email` field to CSV, log file pattern |
| `lib/exporter/client_exporter.rb` | Log append pattern (`write_log`, per-client entries) |
| `lib/utilities/export_client_files.rb` | Per-client folder naming convention |
| `app/lib/modules/reports/external/data_export.rb` | Confirms collaterals and donesigforms as document sources |

---

## Usage (Rails console / shell)

```ruby
load 'app/lib/export/clients/bundle.rb'

# All clients
Export::Clients::Bundle.run(destination: '/export/2026-03-06')

# Specific clients
Export::Clients::Bundle.run(destination: '/export/2026-03-06', client_ids: [1, 42, 300])
```

---

## Output Structure

```
/export/2026-03-06/
  export_log.txt
  clients_roster_2026-03-06.csv
  files/
    00042_Smith_John_1985-04-12/
      demographics.txt
      encounters/
      signature_forms/
      prescriptions/
      medication_consents/
      collaterals/
      billing_documents/
      statements/
      haccess/
      otp/
      tfc/
    00087_Doe_Jane_1990-11-03/
      ...
```

---

## File Structure

```
app/lib/export/
  clients/
    roster.rb     <- Part 1: CSV
    files.rb      <- Part 2: per-client folders
    bundle.rb     <- Part 3: orchestrator
```

---

## Part 1 — `Export::Clients::Roster`

Generates a single CSV file named `clients_roster_YYYY-MM-DD.csv`.

Base the row-building logic on `Modules::Reports::Clients::Export::ClientInformation::ToRow` and `CommonMethods`. Use `find_in_batches` when iterating clients.

**CSV columns** (in order):

- Identity: `legacy_id`, `last_name`, `first_name`, `middle_initial`, `alias`, `preferred`
- Demographics: `race`, `ethnicity`, `language`, `second_language`, `tribe`, `marital`, `gender`, `dob`, `age`, `ssn`
- Contact: `email`, `phone_work`, `phone_work_ext`, `phone_home`, `phone_cell`
- Location: `location`, `street_1`, `street_2`, `city`, `state`, `zip`, `county`, `address_type`
- Diagnoses: `dx_1` through `dx_5`
- Insurance — policy 1: `payor`, `plan`, `policy_number`, `group_number`, `policy_start`, `medicaid`
- Insurance — policy 2: `payor_2`, `plan_2`, `policy_number_2`, `policy_start_2`
- Insurance — policy 3: `payor_3`, `plan_3`, `policy_number_3`, `policy_start_3`
- Insurance — policy 4: `payor_4`, `plan_4`, `policy_number_4`, `policy_start_4`
- Enrollments: `program_1`, `program_2`, `program_3`
- Assignment: `provider_id` (comma-separated assigned staff IDs)

Log each client processed (success or error) to the shared log file.

---

## Part 2 — `Export::Clients::Files`

Creates a folder per client under `{destination}/files/`. Folder name pattern (from `Utilities::Export::Client#client_directory_name`):

```
{LastName_FirstName}_{YYYY-MM-DD}_{client_id}
```

**Always write** a `demographics.txt` file in the client root folder. Content (from `Utilities::Export::Client#demographic_content`):

```
Full name
Date of birth
Sex
SSN
Address(es)
Phone(s)
Email(s)
Relationships
Insurance policies
```

**Then create the following subfolders. Only create a subfolder if there is content to write.**

For all PDF subfolders use the copy pattern from `Utilities::Export::Client#write_printable`:

```ruby
pd.document.copy_to_local_file(:original, File.join(subfolder_path, pd.document_file_name))
```

| Subfolder | Source | Notes |
|-----------|--------|-------|
| `encounters/` | `client.encounter_forms` — each with a `printed_printable` | One PDF per form |
| `signature_forms/` | `client.donesigforms` — each with a `printed_printable` | |
| `prescriptions/` | `client.prescriptions` — each with a `printed_printable` | From `Utilities::Export::Client#write_printed_printables` |
| `medication_consents/` | `client.consents` — each with a `printed_printable` | Medication consent forms |
| `collaterals/` | `client.collaterals` — copy via `collateral.document.copy_to_local_file` | See `Utilities::Export::Client#write_collaterals` |
| `billing_documents/` | `client.billing_documents` — copy via `billing_document.document.copy_to_local_file` | Pre-existing billing docs already attached to client. See `write_billing_documents` |
| `statements/` | Generate a new `ClientStatement` at export time + copy it | See `Utilities::Export::Client#get_client_statement` — creates via `client.client_statements.new(...)`, saves, calls `create_pdf`, then copies |
| `haccess/` | HAccess encounter forms — filter by form type | Verify the correct form type identifier before implementing |
| `otp/` | Orders and dose reports for OTP clients | Verify source models before implementing |
| `tfc/` | `client.tfc_forms` with `printed_printable` (per-client TFC forms) | See `write_printed_printables` in `lib/utilities/export.rb` |

> **Note on TFC homes:** `lib/utilities/export.rb` also exports `Tfc::Home` records separately (not per-client). The per-client `tfc/` folder above covers `client.tfc_forms`. If exporting TFC homes as a separate top-level concern is needed, that is out of scope for this ticket.

---

## Part 3 — `Export::Clients::Bundle`

The entry point. Accepts `destination:` (required) and `client_ids:` (optional, defaults to all non-hidden clients via `Client.not_hidden`).

Responsibilities:

1. Create the destination directory
2. Open the log file at `{destination}/export_log.txt` in append mode
3. Log start time, client count, and destination path
4. Run `Export::Clients::Roster` — log start, completion, or error
5. Run `Export::Clients::Files` for each client — log per-client progress and any errors without halting the full run
6. Log end time and summary (clients processed, files written, errors)

---

## Log File

Append mode, one line per event. Follow the pattern from `Exporter::ClientExporter#write_log`.

```
[2026-03-06 14:00:00] Export started — 432 clients, destination: /export/2026-03-06
[2026-03-06 14:00:01] Roster: started
[2026-03-06 14:01:12] Roster: complete — clients_roster_2026-03-06.csv
[2026-03-06 14:01:13] Files: #42 Smith, John — encounters: 3, signature_forms: 1, prescriptions: 2, collaterals: 1, billing_documents: 0, statements: 1, tfc: 0
[2026-03-06 14:01:14] Files: #87 Doe, Jane — ERROR: <message>
...
[2026-03-06 14:45:00] Export finished — 432 processed, 1 errors
```

---

## Developer Notes

- All paths relative to the `destination` argument — no hardcoded `/export` or `~/reports` paths.
- `roster.rb` and `files.rb` should each accept the log file handle from `Bundle` so all output goes to one log.
- Rescue per-client errors individually — one bad client must not stop the rest.
- `statements/` creates a new `ClientStatement` record in the database as a side effect (that is the existing behavior and is expected).
- **Before implementing `haccess/` and `otp/`:** identify the correct source models and form type identifiers and note them in the PR. Do not guess — check with the team if unclear.
- `Modules::Reports::External::ClientDataExport` (`app/lib/modules/reports/external/client_data_export.rb`) is confirmed dead code — ignore it.
- No UI wiring, no background jobs, no zip file — output is a plain directory.
