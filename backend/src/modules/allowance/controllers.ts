import { z } from 'zod'
import type { FastifyReply, FastifyRequest } from 'fastify'
import { getAuthUserFromBearer } from '../auth/services/authUser.js'
import { fetchUserRecord } from '../auth/services/userService.js'
import { supabaseDb } from '../../config/supabase.js'
import { addRewardToWallet } from '../chores/services.js'
import { cacheService } from '../../services/cacheService.js'

const AllowanceBody = z.object({
  childId: z.string().min(1),
  amountCents: z.number().int().positive(),
  frequency: z.enum(['WEEKLY', 'MONTHLY', 'CUSTOM']),
  customIntervalDays: z.number().int().positive().optional()
})

export async function createAllowanceController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'PARENT') return reply.forbidden('Only parents can add allowances')

  const parseResult = AllowanceBody.safeParse(request.body)
  if (!parseResult.success) {
    const msg =
      parseResult.error.errors.map(e => `${e.path.join('.') || 'field'}: ${e.message}`).join('; ') ||
      'Invalid payload'
    return reply.badRequest(msg)
  }

  const { childId, amountCents, frequency, customIntervalDays } = parseResult.data

  try {
    const { data: allowance, error } = await supabaseDb
      .from('allowances')
      .insert({
        child_id: childId,
        family_id: caller.family_id,
        amount_cents: amountCents,
        frequency,
        custom_interval_days: customIntervalDays ?? null
      })
      .select()
      .single()

    if (error || !allowance) {
      request.log.error({ error }, 'Failed to create allowance')
      return reply.internalServerError(error?.message ?? 'Failed to create allowance')
    }

    // Credit wallet immediately for now
    await addRewardToWallet(childId, amountCents)
    await cacheService.delete(cacheService.keys.userWallet(childId))

    return reply.code(201).send({ allowance })
  } catch (err: any) {
    request.log.error({ err }, 'Allowance creation error')
    return reply.internalServerError(err.message || 'Failed to create allowance')
  }
}

