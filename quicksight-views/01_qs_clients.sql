-- ============================================================
-- qs_clients — Client demographics for AWS QuickSight
-- One row per client. Includes primary name, address, phone,
-- email, and primary insurance. Historical clients included
-- (deleted_at IS NOT NULL rows have is_active = 0).
-- ============================================================
CREATE OR REPLACE VIEW qs_clients AS
SELECT
  p.id                                                          AS client_id,
  p.client_number                                               AS client_number,

  -- Name (current, non-deleted name record)
  n.first                                                       AS first_name,
  n.last                                                        AS last_name,
  CONCAT(COALESCE(n.first, ''), ' ', COALESCE(n.last, ''))      AS full_name,
  n.preferred                                                   AS preferred_name,
  n.middle                                                      AS middle_name,

  -- Demographics
  p.date_of_birth                                               AS date_of_birth,
  TIMESTAMPDIFF(YEAR, p.date_of_birth, CURDATE())               AS age,
  p.sex                                                         AS sex,
  p.pronoun                                                     AS pronoun,
  p.citizenship                                                 AS citizenship,
  p.nationality                                                 AS nationality,

  -- Status
  CASE WHEN p.deleted_at IS NOT NULL THEN 0 ELSE 1 END          AS is_active,
  CASE WHEN p.hidden = 1              THEN 1 ELSE 0 END          AS is_hidden,
  p.date_of_death                                               AS date_of_death,
  p.cause_of_death                                              AS cause_of_death,
  p.death_by_suicide                                            AS death_by_suicide,

  -- Primary address (first non-deleted address for this client)
  addr.street_1                                                 AS address_street,
  addr.street_2                                                 AS address_street_2,
  addr.city                                                     AS address_city,
  addr.zip                                                      AS address_zip,
  addr.county                                                   AS address_county,
  addr.address_type                                             AS address_type,

  -- Primary phone (first non-deleted phone)
  ph.number                                                     AS primary_phone,
  CASE
    WHEN ph.mobile = 1   THEN 'mobile'
    WHEN ph.home   = 1   THEN 'home'
    WHEN ph.work   = 1   THEN 'work'
    ELSE 'other'
  END                                                           AS primary_phone_type,

  -- Primary email (first non-deleted email)
  em.email                                                      AS primary_email,

  -- Primary insurance
  ip.policy_number                                              AS insurance_policy_number,
  ip.group_number                                               AS insurance_group_number,
  ip.medicaid_number                                            AS medicaid_number,
  ip.priority                                                   AS insurance_priority,
  ip.valid_since                                                AS insurance_valid_since,
  ip.expires_on                                                 AS insurance_expires_on,
  co.name                                                       AS insurance_payor_name,
  co.payor_type                                                 AS insurance_payor_type,
  co.line_of_business                                           AS insurance_line_of_business,

  -- Audit
  p.created_at                                                  AS created_at,
  p.deleted_at                                                  AS deleted_at

FROM people p

-- Current (non-deleted) name
LEFT JOIN names n
  ON n.person_id = p.id
  AND n.deleted_at IS NULL
  AND n.id = (
    SELECT id FROM names
    WHERE person_id = p.id AND deleted_at IS NULL
    ORDER BY created_at DESC LIMIT 1
  )

-- Primary address
LEFT JOIN addresses addr
  ON addr.addressable_id   = p.id
  AND addr.addressable_type = 'Person'
  AND addr.deleted_at IS NULL
  AND addr.id = (
    SELECT id FROM addresses
    WHERE addressable_id = p.id AND addressable_type = 'Person' AND deleted_at IS NULL
    ORDER BY created_at ASC LIMIT 1
  )

-- Primary phone
LEFT JOIN phones ph
  ON ph.phonable_id   = p.id
  AND ph.phonable_type = 'Person'
  AND ph.deleted_at IS NULL
  AND ph.id = (
    SELECT id FROM phones
    WHERE phonable_id = p.id AND phonable_type = 'Person' AND deleted_at IS NULL
    ORDER BY created_at ASC LIMIT 1
  )

-- Primary email
LEFT JOIN emails em
  ON em.emailable_id   = p.id
  AND em.emailable_type = 'Person'
  AND em.deleted_at IS NULL
  AND em.id = (
    SELECT id FROM emails
    WHERE emailable_id = p.id AND emailable_type = 'Person' AND deleted_at IS NULL
    ORDER BY created_at ASC LIMIT 1
  )

-- Primary insurance policy
LEFT JOIN insurance_policies ip
  ON ip.client_id    = p.id
  AND ip.deleted_at IS NULL
  AND ip.id = (
    SELECT id FROM insurance_policies
    WHERE client_id = p.id AND deleted_at IS NULL
    ORDER BY
      CASE priority
        WHEN 'first'   THEN 1
        WHEN 'second'  THEN 2
        WHEN 'third'   THEN 3
        WHEN 'fourth'  THEN 4
        WHEN 'fifth'   THEN 5
        ELSE 9
      END ASC LIMIT 1
  )

-- Insurance payor (companies table)
LEFT JOIN companies co
  ON co.id = ip.payor_id
  AND co.deleted_at IS NULL

WHERE p.type = 'Client'
;
