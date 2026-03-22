# EMR-Bear + GSVLabs Scribe Integration Specification

## Overview

EMR-Bear integrates GSVLabs AI Medical Scribe as a per-agency feature. Bear handles all UI (recording, review, editing). Communication with GSVLabs is **API-only** (no widget). Audio is captured in the browser and uploaded server-side. Processing is **background** — clinician submits audio and continues working; Bear receives the result via webhook callback.

## Concept Mapping

| GSVLabs | EMR-Bear | Notes |
|---------|----------|-------|
| Partner | EMR-Bear (platform) | Single partner account for all of Bear |
| Customer | Agency | One GSVLabs customer per Bear agency |
| Provider | User (staff/clinician) | Linked via `external_id` = Bear `users.id` |
| Patient | Client | Linked via `external_id` = Bear `people.id` (type=Client) |
| Encounter | Encounter | Linked via `external_id` = Bear `encounters.id` |

---

## 1. Agency Onboarding

When a Bear agency enables Scribe, Bear:

1. Uses the agency subdomain as the `client_id` (unique per agency) and generates a `client_secret`
2. Creates a GSVLabs customer via their API, providing those credentials
3. Stores the GSVLabs customer ID and config locally

### 1A. Create Customer Request

`POST /partners/{bear_partner_id}/customers`
`x-api-key: {bear_partner_api_key}`

```json
{
  "name": "Springfield Behavioral Health",
  "external_id": "bear-agency-1234",
  "contact_email": "admin@springfield-bh.com",
  "contact_phone": "555-0100",
  "address": "123 Main St, Springfield, IL 62701",
  "encounter_enabled": true,
  "dictation_enabled": true,
  "retain_audio": false,
  "retain_transcript": false,
  "qa_enabled": false,
  "integration": {
    "ehr_type": "emr_bear",
    "credentials": {
      "client_id": "springfield",
      "client_secret": "sk_live_a7b3c9d2e4f6..."
    },
    "callback_url": "https://springfield.emrbear.com/api/gsv/v1/webhooks",
    "auto_push_on_finalize": true
  }
}
```

> **Requirement for GSVLabs:** The `callback_url` field is a new field we need added to the integration config. GSVLabs must POST all webhook events for this customer to this URL.

### 1B. Expected Response

```json
{
  "id": "gsv-customer-uuid",
  "partner_id": "bear-partner-uuid",
  "external_id": "bear-agency-1234",
  "name": "Springfield Behavioral Health",
  "status": "active",
  "encounter_enabled": true,
  "dictation_enabled": true,
  "retain_audio": false,
  "retain_transcript": false,
  "qa_enabled": false,
  "integration": {
    "id": "ehr-config-uuid",
    "ehr_type": "emr_bear",
    "is_active": true,
    "has_credentials": true,
    "auto_push_on_finalize": true
  },
  "created_at": "2026-03-17T10:30:00Z",
  "updated_at": "2026-03-17T10:30:00Z"
}
```

### 1C. What Bear Stores Per Agency

```json
{
  "agency_id": 1234,
  "agency_subdomain": "springfield",
  "gsv_customer_id": "gsv-customer-uuid",
  "gsv_customer_external_id": "bear-agency-1234",
  "gsv_client_id": "springfield",
  "gsv_client_secret_encrypted": "encrypted_blob...",
  "gsv_webhook_url": "https://springfield.emrbear.com/api/gsv/v1/webhooks",
  "gsv_status": "active",
  "scribe_enabled": true,
  "created_at": "2026-03-17T00:00:00Z",
  "updated_at": "2026-03-17T00:00:00Z"
}
```

---

## 2. Encounter Flow (End-to-End)

