-- ============================================================
-- qs_program_enrollments — Program enrollment history for AWS QuickSight
-- One row per enrollment. Includes program info, status,
-- enrollment/discharge dates, duration, and clinical context.
-- ============================================================
CREATE OR REPLACE VIEW qs_program_enrollments AS
SELECT
  pe.id                                                         AS enrollment_id,
  pe.client_id                                                  AS client_id,

  -- Client name (from qs_clients pattern)
  CONCAT(COALESCE(n.first, ''), ' ', COALESCE(n.last, ''))      AS client_name,

  -- Program
  pe.program_id                                                 AS program_id,
  pr.name                                                       AS program_name,
  pr.acronym                                                    AS program_acronym,
  pr.active                                                     AS program_active,
  pr.tfc                                                        AS is_tfc,
  pr.adoption                                                   AS is_adoption,
  pr.otp                                                        AS is_otp,
  CASE WHEN pr.oasas_program_id IS NOT NULL THEN 1 ELSE 0 END   AS is_oasas,
  pr.inpatient                                                  AS is_inpatient,
  pr.treatment_family                                           AS is_treatment_family,

  -- Enrollment dates
  pe.requested_at                                               AS requested_at,
  pe.effective_enrollment_date                                  AS enrollment_date,
  pe.approved_at                                                AS approved_at,
  pe.denied_at                                                  AS denied_at,
  pe.expires_at                                                 AS discharge_date,
  pe.handoff                                                    AS handoff_date,

  -- Enrollment status (computed)
  CASE
    WHEN pe.denied_at  IS NOT NULL                                        THEN 'denied'
    WHEN pe.expires_at IS NOT NULL AND pe.expires_at <= NOW()             THEN 'discharged'
    WHEN pe.approved_at IS NOT NULL
      AND (pe.expires_at IS NULL OR pe.expires_at > NOW())                THEN 'active'
    ELSE 'pending'
  END                                                           AS enrollment_status,

  -- Duration in days
  CASE
    WHEN pe.effective_enrollment_date IS NOT NULL AND pe.expires_at IS NOT NULL
      THEN DATEDIFF(pe.expires_at, pe.effective_enrollment_date)
    WHEN pe.effective_enrollment_date IS NOT NULL AND pe.expires_at IS NULL
      THEN DATEDIFF(CURDATE(), pe.effective_enrollment_date)
    ELSE NULL
  END                                                           AS duration_days,

  -- Discharge info
  pe.closure_reason                                             AS closure_reason,
  pe.successful_discharge                                       AS successful_discharge,
  pe.referral_status                                            AS referral_status,

  -- Clinical context
  pe.severity                                                   AS severity,
  pe.referral_source                                            AS referral_source,
  el.label                                                      AS enrollment_level,

  -- Location
  loc.name                                                      AS location_name,
  loc.city                                                      AS location_city,

  -- Auto-enrolled flag
  pe.auto_enrolled                                              AS auto_enrolled,

  -- Audit
  pe.created_at                                                 AS created_at,
  pe.updated_at                                                 AS updated_at

FROM program_enrollments pe

-- Client name
LEFT JOIN names n
  ON n.person_id = pe.client_id
  AND n.deleted_at IS NULL
  AND n.id = (
    SELECT id FROM names
    WHERE person_id = pe.client_id AND deleted_at IS NULL
    ORDER BY created_at DESC LIMIT 1
  )

-- Program
LEFT JOIN programs pr
  ON pr.id = pe.program_id

-- Enrollment level
LEFT JOIN enrollment_levels el
  ON el.id = pe.enrollment_level_id
  AND el.deleted_at IS NULL

-- Location via program_location
LEFT JOIN program_locations pl
  ON pl.id = pe.program_location_id

LEFT JOIN locations loc
  ON loc.id = COALESCE(pl.location_id, pe.location_id)
  AND loc.deleted_at IS NULL
;
