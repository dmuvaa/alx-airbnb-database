# Database Schema — Airbnb Clone

This directory contains the **PostgreSQL** schema for the Airbnb-style project: tables, constraints, enums, triggers, and performance indexes. It follows normalization best practices up to **Third Normal Form (3NF)** while preserving auditability for bookings and payments.

---

## Contents

- `schema.sql` — DDL to create types, tables, constraints, trigger(s), and indexes.
- `seed.sql` (optional) — Example seed data for local development.
- `migrations/` (optional) — Versioned SQL migrations if you use a migration tool.
- `../ERD/` — ER diagram images or Mermaid source (adjust relative path as needed).
- `../docs/normalization-3nf.md` — Rationale and normalization notes (if present).

> If your repo layout differs, adjust the relative paths in links and examples below.

---

## Quick Start

### Prerequisites
- PostgreSQL 13+ (14/15 recommended)
- `psql` CLI or a GUI (TablePlus, DBeaver, pgAdmin)
- A database user with permissions to create types/tables

### 1) Create a database
```bash
createdb airbnb_clone
