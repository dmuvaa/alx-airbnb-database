-- PostgreSQL DDL for Airbnb-style schema
-- If you’re using MySQL instead of Postgres, reply and I’ll convert.

-- =========================
-- 0) ENUM TYPES
-- =========================
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('guest','host','admin');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status') THEN
    CREATE TYPE booking_status AS ENUM ('pending','confirmed','canceled');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
    CREATE TYPE payment_method AS ENUM ('credit_card','paypal','stripe');
  END IF;
END $$;

-- =========================
-- 1) USERS
-- =========================
CREATE TABLE IF NOT EXISTS users (
  user_id        UUID PRIMARY KEY,
  first_name     VARCHAR NOT NULL,
  last_name      VARCHAR NOT NULL,
  email          VARCHAR NOT NULL UNIQUE,
  password_hash  VARCHAR NOT NULL,
  phone_number   VARCHAR,
  role           user_role NOT NULL,
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 2) PROPERTIES
-- =========================
CREATE TABLE IF NOT EXISTS properties (
  property_id     UUID PRIMARY KEY,
  host_id         UUID NOT NULL REFERENCES users(user_id),
  name            VARCHAR NOT NULL,
  description     TEXT NOT NULL,
  location        VARCHAR NOT NULL,
  pricepernight   DECIMAL NOT NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- auto-update updated_at (Postgres equivalent of "ON UPDATE CURRENT_TIMESTAMP")
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_properties_set_updated_at ON properties;
CREATE TRIGGER trg_properties_set_updated_at
BEFORE UPDATE ON properties
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =========================
-- 3) BOOKINGS
-- =========================
CREATE TABLE IF NOT EXISTS bookings (
  booking_id   UUID PRIMARY KEY,
  property_id  UUID NOT NULL REFERENCES properties(property_id),
  user_id      UUID NOT NULL REFERENCES users(user_id),
  start_date   DATE NOT NULL,
  end_date     DATE NOT NULL,
  total_price  DECIMAL NOT NULL,
  status       booking_status NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (start_date < end_date)
);

-- =========================
-- 4) PAYMENTS
-- =========================
CREATE TABLE IF NOT EXISTS payments (
  payment_id     UUID PRIMARY KEY,
  booking_id     UUID NOT NULL REFERENCES bookings(booking_id),
  amount         DECIMAL NOT NULL,
  payment_date   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  payment_method payment_method NOT NULL
);

-- =========================
-- 5) REVIEWS
-- =========================
CREATE TABLE IF NOT EXISTS reviews (
  review_id    UUID PRIMARY KEY,
  property_id  UUID NOT NULL REFERENCES properties(property_id),
  user_id      UUID NOT NULL REFERENCES users(user_id),
  rating       INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment      TEXT NOT NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 6) MESSAGES
-- =========================
CREATE TABLE IF NOT EXISTS messages (
  message_id    UUID PRIMARY KEY,
  sender_id     UUID NOT NULL REFERENCES users(user_id),
  recipient_id  UUID NOT NULL REFERENCES users(user_id),
  message_body  TEXT NOT NULL,
  sent_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- 7) INDEXES (beyond PKs/UKs)
-- =========================
-- Users
-- UNIQUE(email) already creates an index

-- Properties
CREATE INDEX IF NOT EXISTS idx_properties_host_id ON properties(host_id);

-- Bookings
CREATE INDEX IF NOT EXISTS idx_bookings_property_id ON bookings(property_id);
CREATE INDEX IF NOT EXISTS idx_bookings_user_id     ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status      ON bookings(status);
-- (PK on booking_id already indexed)

-- Payments
CREATE INDEX IF NOT EXISTS idx_payments_booking_id  ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_date        ON payments(payment_date);

-- Reviews
CREATE INDEX IF NOT EXISTS idx_reviews_property_id  ON reviews(property_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id      ON reviews(user_id);

-- Messages
CREATE INDEX IF NOT EXISTS idx_messages_sender_id    ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient_id ON messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_messages_sent_at      ON messages(sent_at);
