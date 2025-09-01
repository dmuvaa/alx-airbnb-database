erDiagram
  USER ||--o{ PROPERTY : hosts
  USER ||--o{ BOOKING  : makes
  PROPERTY ||--o{ BOOKING : has
  BOOKING ||--o{ PAYMENT  : has
  PROPERTY ||--o{ REVIEW  : receives
  USER ||--o{ REVIEW      : writes
  USER ||--o{ MESSAGE     : sends
  USER ||--o{ MESSAGE     : receives

  USER {
    UUID user_id PK
    string first_name
    string last_name
    string email UK
    string password_hash
    string phone_number
    enum role "guest|host|admin"
    timestamp created_at
  }

  PROPERTY {
    UUID property_id PK
    UUID host_id FK "→ USER.user_id"
    string name
    text description
    string location
    decimal price_per_night
    timestamp created_at
    timestamp updated_at
  }

  BOOKING {
    UUID booking_id PK
    UUID property_id FK "→ PROPERTY.property_id"
    UUID user_id FK "→ USER.user_id"
    date start_date
    date end_date
    decimal total_price
    enum status "pending|confirmed|canceled"
    timestamp created_at
  }

  PAYMENT {
    UUID payment_id PK
    UUID booking_id FK "→ BOOKING.booking_id"
    decimal amount
    timestamp payment_date
    enum payment_method "credit_card|paypal|stripe"
  }

  REVIEW {
    UUID review_id PK
    UUID property_id FK "→ PROPERTY.property_id"
    UUID user_id FK "→ USER.user_id"
    int rating "1..5"
    text comment
    timestamp created_at
  }

  MESSAGE {
    UUID message_id PK
    UUID sender_id FK "→ USER.user_id"
    UUID recipient_id FK "→ USER.user_id"
    text message_body
    timestamp sent_at
  }
