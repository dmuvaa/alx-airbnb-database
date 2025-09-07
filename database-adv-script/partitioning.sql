-- partitioning.sql
-- Repository: alx-airbnb-database
-- Directory: database-adv-script
-- Purpose: Partition the large Bookings table by start_date, then test performance
-- Target DB: MySQL 8.0+

-- ============================================================
-- A) BASELINE: measure BEFORE partitioning (example range query)
--    Run these first on your current (unpartitioned) `bookings` table.
-- ============================================================
EXPLAIN FORMAT=JSON
SELECT
  b.id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.status
FROM bookings AS b
WHERE b.start_date >= '2025-01-01'
  AND b.start_date <  '2025-02-01'
ORDER BY b.start_date, b.id;

EXPLAIN ANALYZE
SELECT
  b.id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.status
FROM bookings AS b
WHERE b.start_date >= '2025-01-01'
  AND b.start_date <  '2025-02-01'
ORDER BY b.start_date, b.id;

-- ============================================================
-- B) SAFETY BACKUP (optional but recommended)
-- ============================================================
CREATE TABLE IF NOT EXISTS bookings_backup LIKE bookings;
INSERT INTO bookings_backup SELECT * FROM bookings;

-- ============================================================
-- C) BUILD A PARTITIONED REPLACEMENT TABLE
--    NOTE (MySQL requirement): All UNIQUE/PRIMARY KEYS on a partitioned table
--    must include the partitioning column (start_date). We therefore make the
--    PK composite: (id, start_date). Adjust unique keys accordingly if needed.
-- ============================================================

-- 1) Create a clone to transform into a partitioned table
DROP TABLE IF EXISTS bookings_part;
CREATE TABLE bookings_part LIKE bookings;

-- 2) Change the PRIMARY KEY to include start_date (required for partitioning)
--    If your table already has a composite PK that includes start_date, skip this.
ALTER TABLE bookings_part
  DROP PRIMARY KEY,
  ADD PRIMARY KEY (id, start_date);

-- 3) Add helpful secondary indexes that align with common filters/joins
--    (These are optional but recommended; adjust to your schema/usage)
ALTER TABLE bookings_part
  ADD INDEX idx_bookings_user_start     (user_id, start_date),
  ADD INDEX idx_bookings_property_start (property_id, start_date),
  ADD INDEX idx_bookings_status         (status);

-- 4) Apply RANGE partitioning on start_date (YEAR partitions as example).
--    Adjust years to cover your data horizon; extend pMAX as catch-all.
ALTER TABLE bookings_part
PARTITION BY RANGE COLUMNS (start_date) (
  PARTITION p2023 VALUES LESS THAN ('2024-01-01'),
  PARTITION p2024 VALUES LESS THAN ('2025-01-01'),
  PARTITION p2025 VALUES LESS THAN ('2026-01-01'),
  PARTITION p2026 VALUES LESS THAN ('2027-01-01'),
  PARTITION pMAX  VALUES LESS THAN (MAXVALUE)
);

-- 5) Load data into the partitioned table
INSERT /*+ NO_WRITE_TO_BINLOG */ INTO bookings_part
SELECT * FROM bookings;

-- 6) Atomically swap tables (minimizes downtime)
RENAME TABLE bookings TO bookings_unpart,
             bookings_part TO bookings;

-- 7) Refresh optimizer statistics
ANALYZE TABLE bookings;

-- ============================================================
-- D) TEST AFTER PARTITIONING
--    Use EXPLAIN PARTITIONS to confirm pruning (only relevant partitions scan)
-- ============================================================
EXPLAIN PARTITIONS
SELECT
  b.id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.status
FROM bookings AS b
WHERE b.start_date >= '2025-01-01'
  AND b.start_date <  '2025-02-01'
ORDER BY b.start_date, b.id;

EXPLAIN ANALYZE
SELECT
  b.id,
  b.user_id,
  b.property_id,
  b.start_date,
  b.end_date,
  b.status
FROM bookings AS b
WHERE b.start_date >= '2025-01-01'
  AND b.start_date <  '2025-02-01'
ORDER BY b.start_date, b.id;

-- ============================================================
-- E) OPTIONAL: MAINTENANCE for next years
--    Add a new partition each year (or quarter/month) before year-end.
-- ============================================================
-- ALTER TABLE bookings
-- ADD PARTITION (
--   PARTITION p2027 VALUES LESS THAN ('2028-01-01')
-- );
