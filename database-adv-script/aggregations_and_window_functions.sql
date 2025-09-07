-- aggregations_and_window_functions.sql
-- Purpose: Apply aggregations and window functions
-- Assumed tables:
--   users(id, name, email, ...)
--   bookings(id, user_id, property_id, booking_date, status, ...)
--   properties(id, title, ...)

 /* ============================================================
    1) Total number of bookings made by each user
    - Uses COUNT + GROUP BY
    - LEFT JOIN keeps users with zero bookings
    ============================================================ */
SELECT
  u.id         AS user_id,
  u.name       AS user_name,
  COUNT(b.id)  AS total_bookings
FROM users AS u
LEFT JOIN bookings AS b
  ON b.user_id = u.id
-- Optional: only count certain statuses
-- AND b.status = 'confirmed'
GROUP BY u.id, u.name
ORDER BY total_bookings DESC, u.id;

 /* ==================================================================================
    2) Rank properties by total bookings
    - CTE aggregates counts per property
    - RANK() gives tie-aware rank; ROW_NUMBER() gives strict ordering within ties
    - Works on PostgreSQL / SQL Server / MySQL 8+
    ================================================================================== */
WITH property_counts AS (
  SELECT
    p.id           AS property_id,
    p.title        AS property_title,
    COUNT(b.id)    AS total_bookings
  FROM properties AS p
  LEFT JOIN bookings AS b
    ON b.property_id = p.id
  GROUP BY p.id, p.title
)
SELECT
  property_id,
  property_title,
  total_bookings,
  RANK()       OVER (ORDER BY total_bookings DESC)                  AS booking_rank,
  ROW_NUMBER() OVER (ORDER BY total_bookings DESC, property_id ASC) AS booking_rownum
FROM property_counts
ORDER BY booking_rank, property_id;