-- perfomance.sql

SELECT
  b.id            AS booking_id,
  b.booking_date,
  b.status        AS booking_status,
  b.user_id,
  b.property_id,
  u.name          AS user_name,
  u.email         AS user_email,
  p.title         AS property_title,
  p.city          AS property_city,
  pay.id          AS payment_id,
  pay.amount      AS payment_amount,
  pay.currency    AS payment_currency,
  pay.status      AS payment_status,
  pay.paid_at     AS paid_at
FROM bookings AS b
JOIN users      AS u   ON u.id = b.user_id
JOIN properties AS p   ON p.id = b.property_id
LEFT JOIN payments AS pay
  ON pay.booking_id = b.id
 AND pay.status IN ('captured', 'settled', 'succeeded')  -- <-- AND present
ORDER BY b.booking_date DESC;

-- Optional: initial plan
EXPLAIN FORMAT=JSON
SELECT
  b.id, b.booking_date, b.status, b.user_id, b.property_id,
  u.name, u.email, p.title, p.city,
  pay.id, pay.amount, pay.currency, pay.status, pay.paid_at
FROM bookings AS b
JOIN users      AS u   ON u.id = b.user_id
JOIN properties AS p   ON p.id = b.property_id
LEFT JOIN payments AS pay
  ON pay.booking_id = b.id
 AND pay.status IN ('captured', 'settled', 'succeeded')  -- <-- AND present
ORDER BY b.booking_date DESC;


/* ========================================================================
   B) SUPPORTING INDEXES (apply once)
   ------------------------------------------------------------------------
   Apply these before running the refactored query for best performance.
   ======================================================================== */
-- USERS
ALTER TABLE users
  ADD UNIQUE INDEX idx_users_email_unique (email),
  ADD INDEX        idx_users_name         (name);

-- BOOKINGS
ALTER TABLE bookings
  ADD INDEX idx_bookings_user_date     (user_id, booking_date),
  ADD INDEX idx_bookings_property_date (property_id, booking_date);

-- PROPERTIES
ALTER TABLE properties
  ADD INDEX idx_properties_city        (city);

-- PAYMENTS
ALTER TABLE payments
  ADD INDEX idx_payments_booking_paid  (booking_id, paid_at),
  ADD INDEX idx_payments_status_book   (status, booking_id, paid_at);

-- Refresh optimizer statistics
ANALYZE TABLE users, bookings, properties, payments;


/* ==================================================================================
   C) REFACTORED QUERY (Latest successful payment per booking; fewer joined rows)
   ----------------------------------------------------------------------------------
   Rationale:
   - Many reports only need ONE payment per booking (e.g., latest successful).
   - Use a window function to pick the most recent successful payment per booking.
   - Reduces join cardinality (≤1 row per booking from payments).
   - Requires MySQL 8.0+ for window functions.
   ================================================================================== */
WITH latest_payments AS (
  SELECT id, booking_id, amount, currency, status, paid_at
  FROM (
    SELECT
      pay.*,
      ROW_NUMBER() OVER (
        PARTITION BY pay.booking_id
        ORDER BY pay.paid_at DESC
      ) AS rn
    FROM payments AS pay
    WHERE pay.status IN ('captured', 'settled', 'succeeded')
  ) AS ranked
  WHERE rn = 1
)
SELECT
  b.id            AS booking_id,
  b.booking_date,
  b.status        AS booking_status,
  u.id            AS user_id,
  u.name          AS user_name,
  u.email         AS user_email,
  p.id            AS property_id,
  p.title         AS property_title,
  p.city          AS property_city,
  lp.id           AS payment_id,
  lp.amount       AS payment_amount,
  lp.currency     AS payment_currency,
  lp.status       AS payment_status,
  lp.paid_at      AS paid_at
FROM bookings AS b
JOIN users      AS u  ON u.id = b.user_id
JOIN properties AS p  ON p.id = b.property_id
LEFT JOIN latest_payments AS lp
  ON lp.booking_id = b.id
ORDER BY b.booking_date DESC;

-- Refactored plan (should show reduced rows on the payments side and index usage)
EXPLAIN ANALYZE
WITH latest_payments AS (
  SELECT id, booking_id, amount, currency, status, paid_at
  FROM (
    SELECT
      pay.*,
      ROW_NUMBER() OVER (
        PARTITION BY pay.booking_id
        ORDER BY pay.paid_at DESC
      ) AS rn
    FROM payments AS pay
    WHERE pay.status IN ('captured', 'settled', 'succeeded')
  ) AS ranked
  WHERE rn = 1
)
SELECT
  b.id, b.booking_date, b.status,
  u.id AS user_id, u.name, u.email,
  p.id AS property_id, p.title, p.city,
  lp.id, lp.amount, lp.currency, lp.status, lp.paid_at
FROM bookings AS b
JOIN users      AS u  ON u.id = b.user_id
JOIN properties AS p  ON p.id = b.property_id
LEFT JOIN latest_payments AS lp
  ON lp.booking_id = b.id
ORDER BY b.booking_date DESC;
