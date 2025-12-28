export interface DbCreditCard {
  id: string
  user_id: string
  card_name: string
  tier: CreditTier
  limit_cents: number
  balance_cents: number
  apr: number
  rewards_rate: number
  opened_at: string
  last_payment_at: string | null
  status: CreditCardStatus
  created_at: string
}

export interface DbCreditTransaction {
  id: string
  card_id: string
  user_id: string
  amount_cents: number
  transaction_type: TransactionType
  description: string
  merchant: string | null
  created_at: string
}

export interface DbCreditPayment {
  id: string
  card_id: string
  user_id: string
  amount_cents: number
  payment_date: string
  is_on_time: boolean
  created_at: string
}

export interface CreditScoreFactors {
  payment_history_score: number  // 0-100
  utilization_score: number       // 0-100
  credit_age_score: number        // 0-100
  credit_mix_score: number        // 0-100
  total_score: number             // 300-850
}

export enum CreditTier {
  STARTER = 'STARTER',
  BUILDER = 'BUILDER',
  STRONG = 'STRONG',
  ELITE = 'ELITE'
}

export enum CreditCardStatus {
  ACTIVE = 'ACTIVE',
  FROZEN = 'FROZEN',
  CLOSED = 'CLOSED',
  PENDING_APPROVAL = 'PENDING_APPROVAL'
}

export enum TransactionType {
  PURCHASE = 'PURCHASE',
  PAYMENT = 'PAYMENT',
  INTEREST = 'INTEREST',
  FEE = 'FEE',
  REWARD = 'REWARD',
  REFUND = 'REFUND'
}

export const TIER_CONFIG = {
  STARTER: {
    minScore: 300,
    maxScore: 579,
    limitCents: 20000,    // $200
    apr: 0.199,           // 19.9%
    rewards: 0.0,         // 0%
    name: 'Starter Card',
    icon: 'sparkles',
    gradient: ['#8B5CF6', '#3B82F6'] // Purple to Blue
  },
  BUILDER: {
    minScore: 580,
    maxScore: 669,
    limitCents: 50000,    // $500
    apr: 0.149,           // 14.9%
    rewards: 0.01,        // 1%
    name: 'Builder Card',
    icon: 'arrow.up.right',
    gradient: ['#3B82F6', '#10B981'] // Blue to Green
  },
  STRONG: {
    minScore: 670,
    maxScore: 739,
    limitCents: 100000,   // $1000
    apr: 0.099,           // 9.9%
    rewards: 0.02,        // 2%
    name: 'Strong Card',
    icon: 'bolt.fill',
    gradient: ['#10B981', '#F59E0B'] // Green to Orange
  },
  ELITE: {
    minScore: 740,
    maxScore: 850,
    limitCents: 200000,   // $2000
    apr: 0.059,           // 5.9%
    rewards: 0.03,        // 3%
    name: 'Elite Card',
    icon: 'crown.fill',
    gradient: ['#F59E0B', '#8B5CF6'] // Orange to Purple
  }
}

export const CREDIT_SETTINGS_DEFAULTS = {
  allow_credit_cards: true,
  require_parent_approval_for_application: true,
  require_parent_approval_for_purchases: false,
  purchase_limit_per_transaction_cents: 5000, // $50
  monthly_payment_reminder_day: 1, // 1st of month
  late_payment_fee_cents: 500, // $5
  minimum_age_for_credit: 7
}


