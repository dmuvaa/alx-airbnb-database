## 1) Identify high-usage columns

These columns commonly appear in `JOIN`, `WHERE`, and `ORDER BY` clauses and benefit from indexing:

- **users**
  - `email` (exact lookups)
  - `created_at` (sorting/filtering by recency)
  - `name` (optional search)
- **bookings**
  - `user_id` (join/filter)
  - `property_id` (join/filter)
  - `booking_date` (ordering/filtering by recency)
  - `status` (filter)
- **properties**
  - `created_at` (ordering by recency)
  - `title` (optional search)

> **Why composite indexes?** Combine columns to match your most common predicate patterns (e.g., `WHERE user_id = ? ORDER BY booking_date DESC`). Left-to-right order matters.

---

## 2) Baseline: measure before adding indexes

Run these **baseline** plans first and note estimated row counts, access types, and key usage.

```sql
-- (Optional) USE your_database_name;

-- A) Users ↔ Bookings join; recent-first
EXPLAIN FORMAT=JSON
SELECT
  b.id, b.property_id, b.booking_date, b.status,
  u.id AS user_id, u.name, u.email
FROM bookings AS b
INNER JOIN users AS u
  ON u.id = b.user_id
ORDER BY b.booking_date DESC
LIMIT 100;

-- B) Lookup a user by email (exact match)
EXPLAIN FORMAT=JSON
SELECT u.id, u.name, u.created_at
FROM users AS u
WHERE u.email = 'someone@example.com';

-- C) Property popularity: count bookings per property
EXPLAIN FORMAT=JSON
SELECT p.id, p.title, COUNT(b.id) AS total_bookings
FROM properties AS p
LEFT JOIN bookings AS b
  ON b.property_id = p.id
GROUP BY p.id, p.title
ORDER BY total_bookings DESC, p.id
LIMIT 100;

-- D) Bookings filtered by user; recent-first
EXPLAIN FORMAT=JSON
SELECT b.id, b.property_id, b.booking_date, b.status
FROM bookings AS b
WHERE b.user_id = 42
ORDER BY b.booking_date DESC
LIMIT 50;