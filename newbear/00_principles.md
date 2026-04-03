# 00 — Principles

Non-negotiable design principles for NewBear. Every decision — architecture, feature,
migration, UI — must pass through these filters.

---

## 1. Zero Data Loss

Every record from every production agency must survive migration intact. No "start fresh"
for any agency. If a column existed in legacy Bear, its data lands somewhere in NewBear —
even if the schema changes, even if the feature is redesigned, even if the field is deprecated.

- Legacy data that maps cleanly → migrated to new schema
- Legacy data with no clear home → preserved in a `legacy_` namespace, queryable, linked to the entity it belongs to
- Soft-deleted records → migrated as soft-deleted (don't discard history)
- MongoDB `med_*` clinical documents → migrated to PostgreSQL relational tables with full provenance

**Test:** After migration, any report that ran against legacy Bear must produce identical results against NewBear.

---

## 2. AI-Native, Not AI-Bolted

AI is not a feature — it is a design constraint. Every module must be designed assuming
an AI agent will be a first-class user alongside the human.

- Every action a human can take, an API can invoke
- Every screen has a structured data model behind it (no logic buried in views)
- Clinical documentation assumes AI draft → human review → sign-off as the primary flow
- Search, filtering, and navigation assume natural language as a valid input
- Decision support surfaces automatically, not on request
- The entire API is exposed via **MCP (Model Context Protocol)** so AI agents can discover
  available actions, understand their parameters, and invoke them — the AI doesn't need
  hardcoded knowledge of endpoints, it reads the MCP tool manifest at runtime

**The interaction model has two equal paths:**

```
Traditional:  User → UI click/type → API call → result → UI update
AI-assisted:  User → voice/text intent → AI agent → MCP → API call → result → UI update
```

Both paths hit the same API, same permissions, same validation. The AI agent is not a
shortcut around the rules — it is a smarter client that translates human intent into
structured API calls.

**The UI is reactive to both paths.** When a voice command navigates to a client,
opens a form, or updates a field, the screen moves in real time — the user sees the
interface responding to their voice just as it would to a click. There is no separate
"AI mode" — the same screen, the same components, reacting to whichever input drives them.
Voice input should feel like the UI has a co-pilot, not like talking to a separate system.

**Anti-pattern:** Building the UI first, then asking "where can we add AI?"

---

## 2b. Design for Humans

The UI must be pleasant, clean, and calm. Clinical staff spend 8+ hours a day in this
application — it should reduce cognitive load, not add to it.

- Visual design is modern, uncluttered, and consistent across every domain
- Typography, spacing, and color are deliberate — not default framework styling
- Animations and transitions are purposeful (guide attention, confirm actions) not decorative
- Dark mode and high-contrast modes are supported (night shifts, bright clinics)
- The interface never makes the user feel lost — current context is always visible
- Error states are helpful, not alarming — tell the user what happened and what to do next
- Voice interaction has clear visual feedback: listening indicator, transcription preview,
  action confirmation — the user always knows the system heard them and what it's about to do

---

## 3. API-First, UI-Second

The API is the product. The web UI, mobile app, client portal, third-party integrations,
and AI agents are all consumers of the same API.

- Every feature ships as an API endpoint before it ships as a screen
- The API is the source of truth for permissions, validation, and business rules
- No business rule enforcement in the frontend — the frontend renders state and sends
  intents. UI presentation logic (show/hide fields, conditional layouts, field dependencies)
  lives in the frontend, driven by configuration metadata from the API
- Third parties get the same API surface (scoped by permissions) as first-party UIs
- Every API endpoint is registered in the **MCP tool manifest** with:
  - Human-readable description (so the AI understands what it does)
  - Parameter schemas with clinical context (so the AI knows what to ask for)
  - Permission requirements (so the AI knows what the current user can do)
  - Related tools (so the AI can chain actions into workflows)

**Three consumers, one API:**

| Consumer | Interface | Notes |
|----------|-----------|-------|
| Web/Mobile UI | REST API directly | Traditional click-driven interaction |
| AI Agent | MCP → REST API | Voice or text intent translated to API calls |
| Third-party | REST API with API key | Integrations, HIE, payer portals |

---

## 4. Data as a Product

The database is not a side effect of the application — it is a product that agencies pay for.
Reports, dashboards, exports, and AI models all depend on clean, consistent, well-modeled data.

- Every entity has a canonical identifier that is stable across time
- Every mutation is auditable (who, when, what changed, why)
- Timestamps are never derived from application state — they are recorded at the moment of the event
- Clinical terminology (ICD-10, SNOMED CT, RxNorm, CPT/HCPCS) is stored as structured codes, not free text
- Financial data uses integer cents, never floating point
- Deleted means soft-deleted with a reason, not gone

---

## 5. Behavioral Health First

Bear serves behavioral health and human services — not general medicine, not hospitals.
Every default, every workflow, every assumption should reflect this specialty.

- 42 CFR Part 2 (substance use confidentiality) is not an edge case — it shapes the entire consent and data-sharing model
- Treatment plans, group therapy, and crisis safety plans are core workflows, not add-ons
- The client is often not the payer — Medicaid, managed care, grants, and self-pay coexist
- Many clients interact with multiple programs simultaneously
- Foster care, residential, OTP, and transportation are not "modules" — they are core service lines
- Family and relationship context matters for treatment (not just for insurance)

---

## 6. Progressive Complexity

Simple things must be simple. Complex things must be possible. The system should not
force a 3-person clinic to navigate the same complexity as a 500-staff multi-site agency.

- Features reveal themselves as the agency's configuration demands them
- Defaults work out of the box for the common case
- Power features are accessible but not in the way
- Configuration is layered: platform defaults → agency settings → program settings → user preferences

---

## 7. Offline-Aware

Many behavioral health services happen in the field — home visits, mobile crisis,
transportation. The system must degrade gracefully without connectivity.

- Critical workflows (documentation, medication administration, vitals) must work offline
- Sync is conflict-aware and auditable
- The user always knows what has and hasn't synced

---

## 8. Regulation-Ready

Behavioral health is heavily regulated. The system must make compliance the path of
least resistance, not an afterthought.

- Audit trails are automatic, not opt-in
- Regulatory reports (OASAS, state reporting, CCBHC, MIPS) are built-in
- Consent management is a first-class subsystem, not a checkbox
- Timely filing, authorization tracking, and credential verification have system-level enforcement
- The system should make it hard to do the wrong thing (e.g., bill without a valid authorization)

---

## 9. Composable, Not Monolithic

NewBear is a platform of well-bounded domains that communicate through defined interfaces.
Each domain owns its data, exposes its capabilities through APIs, and can evolve independently.

- Domain boundaries follow the functional groups in this spec
- Cross-domain communication is explicit (events, API calls) not implicit (shared tables, direct DB queries)
- A domain can be rebuilt without rewriting the others
- New domains can be added without modifying existing ones

---

## 10. Ship Incrementally

NewBear is not a big-bang rewrite. It is an incremental replacement where each domain
can go live independently, running alongside legacy Bear during transition.

- Each domain has a clear migration path from legacy to new
- Both systems can coexist during transition (strangler fig pattern)
- Agencies can migrate domain by domain, not all-or-nothing
- Rollback is always possible at the domain level

---

## 11. AI Infrastructure is Defined, Not Assumed

The AI capabilities in NewBear depend on a deliberate infrastructure stack. Which models
run where, what they cost, and what they're good at must be explicit — not left to
"we'll figure it out."

### Model Tiers

| Tier | Purpose | Examples | Where It Runs |
|------|---------|----------|---------------|
| **Frontier** | Complex clinical reasoning, report generation, ambiguous intent resolution | Claude Opus, GPT-4 class | Cloud API (Anthropic, OpenAI) |
| **Workhorse** | Routine documentation, coding suggestions, structured extraction, MCP tool orchestration | Claude Sonnet, GPT-4o class | Cloud API |
| **Fast/Local** | Autocomplete, simple classification, PHI de-identification, embedding generation | Qwen, Llama, Mistral class | Self-hosted (agency GPU or central GPU server) |
| **Specialized** | Speech-to-text (voice intent), text-to-speech, medical NER | Whisper, domain-fine-tuned models | Self-hosted or cloud depending on latency/privacy |

### Voice-to-Intent Pipeline

```
Microphone → Speech-to-Text (Whisper/local) → Intent Text
  → AI Agent (workhorse model) → MCP tool selection → API call(s)
  → Result → Response generation → Text-to-Speech (optional) → Speaker
```

- Speech-to-text should run locally or on-premises when possible (PHI in audio)
- Intent resolution uses the workhorse model with the MCP manifest as context
- Complex or ambiguous intents escalate to frontier model
- The user always sees what the AI is about to do before it executes (confirm step)

### Infrastructure Principles

- **Model-agnostic abstraction:** The application never calls a specific model directly.
  It calls a capability (e.g., "generate clinical note", "resolve intent", "extract codes")
  and the infrastructure routes to the appropriate model
- **PHI-aware routing:** Data containing PHI is only sent to models/services that meet
  BAA and compliance requirements. Local models are preferred for PHI-heavy workloads
- **Fallback chain:** If a model is unavailable, the system degrades gracefully —
  frontier → workhorse → local → manual (never blocks the user)
- **Cost tracking:** Every AI call is logged with model, tokens, latency, and cost.
  Per-agency AI usage is measurable and billable if needed
- **Fine-tuning pipeline:** As agencies generate data, there is a path to fine-tune
  local models on de-identified clinical patterns (better autocomplete, better coding suggestions)
- **Evaluation:** AI outputs in clinical context are tracked for accuracy. The system
  learns which model tier works best for which task over time
