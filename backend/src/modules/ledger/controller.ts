import type { FastifyReply, FastifyRequest } from 'fastify'
import { getAuthUserFromBearer } from '../auth/services/authUser.js'
import { getWalletBalanceCents } from './service.js'
import { cacheService } from '../../services/cacheService.js'

export async function walletBalanceController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')
  
  try {
    // Try to get from cache first
    const cacheKey = cacheService.keys.userWallet(authUser.id)
    const cached = await cacheService.get<number>(cacheKey)
    
    if (cached !== null) {
      return reply.send({ balanceCents: cached })
    }

    // Cache miss - fetch from database
    const balanceCents = await getWalletBalanceCents(authUser.id)
    
    // Store in cache for 30 seconds
    await cacheService.set(cacheKey, balanceCents, { ttl: 30 })
    
    return reply.send({ balanceCents })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to fetch wallet balance')
    return reply.internalServerError('Failed to fetch wallet balance')
  }
}
