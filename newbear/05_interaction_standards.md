# 05 — Interaction Standards

Rules for how users interact with the application at the component level.
These apply to every domain, every screen, every form. No exceptions.

---

## Validation

### Dual Validation — Model and Screen

Every validation rule that exists at the API/model level **must also exist on screen**.
The user should never be able to submit something the API will reject.

- Required fields are visually marked and enforced before the action button enables
- Format rules (email, phone, date, SSN, NPI) validate on blur or as-you-type
- Business rules (date ranges, dependency between fields) validate in real time
- The submit/save/action button is **disabled** until all visible validations pass
- If a field becomes invalid after being valid (e.g., user clears a required field),
  the button disables again immediately

### Validation Feedback

- Invalid fields show inline error messages — not just a red border, a specific message
  ("Date of birth cannot be in the future", not "Invalid value")
- Error messages appear next to the field, not in a toast or a modal
- When multiple fields are invalid, all errors show simultaneously — don't make the user
  fix one, submit, discover the next
- On submit failure (network error, server-side validation the client missed), scroll to
  and focus the first problem field

### Server as Final Authority

Client-side validation is for UX speed. The API always re-validates everything.
If the client and server disagree, the server wins and the client updates its rules
on the next load (validation rules are API-driven, not hardcoded in the frontend).

---

## Form Behavior

### Field Interaction

- Tab order follows visual layout — left to right, top to bottom
- Enter in a text field moves to the next field (not submit, unless it's the last field)
- Dropdowns are searchable/filterable by typing
- Date fields accept typed input (MM/DD/YYYY) and calendar picker — both work
- Phone and SSN fields auto-format as the user types
- Fields that depend on other fields (e.g., plan dropdown depends on payor selection)
  disable until the parent is filled, then auto-load options

### Auto-Save and Drafts

- Long forms (clinical documentation, treatment plans) auto-save as draft on a timer
  and on blur of each section
- The user sees a "saved" indicator with timestamp — never wonder if work was lost
- Drafts are resumable from any device
- Explicit "Save" button exists for users who want manual control
- Navigating away from unsaved changes prompts confirmation

### Defaults and Smart Pre-fill

- Fields with obvious defaults are pre-filled (today's date, logged-in user as provider,
  client's primary insurance, client's enrolled program)
- AI-suggested values are visually distinct from system defaults (different styling or
  a small indicator) so the user knows what came from AI vs. what came from data
- Pre-filled fields are still editable — defaults are suggestions, not locks

---

## Action Buttons

### State Rules

| Button State | When | Visual |
|-------------|------|--------|
| **Disabled** | Validation errors exist, or required fields are empty | Grayed out, no hover effect, tooltip explains why |
| **Ready** | All validations pass | Full color, hover effect active |
| **Loading** | Action submitted, waiting for response | Spinner replaces label, button disabled to prevent double-submit |
| **Success** | Action completed | Brief success indicator (checkmark), then transition to next state |
| **Error** | Action failed | Button returns to Ready, error message displayed |

### No Double Submits

- After click, the button immediately enters Loading state
- A second click during Loading does nothing
- This applies to every action button in the system, not just forms

### Destructive Actions

- Delete, cancel, void, and other irreversible actions require confirmation
- Confirmation is inline (not a modal) when possible — "Are you sure? [Yes, delete] [No, keep]"
- Destructive buttons are visually distinct (red or separate from primary actions)
- Bulk destructive actions require typing confirmation text

---

## Loading and Empty States

### Loading

- Skeleton screens for initial page loads (not spinners — skeletons preserve layout)
- Inline spinners for partial updates (e.g., loading a dropdown's options)
- If a load takes more than 5 seconds, show a message ("Still loading — this is taking
  longer than usual")
- Never show a blank screen while loading

### Empty States

- Empty lists show a helpful message and a primary action ("No appointments today.
  [Schedule one]")
- Empty states are an opportunity, not an error
- First-time-use empty states guide the user on what to do next

---

## Navigation

### Breadcrumbs and Context

- The user always knows: which client, which program, which encounter they're working in
- Breadcrumb trail at the top of every screen
- Client context (name, DOB, photo, alerts) persists in a sticky header/sidebar while
  working within a client record

### Back and Undo

- Browser back button works correctly everywhere (no broken history states)
- Undo is available for the last destructive action (inline, not Ctrl+Z)
- "Recent" list shows the last 10 clients/records the user accessed

---

## Tables and Lists

### Standard Behaviors

- All list views support: search, filter, sort, column visibility, pagination
- Filters are persistent within a session — navigating away and back remembers them
- Sort is single-column by default, shift-click for multi-column
- Row click navigates to detail view; actions (edit, delete) are in a row-level menu
- Bulk selection with select-all, shift-click range, and bulk action bar

### Pagination

- Cursor-based (not page numbers) for data consistency
- "Load more" or infinite scroll for clinical lists (not page 1, 2, 3)
- Record count shown ("Showing 25 of 142 clients")

---

## Keyboard and Accessibility

### Keyboard

- Every action reachable by keyboard
- Common shortcuts documented and discoverable (? opens shortcut reference)
- Escape closes modals, drawers, and dropdowns
- Ctrl+S / Cmd+S saves the current form (overrides browser default)

### Accessibility

- WCAG 2.1 AA minimum
- All form fields have associated labels (not just placeholder text)
- Color is never the only indicator of state (icons or text accompany color changes)
- Screen reader announcements for dynamic content updates
- Focus management after actions (after delete, focus moves to next item, not to top of page)

---

## Voice Interaction Feedback

When the voice-to-intent path is active:

- **Listening indicator:** Visible, animated mic icon — user knows the system is hearing them
- **Live transcription:** What the system hears appears in real time on screen
- **Intent preview:** Before executing, the system shows what it's about to do:
  "Navigate to John Smith's record" / "Schedule appointment for tomorrow at 2pm"
- **Confirm or correct:** User can confirm (voice: "yes" / click: confirm button) or
  correct ("no, I said 3pm")
- **Screen reacts:** After confirmation, the UI transitions smoothly to the result —
  same animations as a click action, not a jarring jump
- **Error recovery:** If intent can't be resolved: "I didn't understand that. Did you mean:
  [option A] [option B] [try again]?"

---

## Notifications and Feedback

### In-App Feedback

| Type | Presentation | Duration |
|------|-------------|----------|
| Success | Subtle toast, bottom-right | 3 seconds, auto-dismiss |
| Warning | Persistent inline banner | Until dismissed or resolved |
| Error | Inline at point of failure + toast | Until resolved |
| Info | Toast, bottom-right | 5 seconds, auto-dismiss |

### No Alert Fatigue

- Notifications are batched where possible ("3 forms need your signature" not 3 separate alerts)
- Users control notification preferences per category
- Critical alerts (safety, crisis) override preferences and cannot be silenced
