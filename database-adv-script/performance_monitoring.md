# performance_monitoring.md

**Repository:** `alx-airbnb-database`  
**Directory:** `database-adv-script`  

## Objective
Continuously monitor and refine database performance by analyzing execution plans of frequently used queries, identifying bottlenecks, applying schema/index changes, and reporting improvements. Target DB: **MySQL 8.0+**.

> 💡 Note: `SHOW PROFILE` is **removed** in MySQL 8.0. Prefer `EXPLAIN ANALYZE` and the Performance Schema. A legacy snippet for `SHOW PROFILE` (MySQL 5.7) is included for completeness.

---

## 1) Pick frequent/critical queries
Adjust table/column names to your schema (we use `booking_date` here; if you use `start_date`, swap accordingly).

```sql
-- Q1: Recent bookings for a user
SELECT b.id, b.property_id, b.booking_date, b.status
FROM bookings AS b
WHERE b.user_id = ?
ORDER BY b.booking_date DESC
LIMIT 50;

-- Q2: Property popularity (bookings per property)
SELECT p.id, p.title, COUNT(b.id) AS total_bookings
FROM properties AS p
LEFT JOIN bookings AS b ON b.property_id = p.id
GROUP BY p.id, p.title
ORDER BY total_bookings DESC, p.id
LIMIT 100;

-- Q3: Booking details with user & property & latest payment (from previous task)
WITH latest_payments AS (
  SELECT id, booking_id, amount, currency, status, paid_at
  FROM (
    SELECT pay.*,
           ROW_NUMBER() OVER (PARTITION BY pay.booking_id ORDER BY pay.paid_at DESC) AS rn
    FROM payments AS pay
    WHERE pay.status IN ('captured','settled','succeeded')
  ) AS ranked
  WHERE rn = 1
)
SELECT b.id, b.booking_date, b.status,
       u.id AS user_id, u.name, u.email,
       p.id AS property_id, p.title, p.city,
       lp.id AS payment_id, lp.amount, lp.currency, lp.status, lp.paid_at
FROM bookings AS b
JOIN users u      ON u.id = b.user_id
JOIN properties p ON p.id = b.property_id
LEFT JOIN latest_payments lp ON lp.booking_id = b.id
ORDER BY b.booking_date DESC
LIMIT 100;