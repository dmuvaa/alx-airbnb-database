-- Sample data seed for PostgreSQL Airbnb-style schema
-- Assumes the schema and ENUM types from your DDL already exist.

BEGIN;

-- ================
-- USERS
-- ================
INSERT INTO users (user_id, first_name, last_name, email, password_hash, phone_number, role)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Alice', 'Host',   'alice.host@example.com',   'hashed_pw_alice', '+254700000001', 'host'),
  ('22222222-2222-2222-2222-222222222222', 'Ben',   'Host',   'ben.host@example.com',     'hashed_pw_ben',   '+254700000002', 'host'),
  ('33333333-3333-3333-3333-333333333333', 'Bob',   'Guest',  'bob.guest@example.com',    'hashed_pw_bob',   '+254700000003', 'guest'),
  ('44444444-4444-4444-4444-444444444444', 'Carol', 'Guest',  'carol.guest@example.com',  'hashed_pw_carol', '+254700000004', 'guest'),
  ('55555555-5555-5555-5555-555555555555', 'Admin', 'User',   'admin@example.com',        'hashed_pw_admin', '+254700000005', 'admin');

-- ================
-- PROPERTIES
-- ================
INSERT INTO properties (property_id, host_id, name, description, location, pricepernight)
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111',
    'Cozy Loft', 'Modern loft near CBD with great Wi-Fi.', 'Nairobi, Kenya', 75.00),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '22222222-2222-2222-2222-222222222222',
    'Beach House', 'Oceanfront house with balcony and private access.', 'Mombasa, Kenya', 120.00),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '11111111-1111-1111-1111-111111111111',
    'Mountain Cabin', 'Quiet cabin close to hiking trails.', 'Nanyuki, Kenya', 90.00);

-- ================
-- BOOKINGS
-- (total_price = nights * pricepernight; nights = end_date - start_date)
-- ================
-- B1: Bob books Cozy Loft for 2 nights (2 * 75 = 150) - confirmed, future
INSERT INTO bookings (booking_id, property_id, user_id, start_date, end_date, total_price, status)
VALUES
  ('99999999-9999-9999-9999-999999999991', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
    '33333333-3333-3333-3333-333333333333', DATE '2025-09-10', DATE '2025-09-12', 150.00, 'confirmed');

-- B2: Carol books Beach House for 3 nights (3 * 120 = 360) - confirmed, past
INSERT INTO bookings (booking_id, property_id, user_id, start_date, end_date, total_price, status)
VALUES
  ('99999999-9999-9999-9999-999999999992', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
    '44444444-4444-4444-4444-444444444444', DATE '2025-08-15', DATE '2025-08-18', 360.00, 'confirmed');

-- B3: Carol books Cozy Loft for 3 nights (3 * 75 = 225) - pending, future
INSERT INTO bookings (booking_id, property_id, user_id, start_date, end_date, total_price, status)
VALUES
  ('99999999-9999-9999-9999-999999999993', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
    '44444444-4444-4444-4444-444444444444', DATE '2025-09-20', DATE '2025-09-23', 225.00, 'pending');

-- B4: Bob booked Mountain Cabin for 2 nights (2 * 90 = 180) - confirmed, past
INSERT INTO bookings (booking_id, property_id, user_id, start_date, end_date, total_price, status)
VALUES
  ('99999999-9999-9999-9999-999999999994', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
    '33333333-3333-3333-3333-333333333333', DATE '2025-06-10', DATE '2025-06-12', 180.00, 'confirmed');

-- Canceled example (no payment/review)
INSERT INTO bookings (booking_id, property_id, user_id, start_date, end_date, total_price, status)
VALUES
  ('99999999-9999-9999-9999-999999999995', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
    '33333333-3333-3333-3333-333333333333', DATE '2025-08-20', DATE '2025-08-22', 240.00, 'canceled');

-- ================
-- PAYMENTS
-- ================
-- B1: one full payment 150.00 (credit_card)
INSERT INTO payments (payment_id, booking_id, amount, payment_date, payment_method)
VALUES
  ('77777777-7777-7777-7777-777777777771', '99999999-9999-9999-9999-999999999991',
    150.00, TIMESTAMP '2025-09-01 10:15:00', 'credit_card');

-- B2: split payments 200.00 + 160.00 (paypal) = 360.00
INSERT INTO payments (payment_id, booking_id, amount, payment_date, payment_method)
VALUES
  ('77777777-7777-7777-7777-777777777772', '99999999-9999-9999-9999-999999999992',
    200.00, TIMESTAMP '2025-08-01 09:00:00', 'paypal'),
  ('77777777-7777-7777-7777-777777777773', '99999999-9999-9999-9999-999999999992',
    160.00, TIMESTAMP '2025-08-14 16:30:00', 'paypal');

-- B4: one full payment 180.00 (stripe)
INSERT INTO payments (payment_id, booking_id, amount, payment_date, payment_method)
VALUES
  ('77777777-7777-7777-7777-777777777774', '99999999-9999-9999-9999-999999999994',
    180.00, TIMESTAMP '2025-06-05 13:45:00', 'stripe');

-- ================
-- REVIEWS (after stay end dates)
-- ================
INSERT INTO reviews (review_id, property_id, user_id, rating, comment, created_at)
VALUES
  ('66666666-6666-6666-6666-666666666661', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
    '44444444-4444-4444-4444-444444444444', 5, 'Amazing beach view and very clean!', TIMESTAMP '2025-08-19 12:00:00'),
  ('66666666-6666-6666-6666-666666666662', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
    '33333333-3333-3333-3333-333333333333', 4, 'Cozy place, great for hiking weekend.', TIMESTAMP '2025-06-13 09:20:00');

-- ================
-- MESSAGES
-- ================
INSERT INTO messages (message_id, sender_id, recipient_id, message_body, sent_at)
VALUES
  ('88888888-8888-8888-8888-888888888881',
    '33333333-3333-3333-3333-333333333333',  -- Bob
    '11111111-1111-1111-1111-111111111111',  -- Alice (host)
    'Hi! Is early check-in possible for my stay at the Cozy Loft?', TIMESTAMP '2025-09-01 08:45:00'),
  ('88888888-8888-8888-8888-888888888882',
    '11111111-1111-1111-1111-111111111111',  -- Alice
    '33333333-3333-3333-3333-333333333333',
    'Yes, early check-in at 1 PM is fine. See you soon!', TIMESTAMP '2025-09-01 09:10:00'),
  ('88888888-8888-8888-8888-888888888883',
    '44444444-4444-4444-4444-444444444444',  -- Carol
    '22222222-2222-2222-2222-222222222222',  -- Ben (host)
    'Hello! Is the Beach House available for 15–18 Aug? Any discount for 3 nights?', TIMESTAMP '2025-07-30 15:05:00');

COMMIT;