```
1. Clinician opens encounter in Bear UI, clicks "Start Scribe"
   |
2. Bear creates encounter on GSVLabs (server-to-server)
   POST /partners/{pid}/encounters
   |
3. Bear UI records audio in browser (default browser format, typically webm)
   |
4. Clinician stops recording. Bear uploads audio to GSVLabs with background_processing=true
   POST /partners/{pid}/encounters/{eid}/audio
   (backend: "pyannote", background_processing: true)
   |
5. Clinician continues working (does not wait)
   |
6. GSVLabs transcribes audio (with speaker diarization) + generates DAP note
   |
7. GSVLabs POSTs full result to Bear's callback URL:
   POST https://{subdomain}.emrbear.com/api/gsv/v1/webhooks
   (payload includes encounter + provider + patient + note + transcript)
   |
8. Bear notifies clinician: "Scribe note ready for review"
   Clinician reviews/edits DAP note in Bear UI
   |
10. Clinician approves. Bear finalizes on GSVLabs:
    POST /partners/{pid}/encounters/{eid}/soap/finalize
    { data, assessment, plan }
    |
11. Done. Bear stores final note internally.
```

---

## 3. API Calls Bear Makes to GSVLabs

### 3A. Create Encounter

`POST /partners/{bear_partner_id}/encounters`
`x-api-key: {bear_partner_api_key}`

```json
{
  "customer_id": "gsv-customer-uuid",
  "encounter_type": "patient_encounter",
  "provider": {
    "external_id": "4567",
    "name": "Dr. Jane Smith",
    "email": "jane.smith@springfield-bh.com",
    "npi": "1234567890"
  },
  "patient": {
    "external_id": "8901",
    "name": "John Doe",
    "date_of_birth": "1960-01-15",
    "sex": "M",
    "mrn": "MRN-8901"
  },
  "appointment_external_id": "appt-56789",
  "note_type_id": "{dap_note_type_uuid}",
  "metadata": {
    "bear_encounter_id": 56789,
    "program": "Outpatient Behavioral Health",
    "location": "Springfield Main Office"
  }
}
```

**Response:**
```json
{
  "id": "gsv-encounter-uuid",
  "partner_id": "bear-partner-uuid",
  "customer_id": "gsv-customer-uuid",
  "status": "CREATED",
  "encounter_type": "patient_encounter",
  "created_at": "2026-03-17T14:00:00Z"
}
```

### 3B. Upload Audio

`POST /partners/{bear_partner_id}/encounters/{gsv_encounter_id}/audio`
`Content-Type: multipart/form-data`
`x-api-key: {bear_partner_api_key}`

| Field | Value | Notes |
|-------|-------|-------|
| `audio` | (binary file) | `audio/webm` (browser default via MediaRecorder API) |
| `backend` | `"pyannote"` | Speaker diarization enabled |
| `parallel` | `true` | Transcription + diarization in parallel |
| `background_processing` | `true` | Non-blocking; result via webhook |
| `note_type_id` | `"{dap_note_type_uuid}"` | Specifies DAP note format for this recording |

**Response:**
```json
{
  "message": "Audio uploaded successfully. Transcription in progress.",
  "audio": {
    "id": "recording-uuid",
    "encounter_id": "gsv-encounter-uuid",
    "file_size_bytes": 2456789,
    "mime_type": "audio/webm"
  },
  "status": "PROCESSING_TRANSCRIPT"
}
```

### 3B-alt. Chunked Audio Upload (for long recordings)

For long sessions (e.g., 1-hour calls), uploading a single large file at the end is risky — the upload could fail or time out. Instead, Bear can stream audio chunks during the recording and trigger note generation after the last chunk.

This uses GSVLabs' live transcription chunked endpoint. Bear sends chunks silently in the background (the clinician does not need to see partial transcripts).

**Prerequisite:** `live_transcription.enabled = true` at the partner level.

#### Flow

```
1. Clinician starts recording in Bear UI
   |
2. Bear creates encounter on GSVLabs (same as 3A)
   POST /partners/{pid}/encounters
   |
3. Bear sends audio chunks every ~5 seconds as recording progresses
   POST /partners/{pid}/encounters/{eid}/audio/chunk  (repeated)
   |
4. Clinician stops recording. Bear sends final chunk.
   |
5. Bear triggers note generation
   POST /partners/{pid}/encounters/{eid}/soap
   { "note_type_id": "{dap_note_type_uuid}" }
   |
6. GSVLabs generates DAP note from accumulated transcript
   |
7. GSVLabs POSTs result to Bear's callback URL (same payload as Section 4A)
   |
8. Clinician reviews, edits, finalizes (same as standard flow)
```

#### Chunk Upload Request

`POST /partners/{bear_partner_id}/encounters/{gsv_encounter_id}/audio/chunk`
`Content-Type: multipart/form-data`
`x-api-key: {bear_partner_api_key}`

