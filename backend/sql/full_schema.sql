-- =============================================================================
-- KidZone / FitKid – full Supabase schema
-- Run this in Supabase: SQL Editor → New query → paste → Run
-- If you already have some tables, run only the sections you need.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Families
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS families (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 2. Users (links to Supabase Auth via id = auth.uid())
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  email TEXT,
  password_hash TEXT NOT NULL DEFAULT 'EXTERNAL',
  role TEXT NOT NULL CHECK (role IN ('PARENT', 'CHILD')),
  current_credit_score INTEGER NOT NULL DEFAULT 300,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_family_id ON users(family_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- -----------------------------------------------------------------------------
-- 3. Chores
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS chores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  reward_value_cents INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'ASSIGNED'
    CHECK (status IN ('ASSIGNED', 'PENDING_APPROVAL', 'COMPLETED', 'REJECTED')),
  due_date DATE,
  recurrence_type TEXT CHECK (recurrence_type IN ('NONE', 'DAILY', 'WEEKLY', 'MONTHLY')),
  recurrence_config TEXT,
  parent_chore_id UUID REFERENCES chores(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chores_assignee ON chores(assignee_id);
CREATE INDEX IF NOT EXISTS idx_chores_status ON chores(status);

-- -----------------------------------------------------------------------------
-- 4. Ledger (double-entry: accounts, transactions, postings)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ledger_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'CLEARED',
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS postings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES ledger_accounts(id) ON DELETE CASCADE,
  amount BIGINT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ledger_accounts_user ON ledger_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_postings_account ON postings(account_id);
CREATE INDEX IF NOT EXISTS idx_postings_transaction ON postings(transaction_id);

-- -----------------------------------------------------------------------------
-- 5. Purchase requests
-- -----------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE request_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS purchase_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
  requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  url TEXT,
  image_url TEXT,
  price_cents INTEGER NOT NULL,
  status request_status NOT NULL DEFAULT 'PENDING',
  payment_method TEXT,
  card_id UUID,
  card_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  decided_at TIMESTAMPTZ,
  decided_by UUID REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_purchase_requests_family ON purchase_requests(family_id);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_requester ON purchase_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_card_id ON purchase_requests(card_id);

-- -----------------------------------------------------------------------------
-- 6. Credit system
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS credit_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  card_name TEXT NOT NULL,
  tier TEXT NOT NULL CHECK (tier IN ('STARTER', 'BUILDER', 'STRONG', 'ELITE')),
  limit_cents INTEGER NOT NULL,
  balance_cents INTEGER NOT NULL DEFAULT 0,
  apr DECIMAL(5,4) NOT NULL,
  rewards_rate DECIMAL(5,4) NOT NULL DEFAULT 0,
  opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_payment_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'PENDING_APPROVAL'
    CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED', 'PENDING_APPROVAL')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES credit_cards(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_cents INTEGER NOT NULL,
  transaction_type TEXT NOT NULL
    CHECK (transaction_type IN ('PURCHASE', 'PAYMENT', 'INTEREST', 'FEE', 'REWARD', 'REFUND')),
  description TEXT NOT NULL,
  merchant TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS credit_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES credit_cards(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_cents INTEGER NOT NULL,
  payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_on_time BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_credit_cards_user_id ON credit_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_cards_status ON credit_cards(status);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_card_id ON credit_transactions(card_id);
CREATE INDEX IF NOT EXISTS idx_credit_payments_card_id ON credit_payments(card_id);

-- -----------------------------------------------------------------------------
-- 7. Allowances (family_id as TEXT to match backend; backend uses UUID string)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS allowances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  family_id TEXT,
  amount_cents INTEGER NOT NULL,
  frequency TEXT NOT NULL CHECK (frequency IN ('WEEKLY', 'MONTHLY', 'CUSTOM')),
  custom_interval_days INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_allowances_child ON allowances(child_id);
CREATE INDEX IF NOT EXISTS idx_allowances_family ON allowances(family_id);

-- -----------------------------------------------------------------------------
-- Optional: RLS (Row Level Security) – backend uses service_role so it
-- bypasses RLS. Enable only if you also use anon/authenticated clients.
-- -----------------------------------------------------------------------------
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE families ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE chores ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE credit_cards ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE credit_payments ENABLE ROW LEVEL SECURITY;
-- (Add policies as needed for your auth.uid() and family_id checks.)
