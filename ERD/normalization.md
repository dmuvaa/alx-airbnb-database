
# Database Normalization to 3NF — Airbnb Clone

**Goal:** Apply 1NF → 2NF → 3NF to remove redundancy and update anomalies while preserving required business behavior (auditability of bookings & payments).

---

## 0) Starting point (summary of current schema)

- `User(user_id, first_name, last_name, email UNIQUE, password_hash, phone_number, role, created_at)`
- `Property(property_id, host_id → User, name, description, location, price_per_night, created_at, updated_at)`
- `Booking(booking_id, property_id → Property, user_id → User, start_date, end_date, total_price, status, created_at)`
- `Payment(payment_id, booking_id → Booking, amount, payment_date, payment_method)`
- `Review(review_id, property_id → Property, user_id → User, rating, comment, created_at)`
- `Message(message_id, sender_id → User, recipient_id → User, message_body, sent_at)`

---

## 1) First Normal Form (1NF)

**Principle:** All attributes contain atomic values, no repeating groups, each row uniquely identified by a key.

**Findings & actions**

1. **`Property.location` may encode multiple values** (e.g., "Nairobi, Kenya (−1.29, 36.82)").  
   - ✅ **Action:** split into atomic columns: `address_text`, `city`, `country`, `latitude`, `longitude` (or keep `address_text` + `city` + `country` if coordinates aren’t used).  
   - _Reason:_ avoid comma‑separated fields and make filtering and indexing practical.

2. All other columns are already atomic and keyed by a single UUID primary key.  
   - ✅ **No change needed.**

---

## 2) Second Normal Form (2NF)

**Principle:** No partial dependency of a non‑key attribute on a subset of a composite key.

- Every table uses a **single‑column primary key (UUID)**.  
  - ✅ **Already satisfies 2NF.**

---

## 3) Third Normal Form (3NF)

**Principle:** No transitive dependency: non‑key attributes must depend **only on the key**, not on other non‑key attributes.

**Findings**

1. **`Booking.total_price`** can be derived from `Property.price_per_night`, length of stay, fees, and taxes.  
   - If it’s a **live calculation** (depends on current `Property.price_per_night`), that’s a transitive dependency and risks update anomalies.
   - If it’s a **historical snapshot** at time of booking, we must store price components that justify the total to keep the dependency only on `Booking`.

**Normalization options**

- **Strict 3NF (recommended for auditability):**  
  Introduce **`BookingCharge`** as line‑items and **remove** `Booking.total_price`. Use a **view** to compute totals on demand.

- **Pragmatic 3NF:**  
  Keep `Booking.total_price` **only** if it is a historical snapshot and also store components (e.g., `nightly_rate_booked`, `cleaning_fee`, `service_fee`, `tax_amount`). This minimizes anomalies while retaining fast reads.

**Other notes**

- `User.role`, `Booking.status`, and `Payment.payment_method` may stay as **ENUMs** (values are small and stable) *or* be implemented as lookup tables if you need runtime extensibility. This is not required by 3NF but can help governance.
- Add constraints that enforce business rules (e.g., `CHECK (start_date < end_date)`, `CHECK (rating BETWEEN 1 AND 5)`).

---

## 4) 3NF‑compliant schema (DDL — PostgreSQL)

Below are SQL snippets that implement the 1NF/3NF adjustments while keeping the rest of your model intact.

