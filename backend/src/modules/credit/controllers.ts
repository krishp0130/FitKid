import { z } from 'zod'
import type { FastifyReply, FastifyRequest } from 'fastify'
import { getAuthUserFromBearer } from '../auth/services/authUser.js'
import { fetchUserRecord, updateUserCreditScore } from '../auth/services/userService.js'
import { cacheService } from '../../services/cacheService.js'
import { createPurchaseRequest } from '../requests/services.js'
import {
  calculateCreditScore,
  getUserCreditCards,
  applyForCreditCard,
  makeCreditPurchase,
  makeCreditPayment,
  getCreditTransactions,
  checkTierUpgradeEligibility,
  upgradeCreditCardTier
} from './services.js'
import { TIER_CONFIG, type CreditTier } from './types.js'

const ApplyCardBody = z.object({
  requestedTier: z.enum(['STARTER', 'BUILDER', 'STRONG', 'ELITE']).optional()
})

const PurchaseBody = z.object({
  cardId: z.string().uuid(),
  amountCents: z.number().positive(),
  description: z.string().min(1),
  merchant: z.string().optional()
})

const PaymentBody = z.object({
  cardId: z.string().uuid(),
  amountCents: z.number().positive()
})

/**
 * GET /api/credit/score
 * Get user's current credit score and breakdown
 */
export async function getCreditScoreController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller) return reply.forbidden('User not onboarded')

  try {
    const scoreFactors = await calculateCreditScore(caller.id)
    try {
      await updateUserCreditScore(caller.id, scoreFactors.total_score)
    } catch (updateErr: any) {
      request.log.warn({ err: updateErr }, 'Failed to persist credit score')
    }
    
    return reply.send({
      creditScore: scoreFactors.total_score,
      factors: {
        paymentHistory: scoreFactors.payment_history_score,
        utilization: scoreFactors.utilization_score,
        creditAge: scoreFactors.credit_age_score,
        creditMix: scoreFactors.credit_mix_score
      },
      explanation: {
        paymentHistory: 'Your on-time payment record (40% of score)',
        utilization: 'How much of your credit limit you use (30%)',
        creditAge: 'How long you\'ve had credit (20%)',
        creditMix: 'Number of credit cards (10%)'
      }
    })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to calculate credit score')
    return reply.internalServerError('Failed to calculate credit score')
  }
}

/**
 * GET /api/credit/cards
 * Get all user's credit cards
 */
export async function listCreditCardsController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller) return reply.forbidden('User not onboarded')

  try {
    const cards = await getUserCreditCards(caller.id)
    
    const mappedCards = cards.map(card => ({
      id: card.id,
      cardName: card.card_name,
      tier: card.tier,
      limit: card.limit_cents / 100,
      balance: card.balance_cents / 100,
      apr: card.apr,
      rewardsRate: card.rewards_rate,
      openedAt: card.opened_at,
      lastPaymentAt: card.last_payment_at,
      status: card.status,
      utilization: card.limit_cents > 0 
        ? Math.round((card.balance_cents / card.limit_cents) * 100)
        : 0
    }))

    return reply.send({ cards: mappedCards })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to fetch credit cards')
    return reply.internalServerError('Failed to fetch credit cards')
  }
}

/**
 * GET /api/credit/applications (Parent only)
 * List pending credit card applications for a family
 */
