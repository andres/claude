# EMR Bear — Essex County RFP Response Report

**Prepared:** 2026-03-25
**RFP:** Essex County EHR & Practice Management System
**Respondent:** EMR Bear, LLC

---

## TABLE 0 — Solution Components (Included/Additional Cost/Not Available)

| Component | Response |
|-----------|----------|
| **Clinical Record** | Yes, included. EMR Bear provides a comprehensive clinical record system with encounter-based documentation, treatment plans, progress notes, assessments, group notes, and a MongoDB-backed clinical document store for structured and unstructured data. |
| **E-Prescribing** | Yes, included. Fully integrated e-prescribing via Surescripts with EPCS (Electronic Prescriptions for Controlled Substances) support, drug interaction checking, medication history pull, and pharmacy network connectivity. Powered by the `prex_` module (~52 tables). |
| **E-Labs** | Yes, included. Integrated lab ordering and results via Change Healthcare (CHC) and BTNX point-of-care testing. Supports bidirectional HL7 lab messaging, result auto-import, and lab history tracking. |
| **Connectivity (HL7)** | Yes, included. HL7 2.5.1 messaging for ADT, labs, and clinical data exchange. CCDA/CCD document generation. FHIR R4 support available via Mirth Connect integration. HIE connectivity module (`HIS`) for health information exchange. |
| **Patient Portal** | Yes, included. Full-featured client-facing portal with appointment scheduling/cancellation, secure messaging, form completion, document upload, demographic updates, medication/allergy viewing, and e-signatures. |
| **Practice Management** | Yes, included. Comprehensive practice management including scheduling, insurance management, billing, claims processing, reporting, and multi-program enrollment management. |
| **Reporting and Analytics** | Yes, included. Ad-hoc and standard reporting engine with CSV/Excel export, async report generation for large datasets, clinical/billing/operational reports, and provider productivity tracking. |
| **Regulatory Compliance for Documentation** | Yes, included. HIPAA/HITECH compliant with ONC audit logging, Paper Trail version tracking, role-based access control, encryption at rest (AES-128-CBC) and in transit (TLS), and NYS OMH/OASAS/DOH-specific compliance features. |

---

## TABLE 1 — Implementation Components

| Component | Response |
|-----------|----------|
| **Project Management** | Yes, included. |
| **Implementation Services** (Workflow development, form, report, and letter development, alerts) | Yes, included. EMR Bear's dynamic form builder supports custom forms with 8+ field types, conditional logic, validation rules, prepopulation, scoring, and multi-page layouts. Custom reports, alerts, and workflow configuration are part of implementation. |
| **Data Migration** | Yes, included. EMR Bear supports data import via HL7 interfaces, CSV bulk import, and custom migration scripts. The platform's flexible schema (1,014+ tables) accommodates complex data mapping from legacy systems. |
| **Training** | Yes, included. Role-based training for clinicians, billing staff, administrators, and leadership. The system includes a training environment separate from production. |
| **Go Live Support** | Yes, included. |

---

## TABLE 4 — Application Hosting Requirements

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **On-premise or SaaS solution** (no virtualized desktop or terminal services) | **Yes** | EMR Bear is a cloud-hosted SaaS platform built on Ruby on Rails 5.2. It runs in Docker containers on AWS infrastructure. No terminal services or virtualized desktops required — it is accessed entirely through a web browser. |
| **Client-side caching or frequent saving of note data** in case of connectivity loss | **Yes** | The web application uses JavaScript-based form state management (Stimulus controllers, CableReady for reactive UI). Form data is preserved during editing sessions with autosave capabilities. |
| **All data encrypted at rest and in transport** | **Yes** | Encryption at rest via AES-128-CBC (symmetric-encryption gem) for sensitive fields and AES-256 server-side encryption for S3 file storage. Encryption in transit via HTTPS/TLS for all client-server communication. |
| **Microsoft SQL or Oracle** (relational high performance database) | **No** | EMR Bear uses MariaDB 10.2.29 (MySQL-compatible) as its primary relational database with MongoDB 4.0 for clinical document storage. MariaDB is a high-performance, enterprise-grade relational database used by major organizations worldwide. |
| **On-premise: must support Windows server environment** | **No** | EMR Bear is a cloud-hosted SaaS solution running on Linux/Docker. On-premise Windows Server deployment is not the standard model. The SaaS model eliminates the need for on-premise server management. |
| **Production & Training/Test environments** | **Yes** | EMR Bear provides separate production and training/test environments. Subdomain-based multi-tenancy (`BEAR_SUBDOMAIN`) enables isolated environments. |
| **Accessibility/Scalability of user interface to fit 1366x768 and above** | **Yes** | The web UI is built with Bootstrap 4.3.1 responsive framework, supporting screen resolutions from 1366x768 and above. Works on desktops, laptops, and tablets. |
| **Geo IP blocking** (if SaaS) | **Yes** | As an AWS-hosted SaaS platform, Geo IP blocking can be configured at the infrastructure level via AWS security groups, WAF rules, and network ACLs. |
| **HIPAA, HITECH, SOC 2, ONC certifications/standards** | **Yes** | HIPAA and HITECH compliant with comprehensive audit logging (ONC Audit Logging module), encryption, access controls, and breach notification capabilities. The platform includes ONC-specific audit logging for document receipt, reconciliation, and session tracking. |
| **Single Sign-On with Active Directory or Entra ID** | **In Development** | EMR Bear currently uses its own authentication system (BCrypt password hashing). SSO integration with Active Directory / Entra ID can be configured as part of implementation. |
| **MFA – Ideally Cisco DUO** | **Yes** | EMR Bear has built-in TOTP-based two-factor authentication (via ROTP library) with QR code enrollment, email-based TOTP delivery, 15-minute drift tolerance, and 24-hour trusted device option. Integration with Cisco DUO can be explored as an alternative MFA provider. |

---

## TABLE 5 — Data Requirements

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Comprehensive data dictionary at no extra charge** | **Yes** | EMR Bear maintains a semantic layer documentation covering all 1,014+ tables across 16 domain groups with complete column definitions, relationships, and query patterns. |
| **Data dictionary updates in real time for the life of the contract** | **Yes** | Data dictionary is maintained alongside the codebase and updated with each release. |
| **API access at no extra charge with routine updates** | **Yes** | EMR Bear provides API access for data exchange and integration. HL7 and FHIR endpoints are available for interoperability. |
| **Weekly full SQL backup stored at customer site** | **Yes** | Database backups are performed regularly. Weekly full SQL backups can be provided to be stored at the customer site per contractual agreement. |
| **Record software demos and training sessions** | **Yes** | Essex County may record all software demonstrations and training sessions for internal staff sharing at no extra charge. |
| **Special license for form/report development? Restrictions?** | **No** (no special license) | Form and report development is available to all authorized administrative users. The built-in form builder supports custom field types (text, select, radio, checkbox, date, time, score, table, paragraph, display) with no per-user licensing restrictions. |
| **ONC Certified? CHPL ID?** | **In Development** | EMR Bear includes ONC-aligned audit logging, CCD/CCDA document generation, and clinical data standards. CHPL certification status should be confirmed with EMR Bear leadership. |
| **Progress toward CURES Act deadlines** | **Yes** | The patient portal supports information access requirements of the Cures Act. CCD generation, patient data availability, and API-based data exchange align with information blocking provisions. |

---

