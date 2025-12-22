-- Credit System Tables

-- Credit Cards Table
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
  status TEXT NOT NULL DEFAULT 'PENDING_APPROVAL' CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED', 'PENDING_APPROVAL')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Credit Transactions Table
CREATE TABLE IF NOT EXISTS credit_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES credit_cards(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_cents INTEGER NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('PURCHASE', 'PAYMENT', 'INTEREST', 'FEE', 'REWARD', 'REFUND')),
  description TEXT NOT NULL,
  merchant TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Credit Payments Table  
CREATE TABLE IF NOT EXISTS credit_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES credit_cards(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_cents INTEGER NOT NULL,
  payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_on_time BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_credit_cards_user_id ON credit_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_cards_status ON credit_cards(status);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_card_id ON credit_transactions(card_id);
CREATE INDEX IF NOT EXISTS idx_credit_transactions_user_id ON credit_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_payments_card_id ON credit_payments(card_id);
CREATE INDEX IF NOT EXISTS idx_credit_payments_user_id ON credit_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_payments_date ON credit_payments(payment_date);

-- Enable Row Level Security
ALTER TABLE credit_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own credit cards"
  ON credit_cards FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own credit cards"
  ON credit_cards FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own credit cards"
  ON credit_cards FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own credit transactions"
  ON credit_transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own credit transactions"
  ON credit_transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own credit payments"
  ON credit_payments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own credit payments"
  ON credit_payments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