| Field | Value | Notes |
|-------|-------|-------|
| `audio` | (binary chunk) | `audio/webm` chunk from MediaRecorder |

**Response:**
```json
{
  "message": "Audio chunk transcribed",
  "status": "completed",
  "partial_transcript": {
    "encounter_id": "gsv-encounter-uuid",
    "segments": [
      {
        "text": "How have you been feeling since our last session?",
        "speaker": "provider",
        "start_ms": 500,
        "end_ms": 3200,
        "confidence": 0.95
      }
    ],
    "full_text": "How have you been feeling since our last session?",
    "is_provisional": true
  }
}
```

Bear can discard the `partial_transcript` response if not showing live transcription to the clinician. The important thing is the audio is received by GSVLabs incrementally.

#### Trigger Note Generation

After the last chunk, Bear explicitly triggers note generation:

`POST /partners/{bear_partner_id}/encounters/{gsv_encounter_id}/soap`
`x-api-key: {bear_partner_api_key}`

```json
{
  "note_type_id": "{dap_note_type_uuid}"
}
```

**Response:**
```json
{
  "message": "Note generation started"
}
```

GSVLabs then POSTs the result to the `callback_url` (same as Section 4A).

#### When to use which approach

| Scenario | Approach | Why |
|----------|----------|-----|
| Short sessions (< 15 min) | 3B. Single upload | Simpler, one request |
| Long sessions (15+ min) | 3B-alt. Chunked | Avoids large upload risk, progressive upload |
| Unreliable network | 3B-alt. Chunked | Smaller payloads, incremental progress |

### 3C. Fetch Note (after webhook notification)

`GET /partners/{bear_partner_id}/encounters/{gsv_encounter_id}/soap`
`x-api-key: {bear_partner_api_key}`

**Response:**
```json
{
  "id": "gsv-note-uuid",
  "encounter_id": "gsv-encounter-uuid",
  "status": "DRAFT",
  "data": "Patient reports increasing anxiety over the past 2 weeks. Appears alert and oriented x3. Affect is constricted...",
  "assessment": "Generalized anxiety disorder, worsening. Current SSRI may need adjustment...",
  "plan": "1. Increase sertraline to 100mg daily\n2. Continue weekly CBT sessions\n3. Follow up in 2 weeks\n4. PHQ-9 and GAD-7 at next visit",
  "note": "Full combined note text..."
}
```

### 3D. Finalize Note

`POST /partners/{bear_partner_id}/encounters/{gsv_encounter_id}/soap/finalize`
`x-api-key: {bear_partner_api_key}`

```json
{
  "data": "Patient reports increasing anxiety over the past 2 weeks. Sleep has worsened. Appears alert and oriented x3. Affect is constricted. No SI/HI...",
  "assessment": "Generalized anxiety disorder, worsening. Current SSRI may need adjustment...",
  "plan": "1. Increase sertraline to 100mg daily\n2. Continue weekly CBT sessions\n3. Follow up in 2 weeks\n4. PHQ-9 and GAD-7 at next visit"
}
```

**Response:**
```json
{
  "id": "gsv-note-uuid",
  "status": "FINALIZED",
  "finalized_at": "2026-03-17T14:45:00Z"
}
```

### 3E. Retry Transcription (on error)

`POST /partners/{bear_partner_id}/encounters/{gsv_encounter_id}/transcript/retry`
`x-api-key: {bear_partner_api_key}`

```json
{
  "backend": "pyannote",
  "parallel": true
}
```

### 3F. Get Note Types (one-time or cached)

`GET /partners/{bear_partner_id}/note-types`
`x-api-key: {bear_partner_api_key}`

Bear fetches available note types and allows the agency to select which type to use. This is supplied as `note_type_id` when creating encounters.

---

## 4. Webhook Callback — Payload We Require GSVLabs to POST

> **This is the JSON structure we are defining for GSVLabs to implement.** When processing completes, GSVLabs must POST this payload to the agency's `callback_url`.

### Endpoint

```
POST https://{agency-subdomain}.emrbear.com/api/gsv/v1/webhooks
```

### Headers

