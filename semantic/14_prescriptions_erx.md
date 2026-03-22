# Domain 14: Electronic Prescribing (Prex)

## Overview
Surescripts-integrated electronic prescribing (eRx) module.
Manages prescriptions, pharmacies, drugs, eligibility, EPCS (Electronic Prescribing
for Controlled Substances), and medication history retrieval.

**Table prefix:** `prex_`

## Tables

### `prex_prescriptions`
Electronic prescription records.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `user_id` | integer | FK to users (prescriber) |
| `client_id` | integer | FK to people (Client) |

---

### `prex_pharmacies`
Pharmacy directory.

---

### `prex_drugs`
Drug database / formulary.

---

### `prex_eligibilities`
Patient eligibility for eRx.

---

### `prex_provider_locations`
Provider-to-location mapping for eRx.

| Column | Type | Notes |
|--------|------|-------|
| `user_id` | integer | FK to users |
| `location_id` | integer | FK to locations |

---

### Other Prex Tables

| Table | Description |
|-------|-------------|
| `prex_configuration_parameters` | eRx system config |
| `prex_consents` | Patient consent for eRx |
| `prex_consent_signatures` | Consent signature records |
| `prex_crypto_keys` | EPCS cryptographic keys |
| `prex_directions` | Sig directions |
| `prex_discontinuation_requests` | Rx discontinuation |
| `prex_drugable_drugs` | Drug-to-formulary mapping |
| `prex_drugable_drug_status_logs` | Drug status audit |
| `prex_epcs_accesses` | EPCS access management |
| `prex_error_logs` | Integration error log |
| `prex_identities` | Provider identity for eRx |
| `prex_loggers` | Transaction logging |
| `prex_medication_histories` | Medication history pulls |
| `prex_medication_history_logs` | History pull audit |
| `prex_medication_history_requests` | History requests |
| `prex_medication_history_request_logs` | Request audit |
| `prex_medication_migration_statuses` | Migration tracking |
| `prex_periods` | Prescription periods |
| `prex_pharmacable_pharmacies` | Active pharmacy mapping |
| `prex_pharmacable_pharmacy_logs` | Pharmacy audit |
| `prex_pharmacy_versions` | Pharmacy data versions |
| `prex_prescriber_auxiliaries` | Auxiliary prescriber staff |
| `prex_prescription_allergies` | Allergy checking |
| `prex_prescription_consents` | Per-Rx consent |
| `prex_repeated_prescription_groups` | Recurring Rx groups |
| `prex_rx_histories` | Rx history records |
| `prex_rxnorms` | RxNorm drug coding |
| `prex_saaspass_auths` | 2FA for EPCS |
| `prex_service_levels` | Service tier management |
| `prex_surescript_messages` | Surescripts message log |
| `prex_surescript_message_archive_logs` | Message archive |
| `prex_user_prescription_auths` | User Rx authorization |
| `prex_verifies` | Verification records |
| `prex_vitals` | Vitals for Rx context |
| `prex_rx_rule_ingredients` | Drug interaction rules |
| `prex_client_settings` | Per-client eRx settings |

---

## Entity Relationship Summary

```
prex_prescriptions
  ├── N:1 user (prescriber)
  ├── N:1 client (people)
  ├── → prex_drugs (medication)
  ├── → prex_pharmacies (destination)
  └── → prex_directions (sig)

prex_provider_locations
  ├── N:1 user
  └── N:1 location
```
