# Domain 15: Laboratory Orders & Results

## Overview
Two lab integration systems:
1. **CHC** — Change Healthcare lab integration
2. **Lab History** — Internal lab order/result tracking

**Table prefixes:** `chc_`, `lab_history_`

## CHC Tables

### `chc_orders`
Lab orders sent via Change Healthcare.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `client_id` | integer | FK to people (Client) |
| `user_id` | integer | FK to users |
| `insurance_policy_id` | integer | FK to insurance_policies |

- `has_many :chc_order_items`
- `has_many :chc_results`
- `has_many :chc_order_aoes` (ask-at-order-entry questions)

---

### `chc_order_items`
Individual test items within an order.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `chc_order_id` | integer | FK to chc_orders |

---

### `chc_results`
Lab results received.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |
| `chc_order_id` | integer | FK to chc_orders |

- `has_many :chc_result_documents`

---

### `chc_result_documents`
Result document attachments (PDFs, etc.).

---

### `chc_lab_configurations`
Lab configuration settings.

### `chc_lab_connections`
Lab interface connection settings.

---

## Lab History Tables

### `lab_history_orders`
Internal lab order tracking.

| Column | Type | Notes |
|--------|------|-------|
| `id` | integer | PK |

- `has_many :lab_history_results`
- `has_many :lab_history_lab_tests`

---

### `lab_history_results`
Lab result records.

---

### `lab_history_lab_tests`
Test definitions.

---

### `lab_history_favorites`
Frequently ordered test sets.

---

### `lab_history_external_uploads`
Externally uploaded lab results.

---

## Related Tables

| Table | Description |
|-------|-------------|
| `laboratory_orders` | Legacy lab orders |
| `laboratory_histories` | Legacy lab history |
| `laboratory_specimen` | Specimen tracking |
| `lab_orders` | Another lab order system |
| `common_labs` | Common lab test reference |
| `diagnostic_labs` | Diagnostic lab results |
| `btnx_orders` | BTNX point-of-care testing orders |
| `btnx_panels` | BTNX test panels |
| `btnx_results` | BTNX test results |
| `btnx_result_values` | BTNX result values |
| `btnx_configurations` | BTNX device config |

---

## Entity Relationship Summary

```
CHC Integration:
  chc_orders
    ├── N:1 client (people)
    ├── N:1 user (ordering provider)
    ├── N:1 insurance_policy
    ├── 1:N chc_order_items
    ├── 1:N chc_order_aoes
    └── 1:N chc_results
          └── 1:N chc_result_documents

BTNX Point-of-Care:
  btnx_orders
    └── 1:N btnx_results
          └── 1:N btnx_result_values
```