```
Content-Type: application/json
X-GSV-Client-Id: {client_id}
X-GSV-Client-Secret: {client_secret}
```

### 4A. Result Payload (note ready)

This is the primary payload — sent when the DAP note is ready after background processing. Modeled after GSVLabs' own `GET /encounters/{id}/soap` response, enriched with encounter context.

```json
{
  "event": "note.draft_ready",
  "timestamp": "2026-03-17T14:35:00Z",
  "encounter": {
    "id": "gsv-encounter-uuid",
    "status": "DAP_DRAFT_READY",
    "encounter_type": "patient_encounter",
    "created_at": "2026-03-17T14:00:00Z",
    "updated_at": "2026-03-17T14:35:00Z"
  },
  "provider": {
    "external_id": "4567",
    "name": "Dr. Jane Smith",
    "npi": "1234567890"
  },
  "patient": {
    "external_id": "8901",
    "name": "John Doe",
    "date_of_birth": "1960-01-15",
    "sex": "M",
    "mrn": "MRN-8901"
  },
  "note": {
    "id": "gsv-note-uuid",
    "status": "DRAFT",
    "note_type_id": "note-type-uuid",
    "note_type_name": "DAP Note",
    "data": "Patient reports increasing anxiety over the past 2 weeks. Sleep has worsened, averaging 4 hours per night. Denies SI/HI. Appears alert and oriented x3. Affect is constricted. Speech is normal rate and rhythm. No psychomotor agitation...",
    "assessment": "Generalized anxiety disorder, worsening. Current SSRI may need adjustment. Sleep disturbance secondary to anxiety...",
    "plan": "1. Increase sertraline to 100mg daily\n2. Continue weekly CBT sessions\n3. Follow up in 2 weeks\n4. PHQ-9 and GAD-7 at next visit"
  },
  "transcript": {
    "id": "gsv-transcript-uuid",
    "status": "COMPLETED",
    "segments": [
      {
        "text": "How have you been feeling since our last session?",
        "speaker": "provider",
        "start_ms": 500,
        "end_ms": 3200,
        "confidence": 0.95
      },
      {
        "text": "The anxiety has been getting worse, especially at night.",
        "speaker": "patient",
        "start_ms": 3500,
        "end_ms": 6800,
        "confidence": 0.93
      }
    ]
  },
  "metadata": {
    "bear_encounter_id": 56789,
    "program": "Outpatient Behavioral Health",
    "location": "Springfield Main Office"
  }
}
```

**Key points:**
- `provider.external_id` and `patient.external_id` are Bear IDs we sent at encounter creation — echoed back so we can resolve internally
- `metadata` is the same object we sent at encounter creation — echoed back as-is
- `note` contains the full DAP content so we don't need a separate GET call
- `transcript.segments` includes speaker diarization (provider vs patient)

### 4B. Error Payload

Same structure, echoing back all identifiers and metadata:


```json
{
  "event": "encounter.error",
  "timestamp": "2026-03-17T14:31:00Z",
  "encounter": {
    "id": "gsv-encounter-uuid",
    "status": "ERROR",
    "created_at": "2026-03-17T14:00:00Z",
    "updated_at": "2026-03-17T14:31:00Z"
  },
  "provider": {
    "external_id": "4567",
    "name": "Dr. Jane Smith"
  },
  "patient": {
    "external_id": "8901",
    "name": "John Doe"
  },
  "error": {
    "code": "PROCESSING_ERROR",
    "message": "Transcription failed due to poor audio quality"
  },
  "metadata": {
    "bear_encounter_id": 56789,
    "program": "Outpatient Behavioral Health",
    "location": "Springfield Main Office"
  }
}
```

### 4C. Finalized Payload (`auto_push_on_finalize`)

When `auto_push_on_finalize` is `true` and the clinician finalizes a note (either via Bear calling `/soap/finalize` or directly in GSVLabs), GSVLabs POSTs the finalized result to the same `callback_url`. This is the same webhook mechanism, with the final note content:

