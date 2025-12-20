import type { FastifyReply, FastifyRequest } from 'fastify'
import { getAuthUserFromBearer } from '../auth/services/authUser.js'
import { getWalletBalanceCents } from './service.js'

export async function walletBalanceController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')
  try {
    const balanceCents = await getWalletBalanceCents(authUser.id)
    return reply.send({ balanceCents })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to fetch wallet balance')
    return reply.internalServerError('Failed to fetch wallet balance')
  }
}
