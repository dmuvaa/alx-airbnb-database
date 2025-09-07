-- database_index.sql

EXPLAIN FORMAT=JSON
SELECT
  b.id, b.property_id, b.booking_date, b.status,
  u.id AS user_id, u.name, u.email
FROM bookings AS b
INNER JOIN users AS u
  ON u.id = b.user_id
ORDER BY b.booking_date DESC
LIMIT 100;

-- 1B) Lookup a user by email (exact match)
EXPLAIN FORMAT=JSON
SELECT u.id, u.name, u.created_at
FROM users AS u
WHERE u.email = 'someone@example.com';

-- 1C) Property popularity: count bookings per property
EXPLAIN FORMAT=JSON
SELECT p.id, p.title, COUNT(b.id) AS total_bookings
FROM properties AS p
LEFT JOIN bookings AS b
  ON b.property_id = p.id
GROUP BY p.id, p.title
ORDER BY total_bookings DESC, p.id
LIMIT 100;

-- 1D) Bookings filtered by user; recent-first
EXPLAIN FORMAT=JSON
SELECT b.id, b.property_id, b.booking_date, b.status
FROM bookings AS b
WHERE b.user_id = 42
ORDER BY b.booking_date DESC
LIMIT 50;

-- =====================================================================
-- STEP 2: Create indexes on high-usage columns
-- =====================================================================

-- USERS
ALTER TABLE users
  ADD UNIQUE INDEX idx_users_email_unique (email),
  ADD INDEX        idx_users_created_at   (created_at),
  ADD INDEX        idx_users_name         (name);

-- BOOKINGS
ALTER TABLE bookings
  ADD INDEX idx_bookings_user_date     (user_id, booking_date),
  ADD INDEX idx_bookings_property_date (property_id, booking_date),
  ADD INDEX idx_bookings_status        (status),
  ADD INDEX idx_bookings_date          (booking_date);

-- PROPERTIES
ALTER TABLE properties
  ADD INDEX idx_properties_created_at (created_at),
  ADD INDEX idx_properties_title      (title);

-- (Optional) REVIEWS
-- Uncomment if you have a reviews table and query it frequently.
-- ALTER TABLE reviews
--   ADD INDEX idx_reviews_property_created (property_id, created_at),
--   ADD INDEX idx_reviews_user            (user_id);

-- Refresh optimizer statistics
ANALYZE TABLE users, bookings, properties;

-- If reviews indexes were created, also:
-- ANALYZE TABLE reviews;

-- =====================================================================
-- STEP 3: Measure AFTER indexes (runtime + plan)
-- =====================================================================

-- 3A) Users ↔ Bookings join; recent-first
EXPLAIN ANALYZE
SELECT
  b.id, b.property_id, b.booking_date, b.status,
  u.id AS user_id, u.name, u.email
FROM bookings AS b
INNER JOIN users AS u
  ON u.id = b.user_id
ORDER BY b.booking_date DESC
LIMIT 100;

-- 3B) User lookup by email
EXPLAIN ANALYZE
SELECT u.id, u.name, u.created_at
FROM users AS u
WHERE u.email = 'someone@example.com';

-- 3C) Property popularity: count bookings per property
EXPLAIN ANALYZE
SELECT p.id, p.title, COUNT(b.id) AS total_bookings
FROM properties AS p
LEFT JOIN bookings AS b
  ON b.property_id = p.id
GROUP BY p.id, p.title
ORDER BY total_bookings DESC, p.id
LIMIT 100;

-- 3D) Bookings by user; recent-first
EXPLAIN ANALYZE
SELECT b.id, b.property_id, b.booking_date, b.status
FROM bookings AS b
WHERE b.user_id = 42
ORDER BY b.booking_date DESC
LIMIT 50;

-- =====================================================================
-- STEP 4: Verify created indexes
-- =====================================================================
SHOW INDEX FROM users;
SHOW INDEX FROM bookings;
SHOW INDEX FROM properties;
-- SHOW INDEX FROM reviews;  -- if applicable