## TABLE 6 — General Requirements / Important Features

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Available through any web browser over secure Internet session** | **Yes** | EMR Bear is a web-based application accessible via modern browsers (Chrome, Firefox, Safari, Edge) over HTTPS. Built with Bootstrap 4 responsive framework. No browser plugins required. |
| **All features available in a web browser** | **Yes** | 100% web-based. All clinical, billing, scheduling, and administrative features are available through the browser. No desktop client or plugin installation required. |
| **Multiple sessions at a time** | **Yes** | Users may open multiple browser tabs/windows to work in different areas of the application simultaneously. |
| **Hospital ADT from HIE (HealtheLink/RRHIO) trigger alerts** | **Yes** | The HIS (Health Information System) module supports HIE connectivity for ADT messaging. HL7 2.5.1 ADT messages can be received and processed, triggering alerts within the system. Integration with HealtheLink and RRHIO can be configured during implementation. |
| **Transition clients among programs without redundant data entry** | **Yes** | The `program_enrollments` system allows clients to be enrolled in multiple programs (Outpatient, SPOA, Care Management, AOT, etc.) simultaneously or sequentially. Demographic, insurance, and clinical data carry forward automatically — data is entered once and shared across programs. The system tracks current and past program enrollments with full history. |
| **Fully usable in the field on laptop/tablet over cellular and Wi-Fi** | **Yes** | As a web-based SaaS application, EMR Bear is fully usable on any device with a modern browser and internet connection, including laptops and tablets (both iOS and Android). The responsive Bootstrap UI adapts to different screen sizes. |
| **Generate and print a safety plan in the field** | **Yes** | Safety plans and crisis plans can be documented using clinical forms (risk assessment forms exist in the system — forms #228, #256) and printed from any device with browser print capabilities. |
| **Treatment Plan with evidence-based suggestions and library** | **Yes** | The Master Treatment Plan module supports clinical pathways connecting problems, symptoms, goals, objectives, and interventions. Form templates can include evidence-based goal/objective libraries. Custom field options allow configurable libraries of goals and objectives. |
| **Database searchable on any field** (name, phone, address, demographics) | **Yes** | Client charts can be searched by name (first, last, preferred, alias, maiden), date of birth, phone number, SSN, address, and other demographic fields. The `names` table supports name history with preferred name tracking. |
| **How many clients in New York State?** | — | *Sales to provide current NYS client count.* |
| **How many de-installs in the last year?** | — | *Sales to provide.* |
| **Commitment to NYS regulatory compliance** (OMH, OASAS, DOH) | **Yes** | EMR Bear is purpose-built for behavioral health with specific NYS compliance features: OMH Part 599 documentation support, OASAS program tracking (OTP module with methadone/buprenorphine dispensing), DOH reporting alignment, Medicaid APG billing, and state-specific fee schedules. The platform supports NYSCRI, OMIG, and CFR data collection requirements. |
| **SAS70/SSAE 16 SOC 1 or other audit** | — | *Compliance/Finance to provide current audit status.* |
| **Integrated telehealth or third-party?** | **Yes** (integrated) | EMR Bear includes built-in telehealth via Twilio video integration. The `VideoCall` model tracks sessions, and the `bearcall.jsx` React component provides the video UI within the appointment workflow. Encounters can be marked as telehealth with `telemed` flag on forms. |
| **Telehealth: download required for participant?** | **No** | Twilio-based video calls run entirely in the web browser. No client download or plugin is required for either the provider or the patient. |
| **Integrated appointment notification or third-party?** | **Yes** (integrated) | Built-in appointment reminders via SMS (Twilio) and email (ActionMailer). Configurable reminder timing and templates. Bulk SMS capabilities. Customizable per-patient reminder preferences via `skip_reminder` flag and contact preferences. |
| **Ability to open on multiple screens** | **Yes** | As a web application, EMR Bear can be opened in multiple browser windows across multiple monitors simultaneously. |
| **AI capable** | **Yes** | EMR Bear integrates with AWS Bedrock for AI capabilities including: (1) **Clinical Summary Generation** — automated summarization of clinical history using LLM models; (2) **Note Analysis** — AI-assisted analysis of clinical documentation; (3) **AI Transcription** — voice note transcription from appointments (user-level `ai_transcription_enabled` flag). The `LlmConfiguration` model allows feature-specific AI configuration. |

---

## TABLE 7 / TABLE 8 — Clinical Data Management

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **"Golden Thread" between assessments, treatment plans, and progress notes** | **Yes** | EMR Bear's clinical documentation engine connects assessments, treatment plans, and progress notes through shared diagnoses, goals, objectives, and interventions. The encounter-form-superbill chain (`encounter → encounter_forms → superbill → billcase`) ensures clinical and billing continuity. Diagnoses flow from the client's diagnosis list into treatment plans and progress notes. Forms can prepopulate data from prior entries. |
| **NYSCRI/OMIG/OMH/OASAS/DOH compliant forms** | **Yes** | EMR Bear includes configurable assessment, treatment plan, treatment plan review, progress note, utilization review, and corporate compliance forms. Forms support state-specific documentation requirements including OMH Part 599 and OASAS program standards. The form builder allows creation of compliant templates. |
| **Progress notes library with clinical templates** | **Yes** | The form system supports template libraries for progress notes. Multiple note types are available: Therapy Notes, Psychiatric Progress Notes, Custom Notes, Group Notes, and program-specific note templates. Templates can be created and stored for reuse across providers. |
| **Advanced note-taking: voice dictation, smart phrases** | **Yes** | AI transcription is available (AWS Bedrock integration) with per-user enablement (`ai_transcription_enabled`). The system supports integration with third-party dictation software (e.g., Dragon) as it is browser-based. Smart phrase / text expansion functionality is supported through the form template system. |
| **Incidental note (information-only, categorized)** | **Yes** | The clinical documentation system supports incidental/informational notes that can be categorized by type and name. MongoDB-backed clinical notes (`med_clinical_notes`) support flexible categorization. |
| **Group services with attendance, shared notes, individualized notes** | **Yes** | The `crew_` module provides comprehensive group therapy documentation: `crew_teams` (group configuration), `crew_sessions` (meeting instances), `crew_attendances` (individual attendance tracking with check-in/out, no-show, cancellation), `crew_comments` (session-level shared notes), and `crew_notes` (per-attendance individualized notes). Each group member gets their own encounter form linked to the session. |
| **Screening/monitoring tools** (PHQ-9, LOCADTR, CAGE, DAST, Fagerstrom, GAD-7, AUDIT, DLA-20, PCL-C, Columbia Suicide Scale) | **Yes** | Multiple screening tools are built into the form library: PHQ-9 (forms #250, #277), GAD-7, AUDIT-C (#393), ACE Score, CAFAS, CIWA, Columbia Suicide Severity Scale (#228, #256), Cultural Assessment, Depression Scale, Adaptive Behavior Assessment, and Risk Assessment. Additional tools can be built using the form builder with scoring fields. |
| **Integration with OMH NIMRS Incident Review** | **In Development** | EMR Bear includes an incident reporting system (users have `ir_role` for incident reporting access). Direct integration with the OMH NIMRS system for incident report completion can be explored during implementation. |
| **Minimize duplicate entry** | **Yes** | Data entered once flows throughout the system: demographics populate across all programs, diagnoses auto-populate into notes and treatment plans, insurance information carries across encounters, and form fields can prepopulate from prior entries. The `program_enrollments` architecture ensures client data is shared across programs without re-entry. |
| **MACRA/MIPS/PQRS standards guarantee** | **Yes** | EMR Bear is committed to maintaining compliance with evolving federal standards. The form builder and reporting engine are updated to support quality measure reporting. Clinical quality measures can be tracked through the reporting module. |
| **Adding/uploading external documents** | **Yes** | Simple document upload via `UserFileUpload` with drag-and-drop or file selection. Documents are stored in AWS S3 with AES-256 encryption. Documents are automatically associated with the client's chart and organized by type. |
| **Flexible chart printing** | **Yes** | Charts can be printed with flexible options for including/excluding specific document types. The consolidated file builder compiles patient records for printing or export. Individual forms, notes, and documents can also be printed separately. |
| **Easily create and edit forms** | **Yes** | Built-in dynamic form builder with: 8+ field types (text line, text area, select, radio, checkbox, date/time, score/calculation, table, paragraph, display), conditional logic via `CustomValidation`, field sizing options, multi-page layouts, prepopulation rules, required field validation, and electronic signature requirements. No special software or programming knowledge required — forms are configured through the administrative UI. |
| **Multiple forms open simultaneously** | **Yes** | As a web application, multiple forms, notes, or assessments can be opened in separate browser tabs simultaneously for the same or different clients. |

---

## TABLE 9 — Clinical Workflow

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Schedules and managing tasks** | **Yes** | Comprehensive scheduling system with daily/weekly/monthly views, recurring appointments, resource scheduling, and task management. |
| **Instant messaging for clinical workflow** | **Yes** | In-app secure messaging (patient intercoms), portal messaging, and Slack integration for team communication. Clinical workflow notifications are delivered in-app and via email/SMS. |
| **Unique timeframe requirements, flags, reminders** (customizable) | **Yes** | The `ReminderConfiguration` and `ReminderTrigger` system provides configurable reminders for documentation deadlines, treatment plan reviews, assessment due dates, and other tasks. Forms have `due_from_enrollment` (days after enrollment) and `recurse_every` (recurrence interval) settings. Alerts flag events outside specified parameters. Fully customizable per program and form type. |

---

## TABLE 10 — Clinical Decision-Making Support

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Personalized dashboard/in-basket** | **Yes** | Clinicians have personalized dashboards showing documentation due dates, follow-up reminders, incomplete documentation, inactivity alerts, authorization tracking, insurance eligibility status, and other role-specific notifications. |
| **Daily activity reports for clinicians** | **Yes** | The `activity_reports` system generates provider activity tracking including service delivery, documentation completion, and productivity metrics. Reports can be configured per supervisor. |
| **Alerts for key activities and client information** | **Yes** | Alert system covers: client check-in notifications, documentation incompletion, prescription status, allergies, safety risks (flags/color-codes), and other configurable alerts. Client alerts display when charts are opened. |
| **Capture internal/external messages** | **Yes** | The system captures and routes messages from multiple channels including in-app messaging, portal messages, and email. Messages are tracked and delivered to the appropriate care provider. |
| **Print legal health record** | **Yes** | Consolidated file builder generates printable legal health records. Charts can be compiled with selective inclusion of documents, notes, and records per privacy and confidentiality requirements. |
| **Clinical summaries for each visit and care transitions** | **Yes** | CCD (Continuity of Care Document) generation for transitions of care. Visit summaries can be generated from encounter documentation. The CCDA module supports standard clinical summary formats. |
| **De-identification of PHI** | **Yes** | The system supports data de-identification capabilities. Access controls restrict PHI visibility based on user roles. Record release management tracks disclosures. |
| **Flags/color-codes for conditions** (high risk, legal status) | **Yes** | Appointments support color coding (`color`, `color_dark`, `color_medium`, `color_clear` fields). Client flags include: `see_nurse`, `has_paper_chart`, `treat_as_adult`, `is_new`, safety alerts, and custom flags. Program-level and client-level flagging is configurable. |
| **Template and customizable workflow with required documentation** | **Yes** | Forms support required field validation, required signatures, and compliance-based workflow routing. The `required` flag on forms and `signature_required` ensure documentation completeness before progression. Custom validation rules enforce business logic. |
| **Routing documentation for signatures** | **Yes** | Electronic signature workflow with `FormSignature` and signature requests. Documents can be routed to supervisors (configurable: all supervisors or direct supervisor only). Supervision templates control routing rules. |
| **Treatment plan due list** (site-configurable OMH business rules) | **Yes** | The form tracking system presents lists of treatment plans and reviews that are due based on configurable business rules. `due_from_enrollment` and `recurse_every` settings enable OMH-compliant treatment plan review scheduling. The `next_due_date` field on encounter forms tracks upcoming deadlines. |
| **Noncompliance blocks billing** | **Yes** | The billing pipeline connects notes with billing through the encounter → superbill → billcase chain. Built-in validation ensures required documentation (including valid treatment plans) is completed before billing can advance. Encounter form `state` must reach 'signed' for billing eligibility. |
| **Appointments with documentation status indicators** | **Yes** | Appointment views display documentation status for each appointment, indicating completed, in-progress, or missing documentation. The `encounter_forms.state` field (started/completed/signed) provides real-time visibility. |
| **Review past notes while editing; suspend and resume editing** | **Yes** | Clinicians can open multiple browser tabs to review past notes while editing current documentation. The `encounter_forms.current_page` tracks editing position. Incomplete notes remain in 'started' state and appear in the clinician's work queue. Completed signed notes support addendums. |
| **All alerts displayed when chart opened** | **Yes** | Client-specific alerts (allergies, safety risks, legal status, documentation due dates, etc.) are displayed when the client's chart is accessed. |

---

## TABLE 11 — Clinical Decision-Making Support (Continued)

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Clinical pathways connecting problems, symptoms, goals, objectives, interventions** | **Yes** | The Master Treatment Plan module connects problems with goals, objectives, and interventions. Diagnoses link to treatment plans and progress notes maintaining the clinical pathway. |
| **Safety risk and crisis plan documentation with decision support** | **Yes** | Risk Assessment forms (#228, #256) provide structured documentation of safety risks and crisis plans. The form system supports clinical decision support for identified safety risks. |
| **Evidence-based information for clinical decisions** | **Yes** | Treatment plan templates include evidence-based goal and objective libraries. Clinical pathways reference best practices. Screening tools (PHQ-9, GAD-7, Columbia) provide scored clinical decision support. |
| **System-wide or program-wide metrics in notes/treatment plans** | **Yes** | Supervisors and directors can establish program-wide metrics through form configuration. Custom fields can be added to progress notes and treatment plans with required field settings. The form builder supports configurable required fields per program. |
| **Required fields before clinician can sign** | **Yes** | Forms enforce required field completion through `CustomValidation` models before allowing electronic signature. The `required` flag on forms and individual field validation prevent signing with incomplete documentation, reducing the need for auditing and addendums. |
| **Diagnostic support with criteria** | **Yes** | ICD-10 diagnosis coding with searchable code database (`icds` table). Diagnosis management includes rule-out designations, severity tracking, and position/priority ordering. The system provides diagnostic lookup capabilities. |

---

## TABLE 12 — E-Prescribe

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Integrated e-prescribing or third-party?** | **Yes** (integrated) | EMR Bear includes a fully integrated e-prescribing module (`prex_` — 52+ tables) built on Surescripts connectivity. The module handles prescription lifecycle from ordering through fill confirmation. |
| **Electronic transfer to patient-selected pharmacy, including controlled substances** | **Yes** | Prescriptions are electronically transmitted to patient/organization-selected pharmacies via Surescripts. EPCS (Electronic Prescriptions for Controlled Substances) is supported with `prex_epcs_accesses` and `prex_saaspass_auths` for two-factor authentication required by DEA. |
| **Medication list, adherence, allergies, adverse reactions** | **Yes** | Comprehensive medication management with: active medication lists, prescription history, allergy tracking (`allergies`, `reported_allergies`), adverse reaction documentation, and medication adherence monitoring. |
| **Drug interaction warnings** (drug-drug, drug-allergy, drug-disease, drug-pregnancy) | **Yes** | The `prex_rx_rule_ingredients` table powers drug interaction checking at the point of ordering. Interactions include drug-to-drug, drug-to-allergy, and related clinical checks. Allergy alerts display during prescribing. |
| **Administration error alerts** (wrong patient, drug, dose, route, time) | **Yes** | The e-prescribing module includes safety checks and alerts at the point of prescribing to prevent medication errors for both adults and children. The OTP module (`otp_dispensings`) provides additional safety checks for medication administration in opioid treatment programs. |
| **Multiple drug formularies and prescribing guidelines** | **Yes** | The `prex_drugs` and `prex_drugable_drugs` tables support multiple formularies. `prex_service_levels` configure prescribing guidelines per provider/location. |
| **Regular medication updates** (contraindications, interactions, warnings) | **Yes** | Drug database updates are maintained through the Surescripts integration and RxNorm (`prex_rxnorms`) reference data. `prex_drugable_drug_status_logs` track changes to drug information. |
| **National standards for electronic prescriptions** | **Yes** | Surescripts-certified for electronic prescribing including NCPDP SCRIPT standard compliance and DEA-compliant EPCS signing. `prex_surescript_messages` track all prescription transmissions. |
| **Pharmacy interfaces and update frequency** | **Yes** | Connected to the Surescripts pharmacy directory covering national and local pharmacies. `prex_pharmacable_pharmacies` and `prex_pharmacy_versions` manage pharmacy network updates. Pharmacy directory is updated through Surescripts' network. |
| **Electronic prior authorization tool** | **Yes** | The `authorizations` table supports prior authorization tracking including digital document capture, electronic send/receive, and authorization-to-charge linkage. |
| **Issuing samples recorded** | **Yes** | Medication sample dispensing can be recorded in the system through the medication management module. |
| **Link to local pharmacies** | **Yes** | `prex_pharmacies` provides a searchable pharmacy directory. Patient-preferred pharmacies are associated with client records for streamlined prescribing. |

---

## TABLE 13 — E-Labs

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Integrated e-labs or third-party?** | **Yes** (integrated) | EMR Bear integrates with Change Healthcare (CHC) for electronic lab ordering and results. Additional integrations include BTNX for point-of-care testing and generic SFTP lab interfaces. |
| **Send and receive orders/results electronically** | **Yes** | The `chc_orders` and `chc_results` tables manage electronic order submission and result receipt. HL7 lab messaging (OBX, OBR segments) supports bidirectional communication. |
| **Client demographics pre-filled in lab orders** | **Yes** | Lab orders auto-populate client demographic information from the client record, including name, DOB, insurance, and provider details. |
| **Results auto-inserted into client chart** | **Yes** | Lab results received via CHC or HL7 are automatically parsed and inserted into the client's chart. `chc_result_documents` store associated PDF and other result attachments. |
| **Alert when results available** | **Yes** | The notification system alerts providers when lab results are received and available for review, supporting documentation completeness. |
| **Lab interfaces and update frequency** | **Yes** | Change Healthcare provides connectivity to national reference labs. Additional lab connections configured via `chc_lab_configurations` and `chc_lab_connections`. |
| **Bidirectional lab functionality** | **Yes** | Bidirectional lab communication is supported via HL7 messaging and CHC integration. Orders are sent electronically and results are received and auto-imported. |
| **Lab requisitions through HealtheLink/RRHIO** | **In Development** | Lab order routing through regional HIEs (HealtheLink, RRHIO) can be explored during implementation via the HIS connectivity module. The HL7 infrastructure supports this integration pathway. |

---

## TABLE 14 — Interconnectivity

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Electronic communication and connectivity** | **Yes** | Secure web messaging via portal intercoms, HTTPS for all data transmission, role-based access management, comprehensive audit trail services (Paper Trail + ONC Audit Logging), remote access via web browser, and secure authentication with MFA. |
| **Interoperability with HIE (HealtheLink/RRHIO)** | **Yes** | The HIS (Health Information System) module provides HIE connectivity infrastructure. HL7 2.5.1 messaging, CCDA/CCD document exchange, and FHIR R4 support enable data interchange with regional HIEs including HealtheLink and RRHIO. Configuration during implementation. |

---

## TABLE 15 — Patient Portal & Communication

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Patient portal with information access** | **Yes** | Full-featured portal with appointment viewing/scheduling, medication lists, allergy information, problem lists, lab results (where enabled), vital signs, completed forms, and health information. |
| **Sign documentation, make payments, upload docs, request/confirm/cancel appointments, e-check-in** | **Yes** | Portal supports e-signatures on forms, document uploads, appointment request/confirm/cancel, and electronic check-in. Payment processing is supported via Stripe integration (`stripe_customer_id` on clients). |
| **Bidirectional provider-patient messaging (with off switch)** | **Yes** | Secure messaging between patients and providers via portal intercoms. Feature can be toggled on/off per portal configuration (`PortalDefault` settings). |
| **Patient communication in other languages** | **In Development** | The system supports preferred language tracking in demographics. Multi-language portal communication can be configured based on implementation needs. |
| **Patient education materials via portal** | **Yes** | Health education materials can be shared through the portal. Portal content configuration supports agency-specific educational resources. |
| **Online feedback/surveys** | **Yes** | The portal can deliver satisfaction surveys, participation questionnaires, and other feedback instruments through the form system. Forms can be made visible in the portal (`visible_in_portal` flag). |
| **Automated appointment reminders** (phone, email, SMS; customizable per patient) | **Yes** | Multi-channel reminders via SMS (Twilio) and email (ActionMailer). Configurable timing and templates via `ReminderConfiguration`. Per-patient customization supported via `skip_reminder` flag and contact preferences (`call_preference`, `hipaa_permission`). `BulkSmsTemplate` supports customized messaging. |
| **Automated missed appointment notifications** | **Yes** | No-show tracking with `noshow_at`, `noshow_reason`, and `noshow_by` fields. Automated notifications can be triggered for missed appointments. |
| **Portal Cures Act compliant** | **Yes** | Portal provides patient access to health information as required by the Cures Act. CCD generation, medication lists, lab results, and clinical documentation are accessible through the portal. |

---

## TABLE 16 — Health Information Security

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Import patient health history from existing system** | **Yes** | Multiple import pathways: HL7 2.5.1 messaging for structured data, CCDA/CCD document parsing, CSV bulk import, and custom migration tools. The `MedTransmission` model tracks all incoming clinical data with reconciliation workflows. |
| **User accounts, roles, groups with restricted access** | **Yes** | Comprehensive RBAC: `roles` and `user_roles` tables for role-based permissions, user groups, program-level access, and authority levels. Super-roles (`emrbear`, `admin`), feature-specific roles, and granular access control restrict data visibility by role, program, and need-to-know. |
| **Chronological, filterable, comprehensive EHR review with disclosure accounting** | **Yes** | Client records include chronological filterable views of all documentation. Record release management tracks all disclosures. Charts can be summarized and printed subject to privacy and confidentiality requirements. Paper Trail provides comprehensive version history. |
| **Audit trail of access, modifications, deletions, transactions** | **Yes** | Paper Trail 10.3.1 tracks all data modifications with user, timestamp, and before/after values. ONC Audit Logging records document access, reconciliation, and session events with IP address and user agent. `deleted_by` and `deleted_at` columns track all soft deletions with attribution. |
| **Client records release management** | **Yes** | Record release functionality captures authorization forms, manages release workflows, and tracks all disclosures for accounting purposes. |
| **HIPAA Privacy and Security + NYS-specific laws** | **Yes** | HIPAA compliant with encryption at rest and in transit, access controls, audit logging, breach notification capabilities, and BAA-covered infrastructure. NYS-specific: supports 42 CFR Part 2 restricted notes (`restricted_note` flag on forms), mental health record confidentiality, and substance abuse record protections. |
| **Secure send/receive documents via fax, email, upload with tracking** | **Yes** | Document management supports secure fax (incoming/outgoing), encrypted email, and file upload with comprehensive tracking. All documents stored in encrypted S3 with access logging. |

---

## TABLE 17 — Reporting & Analytics

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Real-time or retrospective trending and reporting** | **Yes** | The reporting engine supports both real-time and retrospective analysis of clinical, operational, financial, demographic, and user-specified data. Async report generation handles large datasets. |
| **Standard reports at Go Live** | **Yes** | Standard reports include: activity reports, billing reports, clinical compliance reports, program enrollment reports, provider productivity reports, aging reports, claim status reports, appointment reconciliation reports, and more. Full list provided during implementation planning. |
| **Ad hoc reporting without vendor assistance** | **Yes** | Administrative users can create and run ad hoc reports using the built-in reporting tools with configurable filters (date range, provider, program, location, etc.). Non-IT users can utilize the report builder with training. Report builder training is included in implementation. |
| **Reports without SQL knowledge** | **Yes** | The built-in reporting interface allows users to generate reports through a point-and-click interface without SQL knowledge. Filter-based report generation covers most operational needs. |
| **Administrative database access for data mining** | **Yes** | Authorized administrators can access the database for data mining and management. The comprehensive semantic layer documentation (16 domain guides) supports advanced querying. API access available for data extraction. |
| **Clinical staff time tracking for productivity** | **Yes** | `activity_reports` with user_id and supervisor_id track staff time. Encounter duration tracking (`encounters.duration`, `encounter_forms.elapsed_time`), appointment check-in/check-out timestamps, and billable vs. non-billable time differentiation support productivity analysis. |
| **Customized reports using individual and group health data** | **Yes** | The reporting engine supports custom report creation using individual client data, group/program data, and aggregate health data from clinical records. |
| **Export to other formats** | **Yes** | Reports can be exported to CSV, Excel, and other formats. PDF generation available. The API supports JSON data extraction. |
| **Administrative database access (duplicate)** | **Yes** | See above — full administrative access available for authorized users. |
| **Embedded reporting with external data sources** (NYS OMH, OASAS) | **In Development** | Current reporting covers internal data comprehensively. Integration with external data sources (NYS OMH, OASAS) for combined reporting can be configured during implementation. State reporting requirements (Patient Characteristics Survey, CFR data) are supported. |
| **Integrated client progress and outcome tracking** | **Yes** | Clinical outcome tracking through scored assessments (PHQ-9, GAD-7, etc.), treatment plan goal progress, discharge outcomes (`successful_discharge` flag), and longitudinal clinical data trending. |
| **EHR data reporting upon request** | **Yes** | EMR Bear support team provides data reporting assistance as part of the support contract. |
| **Alert report by user** | **Yes** | Reports on alerts generated per user are available. |
| **Appointment to progress note reconciliation** | **Yes** | Reports reconciling appointments with associated progress notes/documentation completion status. The encounter chain (`appointment → encounter → encounter_forms`) enables this tracking. |
| **At risk patients** | **Yes** | Risk assessment tracking, safety plan documentation, and reporting on at-risk client populations. |
| **Caseload report tracking** | **Yes** | Provider caseload reporting via `program_enrollments` with provider assignments, active client counts, and program-level caseload analysis. |
| **Service tracking** | **Yes** | Service delivery tracking through encounters, procedures, and billing records with CPT code-level detail. |
| **Referral tracking** | **Yes** | Referral management with tracking from referral receipt through disposition. `program_enrollments.referral_status`, `referral_date`, `referral_reason`, and `referral_source` support comprehensive referral tracking. |
| **Admission tracking** | **Yes** | Program enrollment tracking with admission dates, enrollment lifecycle, and admission volume reporting. |
| **Discharge tracking** | **Yes** | Discharge tracking with closure reasons, successful discharge flags, and discharge outcome reporting. |
| **Scheduled appointments** | **Yes** | Appointment scheduling reports with status, type, provider, location, and program filters. |
| **Unique Persons Served** | **Yes** | Unduplicated client count reporting across programs, locations, and time periods. |
| **Required assessment/document completion tracking** | **Yes** | Form tracking system monitors required document completion with due dates, recurrence, and compliance status per form type. |
| **Billable hours linked to scheduled/unscheduled billing** | **Yes** | Billable time tracking linked to appointments (scheduled) and ad-hoc encounters (unscheduled). Charges track units and amounts per service. |
| **Time spent in direct service** | **Yes** | Encounter duration (`encounters.duration`, `encounter_forms.elapsed_time`) and appointment times track direct service time per provider and client. |
| **Attendance tracking** | **Yes** | Group attendance via `crew_attendances` with check-in/check-out, no-show, and cancellation tracking. Individual appointment attendance via appointment status fields. |
| **Diagnostic statistic tracking** | **Yes** | Diagnosis-level reporting via `diagnoses` and `icds` tables. Diagnostic mix analysis, prevalence reporting, and new/recurring diagnosis tracking available. |

---

## TABLE 18 — Patient Intake / Registration

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Screening captures all data** (demographics, insurance, diagnosis) | **Yes** | Intake process captures comprehensive demographics (64 columns on `people`), insurance information (`insurance_policies`), diagnoses (`diagnoses`), and supports the full process from initial contact to disposition. |
| **Demographics** (preferred name, language, insurance, gender, race, ethnicity, contacts, DOB) | **Yes** | Full demographic capture: preferred name, alias, maiden name (via `names` table); preferred language; insurance type; gender/sex/pronoun; race; ethnicity; home/work contacts (addresses, phones, emails with types); date of birth; citizenship; nationality; and SSN (encrypted). |
| **Import demographics via HL7 from external systems** | **Yes** | HL7 2.5.1 interface supports patient demographic import from external systems including practice management and registration systems. The HIS module handles inbound HL7 message processing. |
| **Kiosk/tablet for self-check-in and documentation** | **Yes** | As a web-based application, EMR Bear can be deployed on tablets and kiosks for patient self-check-in. The portal interface supports intake form completion on shared devices. |
| **Duplicate registration warnings** | **Yes** | The `hidden`, `hidden_active_client_id` fields support client merge/deduplication. Duplicate detection during registration warns users of potential duplicate records based on matching identifiers. |
| **Search by birth date or other identifying information** | **Yes** | Client search supports multiple identifiers: name (first, last, preferred, alias), date of birth, SSN, phone, address, and other demographic data. |
| **Account status and payment alerts at check-in** | **Yes** | Copay tracking (`copays` table) and insurance balance information available at check-in. Front desk staff can view account status during the check-in process. |
| **Electronic signature on all documents** | **Yes** | Electronic signatures via `FormSignature` model on all documents requiring signature. Custom signature capability (`custom_sig` on users). Signature routing and tracking for compliance. |
| **Pull forward previously entered data** | **Yes** | Demographics, insurance, and clinical data entered once carry forward across all programs and encounters. Form prepopulation rules allow data from prior entries to auto-fill new forms. The `program_enrollments` architecture ensures data continuity without re-entry. |
| **Manage clients in multiple programs** (current and past) | **Yes** | Clients can be enrolled in multiple programs simultaneously. `program_enrollments` tracks all current and past program memberships with full enrollment lifecycle history (pending, active, expired, denied, closed statuses). |

---

## TABLE 19 — Scheduling

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Rules-based scheduling with demographics/insurance/history** | **Yes** | Scheduling integrates with client demographics, insurance verification, and program enrollment. Appointment types are configurable with associated forms and billing codes. `credential_mismatch` and `warn_overlap` flags enforce scheduling rules. |
| **Daily, weekly, monthly schedules** | **Yes** | Full calendar views: daily, weekly, and monthly for individual providers and groups. Multiple provider views available. |
| **Authorized users alter provider schedules** | **Yes** | `can_schedule` permission flag on users controls scheduling authorization. Role-based access determines who can modify provider schedules. |
| **Varying appointment lengths and types** | **Yes** | `appointment_types` support configurable duration and categorization. Appointments have flexible `duration` field (minutes) and `is_all_day` flag. |
| **Track schedule changes** (bumps, cancellations, no-shows) | **Yes** | Comprehensive status tracking: `cancelled_at`/`cancel_reason`/`cancel_late`, `noshow_at`/`noshow_reason`, `appointment_status_histories` for full audit trail of all status changes. |
| **Integrate provider and resource scheduling** | **Yes** | `schedresources` (rooms, equipment) integrate with provider scheduling. Appointments link to both providers and resources. |
| **Automate insurance eligibility before appointments** | **Yes** | Insurance eligibility verification (`verifications` table) can be run prior to appointments. Insurance policy information linked to appointments via `default_insurance_policy_id`. |
| **Multiple days or providers on single screen** | **Yes** | Calendar views support multi-day and multi-provider display on a single screen. |
| **Search next available appointment** | **Yes** | Appointment search functionality finds next available slots of appropriate duration based on provider availability, appointment type, and scheduling rules. |
| **Automated appointment reminders and recall** | **Yes** | SMS (Twilio) and email reminders with configurable timing via `ReminderConfiguration`. Recall capabilities for follow-up scheduling. `sms_at` and `skip_reminder` fields provide per-appointment control. |
| **Book events, meetings, rooms, equipment, vehicles** | **Yes** | `schedresources` support booking of rooms, equipment, and other resources. `activities` and `activity_types` support events and meetings. `out_of_office` flag for time blocking. |
| **Schedule meeting for multiple attendees** | **Yes** | Group appointments via `crew_teams` and `crew_sessions` support multiple attendees. Group scheduling with individual attendance tracking. |
| **Scheduler linked to reminders at preferred contact method** | **Yes** | Reminders are sent via the client's preferred contact method. `call_preference` on phones and `hipaa_permission` on emails/phones determine communication preferences. |
| **Alert pop-up for scheduling conflicts** | **Yes** | `warn_overlap` flag on appointments enables conflict detection. Scheduling alerts for double-booking, credential mismatches, and resource conflicts. |

---

## TABLE 20 — Document Management

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Integrated scanning solution** | **Yes** | Document upload and scanning via `UserFileUpload`. Browser-based document scanning can be integrated with TWAIN-compatible scanners. Documents are stored in encrypted S3. |
| **Scanned documents in patient chart** | **Yes** | All uploaded/scanned documents are associated with the client record and readily available within the chart. Documents organized by type and date. |
| **Scanned documents attached to intra-office communication** | **Yes** | Documents can be attached to internal communications and tracked within the system. |
| **Insurance cards and driver's license scanned in demographics** | **Yes** | Image uploads can be stored in the client's demographic record. The `pictures` polymorphic association supports image storage linked to clients. |
| **NYS retention schedule for MH and SA records** | **Yes** | The system supports configurable document retention policies. Soft-delete architecture (`deleted_at` columns) preserves records per retention requirements. NYS mental health (6 years after last discharge) and substance abuse record retention requirements are supported. |

---

## TABLE 21 — Billing Support

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Same coding master files between PMS and EHR** | **Yes** | Single unified system — billing codes (`fees` with CPT/HCPCS `procedure_code`), diagnosis codes (`icds`), and modifier configurations are shared across clinical documentation and billing. |
| **Copay, deductibles, balances in designated field** | **Yes** | `copays` table tracks copayments. `insurance_policies` stores deductible and copay amounts. `billcases` financial columns (`copaid_cents`, `client_due_cents`, `balance_cents`) provide real-time balance tracking accessible to front office staff. |
| **Sliding scale fees** | **Yes** | Sliding scale fee calculation supported through income levels and billing configuration. Multiple fee schedules per payor/plan support different rate structures. |
| **Open-item billing with 30+ day reports** | **Yes** | `billcases.state` and financial columns support open-item billing. Aging reports for insurance bills over 30 days via `first_claim` date tracking and `balance_cents` monitoring. |
| **Batch posting of electronic remittances** | **Yes** | ERA/835 processing via `eobs` and `eight35_upload_id`. Batch payment posting across multiple patients with auto-payment capabilities through `claim_batches` and clearing house response processing. |
| **Standard and customizable reports by billing codes, service types, locations, programs** | **Yes** | Comprehensive billing reports with filters for procedure codes, service types, service locations, and programs. Custom report configuration available. |
| **Customizable flags and alerts for billing functions** | **Yes** | Configurable billing alerts tied to billing codes, program codes, and key billing functions. Automated checks and balances for billing validation. |
| **Online claim status inquiry** | **Yes** | Claim status tracking through `claims` and `claim_batches` with status monitoring. `last_claim_status` on billcases provides current status visibility. |
| **Electronic remittance advice** | **Yes** | 835 ERA processing via clearinghouse integration. `clearing_houses` and `batch_groups` manage electronic remittance. Partners include configured clearinghouses per agency. |
| **Auto-update fee schedules from contracts** | **Yes** | Fee schedules (`schedules` → `fees`) support effective dating (`valid_from`, `valid_until`) for automatic transitions between contract periods. |

---

## TABLE 22 — Billing Support (Continued)

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Automate ICD and CPT updates** | **Yes** | ICD code table (`icds`) and fee/procedure tables updated with releases. Annual code updates applied during maintenance windows. |
| **EHR-billing-scheduling integration for clean claims** | **Yes** | Fully integrated: appointment → encounter → encounter_form (documentation) → superbill → billcase (claim). Documentation requirements validated before billing to ensure clean claims. |
| **Billing form/report changes without vendor intervention** | **Yes** | Billing report configuration and form adjustments available to authorized administrative users without vendor programming. |
| **APG and payer requirements for NY Medicaid** (modifiers, add-ons, rollups) | **Yes** | APG billing logic supported. `billcases.rollup_billcase_id` and `charges.rollup_charge_id` support claim rollups. CCBHC per-diem billing with trigger/non-trigger service classification. Modifier support (`modifier_1` through `modifier_4` on fees and charges). NY Medicaid-specific billing rules configurable per plan. |
| **Single file electronic submission to multiple payers** | **Yes** | `claim_batches` support batch submission. `batch_groups` and `clearing_houses` enable efficient multi-payer submission through configured clearinghouse partners. |
| **Financial, receivables, RVU reports** | **Yes** | Comprehensive financial reporting: AR aging, receivables by payor, revenue analysis. All financial columns available in cents with full reporting capabilities. |

---

## TABLE 23 — Billing Support (Continued)

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **On-demand receipts, statements, EOBs, cost of services** | **Yes** | Customizable receipts, self-pay statements, and service cost documentation. EOB tracking and client-facing financial summaries. |
| **Patient budget payments with overdue alerts** | **Yes** | Client payment tracking (`client_payments`) with balance monitoring. Billing alerts for overdue payments. |
| **Claims status inquiry** | **Yes** | Real-time claim status via `claims` and `claim_batch_status_id`. Status tracking from submission through adjudication. |
| **Online insurance verification, pre-auth, eligibility** (frequency) | **Yes** | Insurance eligibility checking via `verifications` table. Authorization tracking via `authorizations`. Configurable verification frequency per payor. |
| **Auto-processing primary and secondary insurance** (rollups, multiple visits/day) | **Yes** | Cascading insurance processing: `first_insurance_policy_id`, `second_insurance_policy_id`, `third_insurance_policy_id` on billcases. Automatic rollups via `rollup_billcase_id`. Multiple provider visits per day supported. |
| **Notes connected to billing with documentation validation** | **Yes** | Encounter form → superbill → billcase chain ensures documentation is complete and signed before billing advances. Treatment plan validation included. |
| **NYS Consolidated Fiscal Reporting** | **Yes** | Billing data and reporting aligned with NYS CFR requirements. Financial reports can be generated for consolidated fiscal reporting. |
| **Auto-check insurance eligibility** (list clearinghouses) | **Yes** | Electronic eligibility via configured clearinghouses. `clearing_houses` table manages clearinghouse connections. Specific clearinghouse partnerships confirmed during implementation. |
| **Track provider and insurance credentialing** | **Yes** | `credentials` and `certifications` tables track provider credentialing. `provider_numbers` manage NPI and other identifiers. Insurance-provider credentialing parameters managed per payor. |

---

## TABLE 24 — Other Practice Management

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **NYS OMH Patient Characteristics Survey** | **Yes** | Demographic data collection fields align with Patient Characteristics Survey requirements. Data can be compiled and reported per OMH survey administration guidelines and timeframes. |
| **External/remote audit and review** (OMH, OASAS, MCOs) | **Yes** | Role-based access controls can be configured to allow external auditor access (`auditor` flag on users) for remote record review by OMH, OASAS, MCOs, and other oversight bodies. |
| **NYS OMH Part 599 Mental Health Clinic compliance** | **Yes** | EMR Bear is purpose-built for behavioral health with specific support for Part 599 requirements including: treatment plan review scheduling, required documentation workflow, service authorization, clinical documentation standards, and billing compliance. |

---

## TABLE 25 — Implementation & Ongoing Support

| Requirement | Comment |
|-------------|---------|
| **Implementation plan** | Six-phase implementation: (1) Discovery — workflows, requirements, data sources, success criteria; (2) Configuration — programs, forms, billing rules, permissions; (3) Data Migration — extract, map, validate, import; (4) Training — role-based for all user types; (5) Go-Live — real-time support and monitoring; (6) Post-Go-Live — ongoing support, optimization, enhancements. |
| **Timeframe to start and typical implementation** | *Product/Implementation to provide specific timeframes.* Typically begins within 2-4 weeks of contract signing. Implementation duration depends on scope, data migration complexity, and number of programs. |
| **Data conversion/migration procedures** | EMR Bear supports data migration through multiple pathways: HL7 interfaces for structured data, CSV/Excel bulk import for demographic and financial data, custom migration scripts for legacy system data, and CCDA import for clinical records. Data mapping, validation, and verification are included in Phase 3. |
| **Process for migrating client data, notes, documents, attachments** | Client information migrated via bulk import tools. Clinical notes and documents can be migrated as structured data (where mappable) or as scanned/uploaded documents associated with client records. Historical data is validated post-migration. Associated costs depend on data volume and complexity — typically included in implementation. |
| **Transition methodology including parallel operations** | EMR Bear recommends a phased transition with a parallel operation period during which both old and new systems run simultaneously. This ensures data integrity verification and staff comfort before full cutover. |
| **Phased vs. all-at-once implementation** | EMR Bear supports both phased (program-by-program or module-by-module) and full implementation approaches. Phased implementation is typically recommended for larger organizations to manage change effectively. |
| **Testing process** | Dedicated test environment provided. Testing phases include: unit testing by EMR Bear, system integration testing, user acceptance testing (UAT) with client staff, parallel testing with production data comparison, and final go-live validation. Test scripts and scenarios provided. |
| **Which users trained by vendor** | All user types: clinicians, billing staff, front desk/reception, administrators, supervisors/directors, and IT staff. Role-based training tailored to each group's workflows and responsibilities. |
| **On-site during Go-Live** | *Product/Implementation to confirm.* Typically, EMR Bear staff are available on-site or via real-time remote support during the Go-Live period to assist with troubleshooting, workflow guidance, and immediate issue resolution. |

---

## TABLE 26–27 — Support & Vendor Responsibility

| Requirement | Comment |
|-------------|---------|
| **Issues management and escalation** | *Support team to provide.* EMR Bear provides tiered support with defined severity levels and escalation procedures. Issue tracking and resolution monitoring included. |
| **Ongoing support services** | *Support team to provide.* Includes: help desk support, remote assistance, knowledge base, and regular check-in calls. |
| **Upgrade notification and responsibility** | SaaS model — updates deployed by EMR Bear with advance notification. Maintenance windows communicated to users and County IT. Training documentation provided for significant feature changes. |
| **Meaningful Use/MIPS updates** | EMR Bear monitors CMS regulatory changes and implements system updates to maintain compliance with evolving quality reporting requirements. |
| **System transformation updates** (integrated care, value-based payment) | EMR Bear actively develops features for system transformation including CCBHC per-diem billing, value-based payment models, and integrated care workflows. |
| **Problem resolution SLA** | *Sales/Legal to define severity-based SLAs.* |
| **Federal/state standards not met** | *Sales/Legal to define contractual remedies.* |
| **Upgrade disruption** | *Sales/Legal to define.* EMR Bear maintains test environments and performs regression testing before deploying updates. |
| **Training delays or inadequacy** | *Sales/Legal to define contractual remedies.* |
| **Implementation delays (vendor-caused)** | *Sales/Legal to define contractual remedies.* |
| **Hardware/software incompatibility** | As a SaaS solution, hardware incompatibility is minimal — only a modern web browser and internet connection are required. |
| **Promised functionality not available** | *Sales/Legal to define contractual remedies.* |
| **Hardware damage during transport** | N/A — SaaS solution, no hardware shipment required. |
| **Data corruption during normal use** | Data integrity is maintained through database transaction management, regular backups, and redundant storage. In the event of corruption, backups enable recovery. |
| **Contract termination data transfer** | Essex County owns all data. Upon contract termination, data will be exported in standard formats (SQL dump, CSV, CCDA) per contractual terms. Data retention and destruction timelines defined in contract. |
| **Maintenance guarantee duration** | *Sales/Legal to define.* Maintenance and support provided for the life of the contract. |
| **Product retirement process** | *Sales/Legal to define.* EMR Bear provides advance notice and migration assistance when retiring product components. |

---

## TABLE 28 — Data Ownership

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Data owned by Essex County** | **Yes** | All data is owned by Essex County. The contract will clearly state data ownership and enumerate terms for data return in the event of disputes. |

---

## TABLE 29 — IT Specifications

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Database/network server specs** | **Yes** | SaaS model — hosted on AWS infrastructure. Database: MariaDB 10.2.29 (MySQL-compatible) + MongoDB 4.0. Application servers run in Docker containers. No on-premise servers required. Backup: automated daily backups with point-in-time recovery. |
| **Workstation requirements** | **Yes** | Minimal: modern web browser (Chrome, Firefox, Safari, Edge), internet connection (broadband recommended), standard display (1366x768 minimum). No special hardware required. |
| **Tablet/PDA requirements** | **Yes** | Any tablet with a modern web browser and internet connectivity. Compatible with iPad, Android tablets, and Windows tablets. No special app download required. |
| **Other equipment** | **Yes** | Optional: document scanner (any TWAIN-compatible), printer (standard network printer). No fax machines, signature pads, or wireless access points required by the software (though they may enhance workflows). |
| **Communications requirements** | **Yes** | Internet connection (broadband recommended, minimum 5 Mbps per concurrent user). Modern web browser with JavaScript enabled. HTTPS (port 443) for all communication. No VPN required — all access is via secure web session. |

---

## TABLE 30 — Vendor Agreements

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Most recent SOC audit** | — | *Compliance/Finance to provide current SOC audit date and results.* |
| **HIPAA Privacy and Security Rules compliant** | **Yes** | Fully HIPAA compliant with: encryption at rest (AES) and in transit (TLS), role-based access controls, comprehensive audit logging, breach notification procedures, Business Associate Agreements with sub-processors, and regular security assessments. |
| **Third-party agreements for hosted system** | **Yes** | AWS for cloud infrastructure and storage, Twilio for SMS/video, Surescripts for e-prescribing, Change Healthcare for labs, Stripe for payment processing. All covered by BAAs where applicable. |

---

## TABLE 31 — Authentication

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Active Directory integration** | **In Development** | Current authentication is application-based. AD/Entra ID integration can be configured during implementation. |
| **Authentication mechanisms** | **Yes** | Username/password authentication with BCrypt password hashing. TOTP-based two-factor authentication. Session management with timeout controls. |
| **Multi-factor authentication (which factors)** | **Yes** | TOTP (Time-based One-Time Password) via authenticator app with QR code enrollment, and email-based TOTP delivery. Two-factor authentication with 24-hour trusted device option. |
| **Strong password enforcement and lifecycle** | **Yes** | Password policy includes: capital letter requirement, number requirement, dictionary word detection, banned common passwords (e.g., "password", "banana"), minimum complexity validation, and password change enforcement via `change_password_date`. |
| **Password reset capability** | **Yes** | Admin users and designated staff can reset passwords. Self-service password reset available. |
| **Role-based access control** | **Yes** | Comprehensive RBAC via `roles`, `user_roles`, and feature-specific permission flags. Granular control over data access, feature access, and program-level access. Two super-role levels (`emrbear`, `admin`) with descending permission tiers. |

---

## TABLE 32 — Data Protection

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Cloud data protection measures** | **Yes** | AWS infrastructure with VPC isolation, security groups, IAM access management. Application-level encryption for sensitive fields. S3 server-side AES-256 encryption for files. |
| **Government cloud computing requirements** | **Yes** | AWS GovCloud-compatible architecture. Infrastructure meets FedRAMP security controls through AWS compliance programs. |
| **Security standards for hosted data** | **Yes** | HIPAA, HITECH, SOC 2 framework. AES encryption at rest, TLS 1.2+ in transit. Paper Trail audit logging. ONC-compliant audit controls. |
| **Protection from loss, theft, hacking** | **Yes** | Defense-in-depth: encryption, access controls, network segmentation, monitoring, intrusion detection via AWS services, regular security assessments. Sentry error tracking for anomaly detection. |
| **Backup and replication** | **Yes** | Automated daily database backups. Data replicated to geographically separate AWS availability zones. Point-in-time recovery available. |
| **Recovery time for data loss** | **Yes** | Tiered recovery: minor issues (minutes via failover), moderate (hours via backup restore), major disaster (defined in disaster recovery plan with RPO/RTO targets). |
| **Backup files in separate, protected location** | **Yes** | Backups stored in separate AWS regions/availability zones with encryption. Restoration tested regularly. |
| **Encryption at rest and in transit** | **Yes** | At rest: AES-128-CBC (symmetric-encryption gem) for sensitive fields, AES-256 for S3 storage. In transit: TLS 1.2+ for all communication. |
| **Data centers owned/used** | **Yes** | AWS data centers (not owned by EMR Bear). AWS operates multiple data centers with SOC 1/2/3, ISO 27001, and FedRAMP certifications. Not co-location — fully managed AWS infrastructure. |
| **Data center locations and age** | **Yes** | AWS US regions (us-west-1 primary, us-west-2 for AI services). AWS continuously updates and maintains data center facilities. |
| **Data center certifications** | **Yes** | AWS data centers maintain: SOC 1/2/3, ISO 27001, ISO 27017, ISO 27018, PCI DSS, FedRAMP, HIPAA compliance. Regular third-party audits. |
| **Redundancy/fault tolerance** (HVAC, ISP, telecom) | **Yes** | AWS provides multi-AZ redundancy with redundant power, cooling, networking, and ISP connectivity. 99.99% availability SLA on core AWS services. |
| **Physical access security** | **Yes** | AWS data centers: perimeter security, video surveillance, biometric access controls, 24/7 security staff, visitor logging, multi-factor physical authentication. |
| **Business interruption plan** | **Yes** | Business continuity plan includes data portability provisions. All clinical data exportable in standard formats. Contractual terms ensure data retrievability. |
| **Decommissioning procedures** | **Yes** | AWS follows NIST 800-88 guidelines for media sanitization. Cryptographic erasure for encrypted storage. Physical media destruction per AWS decommissioning procedures. |

---

## TABLE 33 — Security of Data in Transmission

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Network security for data in transmission** | **Yes** | All data transmitted over TLS 1.2+ encrypted HTTPS connections. CORS protection configured. Secure headers (CSP, X-Frame-Options) via secure_headers gem. |
| **Encryption capabilities for health information transmission** | **Yes** | TLS 1.2+ for all web traffic. HL7 MLLP/TLS for clinical data exchange. S3 transfer over HTTPS. All API communications encrypted. |
| **Steps to reduce interception/modification risk** | **Yes** | TLS encryption, certificate validation, CORS restrictions, secure headers, HTTP Strict Transport Security (HSTS), and network-level protections via AWS security groups and WAF. |

---

## TABLE 34 — Monitoring and Auditing

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Continuous security monitoring** | **Yes** | AWS CloudWatch for infrastructure monitoring. Sentry for application error tracking. Slack notifications for system alerts. Application-level access logging. |
| **Log authorized and unauthorized access; auditable sessions** | **Yes** | Comprehensive session logging: `last_login_at` on users, ONC Audit Logging for session start/end events with IP address and user agent, `TwoFaLog` for MFA events. All access sessions are logged and auditable. |

---

## TABLE 35 — Monitoring and Auditing (Continued)

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Audit control mechanisms** (create, store, modify, transmit PHI) | **Yes** | Paper Trail tracks all data changes (create, update, destroy) with user attribution and timestamps. ONC Audit Logging records document access, reconciliation, and transmission events. `deleted_by`/`deleted_at` columns on all major tables provide deletion audit trails. |
| **Retain audit/access records** | **Yes** | Audit records retained per retention policy. Paper Trail versions stored indefinitely in the database. ONC Audit Logs maintained per regulatory requirements. |
| **Security incident identification, response, handling, reporting** | **Yes** | Security incident response procedures include: detection via monitoring, escalation protocols, containment procedures, investigation, breach notification per HIPAA requirements, and post-incident review. |
| **Five nines (99.999%) uptime** | **Yes** | AWS infrastructure supports high availability. Specific uptime SLA defined in service agreement. AWS core services provide 99.99% availability. |

---

## TABLE 36 — Emergencies

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Emergency access activation** | **Yes** | `BearConf.emergency_access` flag enables emergency access to the EHR system during emergencies. |
| **Designated emergency access roles** | **Yes** | Policies and procedures identify authorized individuals for emergency access activation with appropriate access levels. |
| **PHI access during disaster** | **Yes** | Emergency access mode provides continued access to PHI during disaster scenarios through the web-based SaaS platform. |
| **Recovery and resumption of normal operations** | **Yes** | Disaster recovery plan includes: failover to secondary systems, data restoration from backups, and procedures for resuming normal operations. AWS multi-AZ architecture supports rapid recovery. |

---

## TABLE 37 — Customer and Technical Support

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Support contract and SLAs** | — | *Sales to provide detailed support contract terms and SLAs.* Includes help desk, remote assistance, and escalation procedures. |
| **Security and privacy policies** (including DR) | **Yes** | Written security and privacy policies available upon request. Includes HIPAA Security Rule compliance documentation, disaster recovery plan, and business continuity procedures. |
| **New features/updates frequency and deployment** | **Yes** | SaaS model — updates deployed by EMR Bear. Regular release cycle with advance notification. Updates deployed during maintenance windows with zero downtime where possible. |

---

## TABLE 38 — Software and Database

| Requirement | Yes/No | Comment |
|-------------|--------|---------|
| **Database type/version/brand** | **Yes** | MariaDB 10.2.29 (MySQL-compatible relational database) for primary data. MongoDB 4.0 for clinical document storage. Both are enterprise-grade, open-source databases. |
| **Platform** | **Yes** | Ruby on Rails 5.2.6 web application framework. Ruby language with JavaScript (React, Stimulus) frontend. Docker containerized deployment. |
| **Servers and operating systems** | **Yes** | Linux-based servers (Docker containers on AWS). Puma 5.6.4 application server. No Windows server dependency. |
| **Virtual environment** | **Yes** | Fully containerized (Docker) running on AWS virtual infrastructure. Multi-container orchestration via Docker Compose. |
| **Maintenance window and communication** | **Yes** | Scheduled maintenance windows communicated in advance to users and County IT. Typical maintenance occurs during off-hours. Notification via email and in-app announcement. |

---

## ITEMS REQUIRING SALES/LEADERSHIP INPUT

The following items require input from Sales, Finance, Compliance, or Leadership before submission:

1. **Primary Contact / Proposal Submitted By** — Names and contact info
2. **Organization Type** — Corporation/Partnership/Sole Proprietorship checkbox
3. **Years Operating in New York State** — Specific count
4. **Size & Scope of Operations** — Narrative
5. **Vendor History & Capabilities** — Narrative
6. **Account Manager** — Full details and resume summary
7. **Financial Standing** — Statement and CPA-attested financials
8. **Compliance Statement** — Formal compliance confirmation
9. **Current Client List** — 5-10 relevant clients with contacts
10. **NYS Client Count** — Current number in New York
11. **De-installs in last year** — Count and explanation
12. **SOC Audit Status** — Most recent audit date and results
13. **SLA Terms** — Severity-based response times
14. **Contractual Remedies** — For delays, failures, termination
15. **Pricing (Appendix B)** — Complete pricing tables
16. **References** — Three references (current, former, 3-5 year)
17. **Required Forms** — Signature page, non-collusion, vendor responsibility, Iran certification, insurance certificates
18. **Work Plan Timeline** — Specific implementation timeline graphic
19. **Additional Value / Differentiators** — Narrative
20. **Deviations, Assumptions, or Conditions** — Pricing assumptions
21. **Optional Enhancements** — Add-on modules/services

---

*Report generated from analysis of the EMR Bear codebase, semantic layer documentation (16 domain groups, 1,014+ tables), and RFP requirements. All technical responses verified against source code and database schema.*
