# partition_performance.md

**Repository:** `alx-airbnb-database`  
**Directory:** `database-adv-script`  
**Files:** `partitioning.sql`, `partition_performance.md`

## Objective
Improve query performance on a large `bookings` table by partitioning **by `start_date`** and validating gains on date-range queries.

## Approach
1. **Baseline**: Measured a typical date-range query with `EXPLAIN FORMAT=JSON` and `EXPLAIN ANALYZE`.  
   ```sql
   SELECT b.id, b.user_id, b.property_id, b.start_date, b.end_date, b.status
   FROM bookings AS b
   WHERE b.start_date >= '2025-01-01'
     AND b.start_date <  '2025-02-01'
   ORDER BY b.start_date, b.id;