```sql
-- USERS
CREATE TABLE users (
  user_id         UUID PRIMARY KEY,
  first_name      VARCHAR NOT NULL,
  last_name       VARCHAR NOT NULL,
  email           VARCHAR NOT NULL UNIQUE,
  password_hash   VARCHAR NOT NULL,
  phone_number    VARCHAR,
  role            VARCHAR(10) NOT NULL CHECK (role IN ('guest','host','admin')),
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- PROPERTIES (location split into atomic parts)
CREATE TABLE properties (
  property_id       UUID PRIMARY KEY,
  host_id           UUID NOT NULL REFERENCES users(user_id),
  name              VARCHAR NOT NULL,
  description       TEXT NOT NULL,
  address_text      TEXT,                 -- optional human-friendly address
  city              VARCHAR,
  country           VARCHAR,
  latitude          NUMERIC(9,6),
  longitude         NUMERIC(9,6),
  price_per_night   DECIMAL NOT NULL,
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- BOOKINGS (total_price removed in strict 3NF)
CREATE TABLE bookings (
  booking_id    UUID PRIMARY KEY,
  property_id   UUID NOT NULL REFERENCES properties(property_id),
  user_id       UUID NOT NULL REFERENCES users(user_id),
  start_date    DATE NOT NULL,
  end_date      DATE NOT NULL,
  status        VARCHAR(10) NOT NULL CHECK (status IN ('pending','confirmed','canceled')),
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (start_date < end_date)
);

-- BOOKING LINE ITEMS (strict 3NF)
CREATE TABLE booking_charges (
  booking_charge_id UUID PRIMARY KEY,
  booking_id        UUID NOT NULL REFERENCES bookings(booking_id) ON DELETE CASCADE,
  charge_type       VARCHAR(20) NOT NULL CHECK (charge_type IN ('nightly_rate','cleaning_fee','service_fee','tax','discount')),
  amount            DECIMAL NOT NULL CHECK (amount >= 0 OR charge_type = 'discount')
);

-- Optional view for totals (derived, no redundancy)
CREATE VIEW booking_totals AS
SELECT
  b.booking_id,
  SUM(CASE WHEN charge_type = 'discount' THEN -amount ELSE amount END) AS total_price
FROM bookings b
JOIN booking_charges c ON c.booking_id = b.booking_id
GROUP BY b.booking_id;

-- PAYMENTS
CREATE TABLE payments (
  payment_id     UUID PRIMARY KEY,
  booking_id     UUID NOT NULL REFERENCES bookings(booking_id),
  amount         DECIMAL NOT NULL,
  payment_date   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('credit_card','paypal','stripe'))
);

-- REVIEWS
CREATE TABLE reviews (
  review_id    UUID PRIMARY KEY,
  property_id  UUID NOT NULL REFERENCES properties(property_id),
  user_id      UUID NOT NULL REFERENCES users(user_id),
  rating       INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment      TEXT NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- optional: prevent multiple reviews by the same user per property
  UNIQUE (property_id, user_id)
);

-- MESSAGES
CREATE TABLE messages (
  message_id    UUID PRIMARY KEY,
  sender_id     UUID NOT NULL REFERENCES users(user_id),
  recipient_id  UUID NOT NULL REFERENCES users(user_id),
  message_body  TEXT NOT NULL,
  sent_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexing (beyond PKs/UKs)
CREATE INDEX idx_properties_host_id     ON properties(host_id);
CREATE INDEX idx_bookings_property_id   ON bookings(property_id);
CREATE INDEX idx_bookings_user_id       ON bookings(user_id);
CREATE INDEX idx_payments_booking_id    ON payments(booking_id);
CREATE INDEX idx_reviews_property_id    ON reviews(property_id);
CREATE INDEX idx_messages_sender_id     ON messages(sender_id);
CREATE INDEX idx_messages_recipient_id  ON messages(recipient_id);
```
> **If you prefer the pragmatic approach** (keep `bookings.total_price`), store the components (`nightly_rate_booked`, `cleaning_fee`, `service_fee`, `tax_amount`) too, and enforce consistency with a trigger that recomputes `total_price` on write. This keeps behavior predictable while minimizing anomalies.

---

## 5) Why this is 3NF

- Every non‑key attribute in each table depends **only on that table’s key** (e.g., `amount` depends on `booking_charge_id`, not on `properties.price_per_night`).  
- No attributes depend on other non‑key attributes (transitive dependencies removed).  
- Derived totals are **not stored** (strict 3NF) or are **materialized carefully** with full provenance (pragmatic 3NF).  
- Multi‑valued `location` was decomposed into atomic attributes (1NF), which also improves indexing and filtering.

---

## 6) What to put in the repo

- Add this file as `docs/normalization-3nf.md` (or `REQUIREMENTS/normalization-3nf.md`).  
- If you adopt **strict 3NF**, update migrations with the DDL above, add a `booking_totals` view, and modify API code to read totals from the view.  
- If you adopt **pragmatic 3NF**, keep `bookings.total_price`, add component columns or a `booking_charges` table, and enforce integrity with triggers.

---

## 7) Commit commands

```bash
mkdir -p docs
git add docs/normalization-3nf.md
git commit -m "docs: explain 3NF normalization and propose schema changes (booking_charges, location split)"
git push
```
