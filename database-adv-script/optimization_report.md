# optimization_report.md

**Repository:** `alx-airbnb-database`  
**Directory:** `database-adv-script`

## Goal
Refactor a complex query that pulls **bookings** with **user**, **property**, and **payment** details to reduce execution time and unnecessary work.

## Assumptions
Tables (MySQL 8.0+):
- `users(id PK, name, email, …)`
- `properties(id PK, title, city, created_at, …)`
- `bookings(id PK, user_id FK→users.id, property_id FK→properties.id, booking_date, status, …)`
- `payments(id PK, booking_id FK→bookings.id, amount, currency, status, paid_at, …)`

---

## A) Initial Query
This returns **all** payments for each booking (0..N). It’s correct when you want every payment row, but it can balloon result size when multiple payments exist per booking.

```sql
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
LEFT JOIN payments AS pay ON pay.booking_id = b.id
ORDER BY b.booking_date DESC;
