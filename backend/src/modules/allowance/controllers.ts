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

export async function listAllowancesController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'PARENT') return reply.forbidden('Only parents can list allowances')

  try {
    const { data, error } = await supabaseDb
      .from('allowances')
      .select('id, child_id, amount_cents, frequency, custom_interval_days, created_at')
      .eq('family_id', caller.family_id)
      .order('created_at', { ascending: false })

    if (error) throw error

    const allowances = (data ?? []).map((row: any) => ({
      id: row.id,
      childId: row.child_id,
      amountCents: row.amount_cents,
      frequency: row.frequency,
      customIntervalDays: row.custom_interval_days ?? null,
      createdAt: row.created_at
    }))

    return reply.send({ allowances })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to list allowances')
    return reply.internalServerError(err.message ?? 'Failed to list allowances')
  }
}

export async function deleteAllowanceController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'PARENT') return reply.forbidden('Only parents can delete allowances')

  const allowanceId = (request.params as any)?.id as string
  if (!allowanceId) return reply.badRequest('Missing allowance id')

  try {
    const { data: existing, error: fetchErr } = await supabaseDb
      .from('allowances')
      .select('id, family_id')
      .eq('id', allowanceId)
      .single()

    if (fetchErr || !existing) return reply.notFound('Allowance not found')
    if (existing.family_id !== caller.family_id) return reply.forbidden('Not allowed')

    const { error: deleteErr } = await supabaseDb.from('allowances').delete().eq('id', allowanceId)

    if (deleteErr) throw deleteErr
    return reply.code(204).send()
  } catch (err: any) {
    request.log.error({ err }, 'Failed to delete allowance')
    return reply.internalServerError(err.message ?? 'Failed to delete allowance')
  }
}

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

