/* =========================================================
   1) INNER JOIN — all bookings with the user who made each
   ========================================================= */
SELECT
  b.id           AS booking_id,
  b.property_id,
  b.booking_date,
  b.status,
  u.id           AS user_id,
  u.name         AS user_name,
  u.email        AS user_email
FROM bookings AS b
INNER JOIN users AS u
  ON u.id = b.user_id
ORDER BY b.booking_date DESC;


/* ==================================================================
   2) LEFT JOIN — all properties with their reviews (including none)
   ================================================================== */
SELECT
  p.id           AS property_id,
  p.title        AS property_title,
  r.id           AS review_id,
  r.user_id      AS review_user_id,
  r.rating,
  r.comment,
  r.created_at   AS review_created_at
FROM properties AS p
LEFT JOIN reviews AS r
  ON r.property_id = p.id
ORDER BY p.id, r.id;


/* ===================================================================================
   3) FULL OUTER JOIN — all users and all bookings, even if not linked (PostgreSQL)
   Use this version if your database supports FULL OUTER JOIN (e.g., PostgreSQL).
   =================================================================================== */
-- PostgreSQL (or any DB that supports FULL OUTER JOIN)
SELECT
  u.id           AS user_id,
  u.name         AS user_name,
  u.email        AS user_email,
  b.id           AS booking_id,
  b.property_id,
  b.booking_date,
  b.status
FROM users AS u
FULL OUTER JOIN bookings AS b
  ON b.user_id = u.id
ORDER BY COALESCE(u.id, -1), COALESCE(b.id, -1);


/* ===================================================================================
   3b) FULL OUTER JOIN (MySQL/MariaDB simulation) — choose this if your DB lacks FULL
       OUTER JOIN. We combine LEFT JOIN with unmatched RIGHT JOIN rows via UNION ALL.
   =================================================================================== */
-- MySQL-compatible alternative
SELECT
  u.id           AS user_id,
  u.name         AS user_name,
  u.email        AS user_email,
  b.id           AS booking_id,
  b.property_id,
  b.booking_date,
  b.status
FROM users AS u
LEFT JOIN bookings AS b
  ON b.user_id = u.id

UNION ALL

SELECT
  NULL           AS user_id,
  NULL           AS user_name,
  NULL           AS user_email,
  b.id           AS booking_id,
  b.property_id,
  b.booking_date,
  b.status
FROM users AS u
RIGHT JOIN bookings AS b
  ON b.user_id = u.id
WHERE u.id IS NULL
ORDER BY user_id IS NULL, user_id, booking_id;
