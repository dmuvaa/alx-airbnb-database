/* =====================================================================
   1) NON-CORRELATED SUBQUERY
      Find all properties where the average rating is greater than 4.0.
      The subquery aggregates reviews by property_id (no outer reference).
   ===================================================================== */
-- Returns property rows whose avg review rating > 4.0
SELECT
  p.id,
  p.title
FROM properties AS p
WHERE p.id IN (
  SELECT r.property_id
  FROM reviews AS r
  GROUP BY r.property_id
  HAVING AVG(r.rating) > 4.0
)
ORDER BY p.id;


/* ================================================================
   2) CORRELATED SUBQUERY
      Find users who have made more than 3 bookings.
      The inner query is evaluated per user row (references u.id).
   ================================================================ */
SELECT
  u.id,
  u.name,
  u.email
FROM users AS u
WHERE (
  SELECT COUNT(*)
  FROM bookings AS b
  WHERE b.user_id = u.id
) > 3
ORDER BY u.id;