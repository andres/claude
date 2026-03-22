-- ============================================================
-- qs_appointments — Appointment/service activity for AWS QuickSight
-- One row per appointment. Includes status (computed from timestamps),
-- client, provider, program, event type, and location.
-- Deleted appointments are included with status = 'deleted'.
-- ============================================================
CREATE OR REPLACE VIEW qs_appointments AS
SELECT
  a.id                                                          AS appointment_id,
  a.client_id                                                   AS client_id,
  a.user_id                                                     AS provider_id,
  a.program_enrollment_id                                       AS enrollment_id,
  a.program_id                                                  AS program_id,

  -- Client name
  CONCAT(COALESCE(cn.first, ''), ' ', COALESCE(cn.last, ''))    AS client_name,

  -- Provider name
  CONCAT(COALESCE(pn.first, ''), ' ', COALESCE(pn.last, ''))    AS provider_name,

  -- Program
  pr.name                                                       AS program_name,
  pr.acronym                                                    AS program_acronym,

  -- Appointment type
  at.name                                                       AS appointment_type,

  -- Event type
  et.name                                                       AS event_type,
  et.is_appointment                                             AS is_individual,
  et.is_group                                                   AS is_group,

  -- Location
  loc.name                                                      AS location_name,
  loc.city                                                      AS location_city,

  -- Scheduling
  DATE(a.date_time_starts)                                      AS appointment_date,
  a.date_time_starts                                            AS starts_at,
  a.date_time_ends                                              AS ends_at,
  a.duration                                                    AS duration_minutes,

  -- Status (computed from timestamps, priority order)
  CASE
    WHEN a.deleted_at    IS NOT NULL THEN 'deleted'
    WHEN a.cancelled_at  IS NOT NULL THEN 'cancelled'
    WHEN a.noshow_at     IS NOT NULL THEN 'no_show'
    WHEN a.checked_out_at IS NOT NULL THEN 'completed'
    WHEN a.checked_in_at IS NOT NULL THEN 'checked_in'
    WHEN a.confirmed_at  IS NOT NULL THEN 'confirmed'
    ELSE 'scheduled'
  END                                                           AS status,

  -- Status timestamps
  a.confirmed_at                                                AS confirmed_at,
  a.checked_in_at                                               AS checked_in_at,
  a.checked_out_at                                              AS checked_out_at,
  a.cancelled_at                                                AS cancelled_at,
  a.noshow_at                                                   AS noshow_at,

  -- Cancellation detail
  a.cancel_reason                                               AS cancel_reason,
  a.cancel_note                                                 AS cancel_note,
  a.cancel_late                                                 AS is_late_cancel,

  -- No-show detail
  a.noshow_reason                                               AS noshow_reason,

  -- Time in office (minutes between check-in and check-out)
  CASE
    WHEN a.checked_in_at IS NOT NULL AND a.checked_out_at IS NOT NULL
      THEN TIMESTAMPDIFF(MINUTE, a.checked_in_at, a.checked_out_at)
    ELSE NULL
  END                                                           AS time_in_office_minutes,

  -- Flags
  a.is_all_day                                                  AS is_all_day,
  a.out_of_office                                               AS is_out_of_office,
  CASE WHEN a.group = 1 THEN 1 ELSE 0 END                       AS is_group_appointment,

  -- Audit
  a.created_at                                                  AS created_at,
  a.deleted_at                                                  AS deleted_at

FROM appointments a

-- Client name
LEFT JOIN names cn
  ON cn.person_id = a.client_id
  AND cn.deleted_at IS NULL
  AND cn.id = (
    SELECT id FROM names
    WHERE person_id = a.client_id AND deleted_at IS NULL
    ORDER BY created_at DESC LIMIT 1
  )

-- Provider name (users live in people table via STI)
LEFT JOIN names pn
  ON pn.person_id = a.user_id
  AND pn.deleted_at IS NULL
  AND pn.id = (
    SELECT id FROM names
    WHERE person_id = a.user_id AND deleted_at IS NULL
    ORDER BY created_at DESC LIMIT 1
  )

-- Program
LEFT JOIN programs pr
  ON pr.id = a.program_id

-- Appointment type
LEFT JOIN appointment_types at
  ON at.id = a.appointment_type_id

-- Event type
LEFT JOIN event_types et
  ON et.id = a.event_type_id

-- Location
LEFT JOIN locations loc
  ON loc.id = a.location_id
  AND loc.deleted_at IS NULL
;
