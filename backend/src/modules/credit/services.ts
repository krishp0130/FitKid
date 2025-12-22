import { supabaseDb } from '../../config/supabase.js'
import type {
  DbCreditCard,
  DbCreditTransaction,
  DbCreditPayment,
  CreditScoreFactors,
  CreditTier,
  CreditCardStatus,
  TransactionType
} from './types.js'
import { TIER_CONFIG } from './types.js'

/**
 * Calculate credit score based on kid-friendly algorithm
 * Mimics real credit scoring but simplified for education
 */
export async function calculateCreditScore(userId: string): Promise<CreditScoreFactors> {
  // Get all user's cards
  const { data: cards } = await supabaseDb
    .from('credit_cards')
    .select('*')
    .eq('user_id', userId)
    .eq('status', 'ACTIVE')

  if (!cards || cards.length === 0) {
    // No credit history - start at 300
    return {
      payment_history_score: 0,
      utilization_score: 0,
      credit_age_score: 0,
      credit_mix_score: 0,
      total_score: 300
    }
  }

  // 1. Payment History (40% weight) - Most important!
  const paymentScore = await calculatePaymentHistoryScore(userId)

  // 2. Utilization (30% weight) - How much credit they're using
  const utilizationScore = calculateUtilizationScore(cards)

  // 3. Credit Age (20% weight) - How long they've had credit
  const creditAgeScore = calculateCreditAgeScore(cards)

  // 4. Credit Mix (10% weight) - Number of different cards
  const creditMixScore = calculateCreditMixScore(cards.length)

  // Calculate total score (300-850 range)
  const weightedScore = 
    (paymentScore * 0.40) +
    (utilizationScore * 0.30) +
    (creditAgeScore * 0.20) +
    (creditMixScore * 0.10)

  // Convert 0-100 score to 300-850 range
  const totalScore = Math.round(300 + (weightedScore / 100) * 550)

  return {
    payment_history_score: Math.round(paymentScore),
    utilization_score: Math.round(utilizationScore),
    credit_age_score: Math.round(creditAgeScore),
    credit_mix_score: Math.round(creditMixScore),
    total_score: Math.min(850, Math.max(300, totalScore))
  }
}

async function calculatePaymentHistoryScore(userId: string): Promise<number> {
  // Get all payments in last 12 months
  const oneYearAgo = new Date()
  oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1)

  const { data: payments } = await supabaseDb
    .from('credit_payments')
    .select('*')
    .eq('user_id', userId)
    .gte('payment_date', oneYearAgo.toISOString())

  if (!payments || payments.length === 0) return 50 // Neutral score for no history

  // Calculate on-time payment percentage
  const onTimePayments = payments.filter(p => p.is_on_time).length
  const onTimePercentage = (onTimePayments / payments.length) * 100

  // Perfect payment history = 100, each missed payment hurts
  return onTimePercentage
}

function calculateUtilizationScore(cards: any[]): number {
  let totalLimit = 0
  let totalBalance = 0

  for (const card of cards) {
    totalLimit += card.limit_cents
    totalBalance += card.balance_cents
  }

  if (totalLimit === 0) return 100 // No credit = perfect score

  const utilization = (totalBalance / totalLimit) * 100

  // Best utilization is under 30%
  if (utilization <= 30) return 100
  if (utilization <= 50) return 80
  if (utilization <= 70) return 60
  if (utilization <= 90) return 40
  return 20 // Over 90% is bad
}

function calculateCreditAgeScore(cards: any[]): number {
  const now = new Date()
  let totalAgeDays = 0

  for (const card of cards) {
    const openedDate = new Date(card.opened_at)
    const ageDays = (now.getTime() - openedDate.getTime()) / (1000 * 60 * 60 * 24)
    totalAgeDays += ageDays
  }

  const avgAgeDays = totalAgeDays / cards.length

  // Score based on average age of accounts
  if (avgAgeDays >= 365) return 100      // 1+ year = excellent
  if (avgAgeDays >= 180) return 80       // 6+ months = good
  if (avgAgeDays >= 90) return 60        // 3+ months = fair
  if (avgAgeDays >= 30) return 40        // 1+ month = building
  return 20                               // Less than 1 month = new
}

function calculateCreditMixScore(numCards: number): number {
  // Having multiple cards shows responsibility
  if (numCards >= 3) return 100
  if (numCards === 2) return 75
  if (numCards === 1) return 50
  return 0
}

/**
 * Determine appropriate tier based on credit score
 */
export function determineTier(creditScore: number): CreditTier {
  if (creditScore >= TIER_CONFIG.ELITE.minScore) return 'ELITE'
  if (creditScore >= TIER_CONFIG.STRONG.minScore) return 'STRONG'
  if (creditScore >= TIER_CONFIG.BUILDER.minScore) return 'BUILDER'
  return 'STARTER'
}

/**
 * Check if user is eligible for tier upgrade
 */
export async function checkTierUpgradeEligibility(userId: string, cardId: string): Promise<{
  eligible: boolean
  currentTier: CreditTier
  newTier: CreditTier | null
  creditScore: number
}> {
  const scoreFactors = await calculateCreditScore(userId)
  const currentTier = await getCurrentCardTier(cardId)
  const newTier = determineTier(scoreFactors.total_score)

  const tierOrder = ['STARTER', 'BUILDER', 'STRONG', 'ELITE']
  const eligible = tierOrder.indexOf(newTier) > tierOrder.indexOf(currentTier)

  return {
    eligible,
    currentTier,
    newTier: eligible ? newTier : null,
    creditScore: scoreFactors.total_score
  }
}

async function getCurrentCardTier(cardId: string): Promise<CreditTier> {
  const { data } = await supabaseDb
    .from('credit_cards')
    .select('tier')
    .eq('id', cardId)
    .single()

  return (data?.tier as CreditTier) || 'STARTER'
}

