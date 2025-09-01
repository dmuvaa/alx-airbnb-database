# Seed Data — Airbnb Clone

This folder contains **sample data** to quickly populate the database for local development and demos.

## Files
- `seed.sql` — INSERTs for users, properties, bookings, payments, reviews, and messages.

## Prerequisites
- **PostgreSQL 13+**
- The schema must already exist (run your `schema.sql` first).

## Load the data
```bash
# from this directory
psql -d airbnb_clone -f ./seed.sql