export async function listCardApplicationsController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'PARENT') {
    return reply.forbidden('Only parents can view card applications')
  }

  const cacheKey = cacheService.keys.familyCardApplications(caller.family_id)
  const cached = await cacheService.get<any[]>(cacheKey)
  if (cached) {
    return reply.send({ applications: cached })
  }

  try {
    const { data, error } = await supabaseDb
      .from('credit_cards')
      .select('id, user_id, card_name, tier, limit_cents, status, created_at, users!inner(username, family_id)')
      .eq('status', 'PENDING_APPROVAL')
      .eq('users.family_id', caller.family_id)
      .order('created_at', { ascending: false })

    if (error) throw error

    const applications = (data ?? []).map((row: any) => ({
      id: row.id,
      cardName: row.card_name,
      tier: row.tier,
      limit: row.limit_cents / 100,
      requesterName: row.users?.username ?? null,
      createdAt: row.created_at,
      status: row.status
    }))

    await cacheService.set(cacheKey, applications, { ttl: 10 })

    return reply.send({ applications })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to fetch card applications')
    return reply.internalServerError('Failed to fetch card applications')
  }
}

/**
 * POST /api/credit/apply
 * Apply for a new credit card
 */
export async function applyCreditCardController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'CHILD') {
    return reply.forbidden('Only children can apply for credit cards')
  }

  const parseResult = ApplyCardBody.safeParse(request.body)
  if (!parseResult.success) {
    return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
  }

  const { requestedTier } = parseResult.data

  try {
    const card = await applyForCreditCard(caller.id, requestedTier as CreditTier | undefined)
    // Create a purchase request so parent sees the application
    await createPurchaseRequest({
      familyId: caller.family_id,
      requesterId: caller.id,
      requesterName: caller.username,
      title: 'Credit Card Application',
      description: `Requested tier: ${card.tier}`,
      url: null,
      imageUrl: null,
      priceDollars: 0,
      paymentMethod: 'CREDIT_CARD_APPLICATION',
      cardId: card.id,
      cardName: card.card_name
    })
    // Invalidate requests cache for family and requester
    await cacheService.delete(cacheService.keys.familyRequests(caller.family_id))
    await cacheService.delete(cacheService.keys.userRequests(caller.id))
    await cacheService.delete(cacheService.keys.familyCardApplications(caller.family_id))
    
    return reply.code(201).send({
      card: {
        id: card.id,
        cardName: card.card_name,
        tier: card.tier,
        limit: card.limit_cents / 100,
        balance: card.balance_cents / 100,
        apr: card.apr,
        rewardsRate: card.rewards_rate,
        status: card.status,
        openedAt: card.opened_at,
        lastPaymentAt: card.last_payment_at,
        utilization: card.limit_cents > 0 
          ? Math.round((card.balance_cents / card.limit_cents) * 100)
          : 0
      },
      message: 'Credit card application submitted! Awaiting parent approval.'
    })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to apply for credit card')
    return reply.internalServerError(err.message || 'Failed to apply for credit card')
  }
}

/**
 * POST /api/credit/purchase
 * Make a purchase with credit card
 */
export async function makePurchaseController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'CHILD') {
    return reply.forbidden('Only children can make credit purchases')
  }

  const parseResult = PurchaseBody.safeParse(request.body)
  if (!parseResult.success) {
    return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
  }

  const { cardId, amountCents, description, merchant } = parseResult.data

  try {
    const transaction = await makeCreditPurchase(
      cardId,
      caller.id,
      amountCents,
      description,
      merchant
    )
    
    return reply.send({
      transaction: {
        id: transaction.id,
        amount: transaction.amount_cents / 100,
        description: transaction.description,
        merchant: transaction.merchant,
        date: transaction.created_at
      },
      message: 'Purchase successful!'
    })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to process credit purchase')
    return reply.badRequest(err.message || 'Failed to process purchase')
  }
}

/**
 * POST /api/credit/payment
 * Make a payment on credit card
 */
export async function makePaymentController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'CHILD') {
    return reply.forbidden('Only children can make credit payments')
  }

  const parseResult = PaymentBody.safeParse(request.body)
  if (!parseResult.success) {
    return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
  }

  const { cardId, amountCents } = parseResult.data

  try {
    const result = await makeCreditPayment(cardId, caller.id, amountCents)
    
    return reply.send({
      payment: {
        amount: result.payment.amount_cents / 100,
        date: result.payment.payment_date,
        isOnTime: result.payment.is_on_time
      },
      newBalance: result.newBalance / 100,
      message: result.payment.is_on_time 
        ? 'Payment successful! Your credit score may improve.' 
        : 'Payment successful!'
    })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to process payment')
    return reply.badRequest(err.message || 'Failed to process payment')
  }
}