/**
 * Apply for a new credit card
 */
export async function applyForCreditCard(userId: string, requestedTier?: CreditTier) {
  // Calculate what tier they qualify for
  const scoreFactors = await calculateCreditScore(userId)
  const qualifiedTier = determineTier(scoreFactors.total_score)

  // Use qualified tier or requested tier (whichever is lower)
  const tierOrder = ['STARTER', 'BUILDER', 'STRONG', 'ELITE']
  let assignedTier = qualifiedTier

  if (requestedTier) {
    const requestedIndex = tierOrder.indexOf(requestedTier)
    const qualifiedIndex = tierOrder.indexOf(qualifiedTier)
    assignedTier = requestedIndex <= qualifiedIndex ? requestedTier : qualifiedTier
  }

  const config = TIER_CONFIG[assignedTier]

  const { data, error } = await supabaseDb
    .from('credit_cards')
    .insert({
      user_id: userId,
      card_name: config.name,
      tier: assignedTier,
      limit_cents: config.limitCents,
      balance_cents: 0,
      apr: config.apr,
      rewards_rate: config.rewards,
      opened_at: new Date().toISOString(),
      status: 'PENDING_APPROVAL'
    })
    .select()
    .single()

  if (error) throw error
  return data
}

/**
 * Make a credit card purchase
 */
export async function makeCreditPurchase(
  cardId: string,
  userId: string,
  amountCents: number,
  description: string,
  merchant?: string
): Promise<DbCreditTransaction> {
  // Get card
  const { data: card } = await supabaseDb
    .from('credit_cards')
    .select('*')
    .eq('id', cardId)
    .eq('user_id', userId)
    .single()

  if (!card) throw new Error('Card not found')
  if (card.status !== 'ACTIVE') throw new Error('Card is not active')

  const newBalance = card.balance_cents + amountCents

  // Check credit limit
  if (newBalance > card.limit_cents) {
    throw new Error('Purchase would exceed credit limit')
  }

  // Update card balance
  await supabaseDb
    .from('credit_cards')
    .update({ balance_cents: newBalance })
    .eq('id', cardId)

  // Create transaction record
  const { data: transaction, error } = await supabaseDb
    .from('credit_transactions')
    .insert({
      card_id: cardId,
      user_id: userId,
      amount_cents: amountCents,
      transaction_type: 'PURCHASE',
      description,
      merchant: merchant || null
    })
    .select()
    .single()

  if (error) throw error
  return transaction as DbCreditTransaction
}

/**
 * Make a payment on credit card
 */
export async function makeCreditPayment(
  cardId: string,
  userId: string,
  amountCents: number
): Promise<{ payment: DbCreditPayment; newBalance: number }> {
  // Get card
  const { data: card } = await supabaseDb
    .from('credit_cards')
    .select('*')
    .eq('id', cardId)
    .eq('user_id', userId)
    .single()

  if (!card) throw new Error('Card not found')
  if (amountCents <= 0) throw new Error('Payment amount must be positive')
  if (amountCents > card.balance_cents) {
    throw new Error('Payment amount exceeds balance')
  }

  const newBalance = card.balance_cents - amountCents

  // Update card balance
  await supabaseDb
    .from('credit_cards')
    .update({ 
      balance_cents: newBalance,
      last_payment_at: new Date().toISOString()
    })
    .eq('id', cardId)

  // Determine if payment is on time (within first 5 days of month)
  const today = new Date().getDate()
  const isOnTime = today <= 5

  // Create payment record
  const { data: payment, error } = await supabaseDb
    .from('credit_payments')
    .insert({
      card_id: cardId,
      user_id: userId,
      amount_cents: amountCents,
      payment_date: new Date().toISOString(),
      is_on_time: isOnTime
    })
    .select()
    .single()

  if (error) throw error

  // Create transaction record
  await supabaseDb
    .from('credit_transactions')
    .insert({
      card_id: cardId,
      user_id: userId,
      amount_cents: -amountCents, // Negative for payment
      transaction_type: 'PAYMENT',
      description: 'Payment received'
    })

  return { payment: payment as DbCreditPayment, newBalance }
}

/**
 * Get user's credit cards
 */
export async function getUserCreditCards(userId: string): Promise<DbCreditCard[]> {
  const { data, error } = await supabaseDb
    .from('credit_cards')
    .select('*')
    .eq('user_id', userId)
    .order('opened_at', { ascending: false })

  if (error) throw error
  return (data || []) as DbCreditCard[]
}

/**
 * Get credit card transactions
 */
export async function getCreditTransactions(
  cardId: string,
  userId: string,
  limit: number = 50
): Promise<DbCreditTransaction[]> {
  const { data, error } = await supabaseDb
    .from('credit_transactions')
    .select('*')
    .eq('card_id', cardId)
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit)

  if (error) throw error
  return (data || []) as DbCreditTransaction[]
}

/**
 * Upgrade credit card tier
 */
export async function upgradeCreditCardTier(cardId: string, userId: string): Promise<DbCreditCard> {
  const eligibility = await checkTierUpgradeEligibility(userId, cardId)

  if (!eligibility.eligible) {
    throw new Error('Not eligible for upgrade')
  }

  const newTier = eligibility.newTier!
  const config = TIER_CONFIG[newTier]

  const { data, error } = await supabaseDb
    .from('credit_cards')
    .update({
      tier: newTier,
      card_name: config.name,
      limit_cents: config.limitCents,
      apr: config.apr,
      rewards_rate: config.rewards
    })
    .eq('id', cardId)
    .eq('user_id', userId)
    .select()
    .single()

  if (error) throw error
  return data as DbCreditCard
}

