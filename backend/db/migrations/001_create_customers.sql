BEGIN; 

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

----- Domain Statuses

CREATE TYPE  quote_status AS ENUM (
    'DRAFT',
    'PENDING_APPROVAL',
    'APPROVED',
    'ACCEPTED',
    'REJECTED'
);

CREATE TYPE order_status AS ENUM(
    'DRAFT',
    'SUBMITTED',
    'CONFIRMED',
    'COMPLETED',
    'FAILED',
    'CANCELLED'
);


-- TABLES

-- Customers
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuidv7(), 
    name VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Opportunities
CREATE TABLE IF NOT EXISTS opportunities (
    id UUID PRIMARY KEY DEFAULT uuidv7(), 
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    name VARCHAR(80) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Quotes
CREATE TABLE IF NOT EXISTS quotes(
    id UUID PRIMARY KEY DEFAULT uuidv7(), 
    opportunity_id UUID NOT NULL REFERENCES opportunities(id) ON DELETE RESTRICT,
    status quote_status NOT NULL DEFAULT 'DRAFT',
    total_price NUMERIC (12,2) CHECK (total_price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rejection_reason TEXT 
);


-- Quote Items
CREATE TABLE IF NOT EXISTS quote_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- uuid v4
    quote_id UUID NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    product_id UUID NOT NULL references products(id) ON DELETE RESTRICT, 
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) CHECK (unit_price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_quote_product UNIQUE (quote_id, product_id)
);


-- Products
CREATE TABLE IF NOT EXISTS products(
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    name VARCHAR(255) NOT NULL,
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- Orders
CREATE TABLE IF NOT EXISTS  orders (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    quote_id UUID NOT NULL references quotes(id) ON DELETE RESTRICT,
    status order_status NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Order Items

CREATE TABLE IF NOT EXISTS OrderItems (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    order_id  UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity >),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_order_product UNIQUE (order_id, product_id)
)


-- -- INDEXES FOR FOREIGN KEYS & SEARCH
CREATE INDEX IF NOT EXISTS idx_opportunities_customer_id ON opportunities(customer_id);
CREATE INDEX IF NOT EXISTS idx_quotes_opportunity_id ON quotes(opportunity_id);
CREATE INDEX IF NOT EXISTS idx_quote_items_quote_id ON quote_items(quote_id);
CREATE INDEX IF NOT EXISTS idx_orders_quote_id ON orders(quote_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);

-- Enforce maximum 1 active (non-cancelled) Order per Quote at database level
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_active_order_per_quote 
ON orders(quote_id) 
WHERE status != 'CANCELLED';

COMMIT;