/**
 * GET /api/credit/transactions/:cardId
 * Get credit card transaction history
 */
export async function getTransactionsController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller) return reply.forbidden('User not onboarded')

  const cardId = (request.params as any)?.cardId as string
  if (!cardId) return reply.badRequest('Missing card ID')

  try {
    const transactions = await getCreditTransactions(cardId, caller.id)
    
    const mappedTransactions = transactions.map(tx => ({
      id: tx.id,
      amount: tx.amount_cents / 100,
      type: tx.transaction_type,
      description: tx.description,
      merchant: tx.merchant,
      date: tx.created_at
    }))

    return reply.send({ transactions: mappedTransactions })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to fetch transactions')
    return reply.internalServerError('Failed to fetch transactions')
  }
}

/**
 * GET /api/credit/upgrade/:cardId
 * Check if eligible for tier upgrade
 */
export async function checkUpgradeController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller) return reply.forbidden('User not onboarded')

  const cardId = (request.params as any)?.cardId as string
  if (!cardId) return reply.badRequest('Missing card ID')

  try {
    const eligibility = await checkTierUpgradeEligibility(caller.id, cardId)
    
    return reply.send({
      eligible: eligibility.eligible,
      currentTier: eligibility.currentTier,
      newTier: eligibility.newTier,
      creditScore: eligibility.creditScore,
      currentTierConfig: TIER_CONFIG[eligibility.currentTier],
      newTierConfig: eligibility.newTier ? TIER_CONFIG[eligibility.newTier] : null
    })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to check upgrade eligibility')
    return reply.internalServerError('Failed to check upgrade eligibility')
  }
}

/**
 * POST /api/credit/upgrade/:cardId
 * Upgrade credit card to higher tier
 */
export async function upgradeTierController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'CHILD') {
    return reply.forbidden('Only children can upgrade cards')
  }

  const cardId = (request.params as any)?.cardId as string
  if (!cardId) return reply.badRequest('Missing card ID')

  try {
    const upgradedCard = await upgradeCreditCardTier(cardId, caller.id)
    
    return reply.send({
      card: {
        id: upgradedCard.id,
        cardName: upgradedCard.card_name,
        tier: upgradedCard.tier,
        limit: upgradedCard.limit_cents / 100,
        balance: upgradedCard.balance_cents / 100,
        apr: upgradedCard.apr,
        rewardsRate: upgradedCard.rewards_rate
      },
      message: `Congratulations! Your card has been upgraded to ${upgradedCard.tier}!`
    })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to upgrade card')
    return reply.badRequest(err.message || 'Failed to upgrade card')
  }
}

/**
 * POST /api/credit/approve/:cardId (Parent only)
 * Approve child's credit card application
 */
export async function approveCardController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'PARENT') {
    return reply.forbidden('Only parents can approve credit cards')
  }

  const cardId = (request.params as any)?.cardId as string
  if (!cardId) return reply.badRequest('Missing card ID')

  try {
    // TODO: Verify card belongs to family member
    // For now, just approve it
    const { data, error } = await supabaseDb
      .from('credit_cards')
      .update({ status: 'ACTIVE' })
      .eq('id', cardId)
      .select()
      .single()

    if (error) throw error

    await cacheService.delete(cacheService.keys.familyCardApplications(caller.family_id))

    return reply.send({
      card: {
        id: data.id,
        status: data.status
      },
      message: 'Credit card approved!'
    })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to approve card')
    return reply.internalServerError('Failed to approve card')
  }
}

// Import supabaseDb for approve controller
import { supabaseDb } from '../../config/supabase.js'