```json
{
  "event": "note.finalized",
  "timestamp": "2026-03-17T14:45:00Z",
  "encounter": {
    "id": "gsv-encounter-uuid",
    "status": "FINALIZED",
    "encounter_type": "patient_encounter",
    "created_at": "2026-03-17T14:00:00Z",
    "updated_at": "2026-03-17T14:45:00Z"
  },
  "provider": {
    "external_id": "4567",
    "name": "Dr. Jane Smith",
    "npi": "1234567890"
  },
  "patient": {
    "external_id": "8901",
    "name": "John Doe",
    "date_of_birth": "1960-01-15",
    "sex": "M",
    "mrn": "MRN-8901"
  },
  "note": {
    "id": "gsv-note-uuid",
    "status": "FINALIZED",
    "note_type_id": "note-type-uuid",
    "note_type_name": "DAP Note",
    "finalized_at": "2026-03-17T14:45:00Z",
    "data": "Patient reports increasing anxiety over the past 2 weeks. Sleep has worsened, averaging 4 hours per night. Denies SI/HI. Appears alert and oriented x3. Affect is constricted. Speech is normal rate and rhythm. No psychomotor agitation...",
    "assessment": "Generalized anxiety disorder, worsening. Current SSRI may need adjustment. Sleep disturbance secondary to anxiety...",
    "plan": "1. Increase sertraline to 100mg daily\n2. Continue weekly CBT sessions\n3. Follow up in 2 weeks\n4. PHQ-9 and GAD-7 at next visit"
  },
  "transcript": {
    "id": "gsv-transcript-uuid",
    "status": "COMPLETED",
    "segments": [
      {
        "text": "How have you been feeling since our last session?",
        "speaker": "provider",
        "start_ms": 500,
        "end_ms": 3200,
        "confidence": 0.95
      },
      {
        "text": "The anxiety has been getting worse, especially at night.",
        "speaker": "patient",
        "start_ms": 3500,
        "end_ms": 6800,
        "confidence": 0.93
      }
    ]
  },
  "metadata": {
    "bear_encounter_id": 56789,
    "program": "Outpatient Behavioral Health",
    "location": "Springfield Main Office"
  }
}
```

### 4D. Bear's Response

```
HTTP 200 OK

{
  "status": "received"
}
```

### 4E. Retry Policy

On non-2xx response, GSVLabs retries up to **4 times** with exponential backoff:

| Retry | Delay |
|-------|-------|
| 1st | 1 minute |
| 2nd | 2 minutes |
| 3rd | 4 minutes |
| 4th | 8 minutes |

After 4 failed retries, GSVLabs should mark the delivery as failed. Bear can retrieve the result manually via `GET /partners/{pid}/encounters/{eid}/soap` as a fallback.

---

## 5. Authentication Summary

| Direction | Method | Details |
|-----------|--------|---------|
| Bear → GSVLabs | API key | `x-api-key` header with partner-level API key |
| GSVLabs → Bear | Headers | `X-GSV-Client-Id` + `X-GSV-Client-Secret` headers using the credentials Bear provided at customer creation. |

---

## 6. What We Need GSVLabs to Implement

1. **`callback_url` field on customer creation** — Add support for a `callback_url` in the integration config. GSVLabs must POST all event payloads (draft ready, finalized, error) to this URL per customer.
2. **Webhook payloads** — POST the full result payloads as defined in Section 4 (encounter + provider + patient + note + transcript + metadata). Three event types: `note.draft_ready` (4A), `encounter.error` (4B), `note.finalized` (4C). We don't want to make a separate GET call.
3. **Echo back `external_id` and `metadata`** — The `provider.external_id`, `patient.external_id`, and `metadata` object we send at encounter creation must be included in every webhook payload so we can resolve records on our side.
4. **Authentication headers** — Include `X-GSV-Client-Id` and `X-GSV-Client-Secret` headers when posting to our webhook, using the credentials we provide at customer creation.
5. **`ehr_type: "emr_bear"`** — Register a new EHR type for Bear.
6. **`note_type_id` on audio upload** — Accept `note_type_id` as a field on the audio upload endpoint so we can specify DAP (or other note types) per recording.
7. **Retry policy** — On non-2xx response from our webhook, retry 4 times with exponential backoff: 1 min, 2 min, 4 min, 8 min.

## 7. Open Questions for GSVLabs

1. **Environments** — Staging base URL is `scribe-staging.gsvlabs.ai`. What is the production base URL?
2. **Audio size/duration limits** — Any max file size or recording duration for `audio/webm` uploads?
