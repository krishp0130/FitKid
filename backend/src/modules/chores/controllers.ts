import { z } from 'zod'
import type { FastifyReply, FastifyRequest } from 'fastify'
import { getAuthUserFromBearer } from '../auth/services/authUser.js'
import { fetchUserRecord } from '../auth/services/userService.js'
import { createChoreForChild, fetchChore, fetchChoresForUser, updateChoreStatus, updateChore, addRewardToWallet } from './services.js'
import type { ChoreStatus } from './types.js'
import { CHORE_PRESETS } from './presets.js'
import { cacheService } from '../../services/cacheService.js'

const CreateChoreBody = z.object({
  assigneeId: z.string().uuid(),
  title: z.string().min(1),
  description: z
    .string()
    .optional()
    .nullable()
    .transform(val => (val === undefined || val === null || val === '' ? null : val)),
  reward: z.coerce.number().positive(),
  dueDate: z
    .string()
    .optional()
    .nullable()
    .transform(val => (val === undefined || val === null || val === '' ? null : val)),
  recurrenceType: z.enum(['NONE', 'DAILY', 'WEEKLY', 'MONTHLY']).optional().nullable().default('NONE'),
  recurrenceConfig: z.string().optional().nullable()
})

export async function listChoresController(request: FastifyRequest, reply: FastifyReply) {
  try {
    const authUser = await getAuthUserFromBearer(request)
    if (!authUser) return reply.unauthorized('Missing or invalid token')

    const caller = await fetchUserRecord(authUser.id)
    if (!caller) return reply.forbidden('User not onboarded')

    // Try to get from cache first
    const cacheKey = cacheService.keys.userChores(authUser.id)
    const cached = await cacheService.get<any[]>(cacheKey)
    
    if (cached) {
      return reply.send({ chores: cached })
    }

    // Cache miss - fetch from database
    const chores = await fetchChoresForUser(authUser.id, caller.role as any, caller.family_id)
    
    // For children, we need to handle assigneeName differently since it's not in the query result
    const mappedChores = chores.map(chore => {
      // For child users, the assignee is themselves, so use caller.username
      const assigneeName = caller.role === 'CHILD' ? caller.username : undefined
      return mapChore(chore, assigneeName)
    })
    
    // Store in cache for 1 second (for real-time updates)
    await cacheService.set(cacheKey, mappedChores, { ttl: 1 })
    
    return reply.send({ chores: mappedChores })
  } catch (err: any) {
    request.log.error({ err, message: err.message, stack: err.stack }, 'Failed to fetch chores')
    return reply.internalServerError(err.message || 'Failed to fetch chores')
  }
}

export async function createChoreController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'PARENT') return reply.forbidden('Only parents can create chores')

  const parseResult = CreateChoreBody.safeParse(request.body)
  if (!parseResult.success) {
    request.log.error({ zodError: parseResult.error.errors, body: request.body }, 'Invalid chore payload')
    const msg =
      parseResult.error.errors
        .map(e => `${e.path.join('.') || 'field'}: ${e.message}`)
        .join('; ') || 'Invalid payload'
    return reply.badRequest(msg)
  }

  const { assigneeId, title, description, reward, dueDate, recurrenceType, recurrenceConfig } = parseResult.data

  // Ensure assignee is in same family and is a child
  const assignee = await fetchUserRecord(assigneeId)
  if (!assignee || assignee.family_id !== caller.family_id || assignee.role !== 'CHILD') {
    return reply.forbidden('Assignee must be a child in your family')
  }

  try {
    const chore = await createChoreForChild({ 
      assigneeId, 
      title, 
      description, 
      rewardDollars: reward, 
      dueDate,
      recurrenceType: recurrenceType === 'NONE' ? null : recurrenceType,
      recurrenceConfig: recurrenceConfig ?? null
    })
    
    // Invalidate chore caches for both parent and child
    await cacheService.delete(cacheService.keys.userChores(authUser.id)) // parent
    await cacheService.delete(cacheService.keys.userChores(assigneeId)) // child
    
    return reply.code(201).send({ chore: mapChore(chore, assignee.username) })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to create chore')
    return reply.internalServerError('Failed to create chore')
  }
}

export async function submitChoreController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')
  const choreId = (request.params as any)?.id as string
  if (!choreId) return reply.badRequest('Missing chore id')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller) return reply.forbidden('User not onboarded')

  const chore = await fetchChore(choreId)
  if (!chore || chore.assignee_id !== caller.id) return reply.forbidden('Not allowed')

  try {
    const updated = await updateChoreStatus(choreId, 'PENDING_APPROVAL')
    
    // Invalidate chore caches for both parent and child
    await cacheService.delete(cacheService.keys.userChores(caller.id)) // child
    // Also need to invalidate parent's cache - we can use family invalidation
    if (caller.family_id) {
      await cacheService.deletePattern(`user:*:chores`)
    }
    
    return reply.send({ chore: mapChore(updated) })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to submit chore')
    return reply.internalServerError('Failed to submit chore')
  }
}

export async function approveChoreController(request: FastifyRequest, reply: FastifyReply) {
  return handleDecision(request, reply, 'COMPLETED')
}

export async function rejectChoreController(request: FastifyRequest, reply: FastifyReply) {
  return handleDecision(request, reply, 'REJECTED')
}

export async function updateChoreController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')
  
  const choreId = (request.params as any)?.id as string
  if (!choreId) return reply.badRequest('Missing chore id')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'PARENT') return reply.forbidden('Only parents can update chores')

  const parseResult = CreateChoreBody.partial().safeParse(request.body)
  if (!parseResult.success) {
    return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
  }

  const chore = await fetchChore(choreId)
  if (!chore) return reply.notFound('Chore not found')

  // Ensure chore belongs to caller's family
  const assignee = await fetchUserRecord(chore.assignee_id)
  if (!assignee || assignee.family_id !== caller.family_id) return reply.forbidden('Not allowed')

  const { title, description, reward, dueDate, recurrenceType, recurrenceConfig } = parseResult.data

  try {
    const updated = await updateChore(choreId, {
      title,
      description,
      rewardDollars: reward,
      dueDate,
      recurrenceType: recurrenceType === 'NONE' ? null : recurrenceType,
      recurrenceConfig
    })
    
    // Invalidate chore caches for both parent and child
    await cacheService.delete(cacheService.keys.userChores(authUser.id)) // parent
    await cacheService.delete(cacheService.keys.userChores(chore.assignee_id)) // child
    
    return reply.send({ chore: mapChore(updated, assignee.username) })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to update chore')
    return reply.internalServerError('Failed to update chore')
  }
}

export async function listPresetsController(request: FastifyRequest, reply: FastifyReply) {
  return reply.send({ presets: CHORE_PRESETS })
}

async function handleDecision(request: FastifyRequest, reply: FastifyReply, status: ChoreStatus) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')
  const choreId = (request.params as any)?.id as string
  if (!choreId) return reply.badRequest('Missing chore id')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'PARENT') return reply.forbidden('Only parents can decide')

  const chore = await fetchChore(choreId)
  if (!chore) return reply.notFound('Chore not found')

  // ensure chore belongs to the caller's family
  const assignee = await fetchUserRecord(chore.assignee_id)
  if (!assignee || assignee.family_id !== caller.family_id) return reply.forbidden('Not allowed')

  try {
    const updated = await updateChoreStatus(choreId, status)
    
    // If approved, add reward to user's wallet balance
    if (status === 'COMPLETED') {
      try {
        await addRewardToWallet(chore.assignee_id, chore.reward_value_cents)
        // Invalidate wallet cache
        await cacheService.delete(cacheService.keys.userWallet(chore.assignee_id))
      } catch (walletErr: any) {
        // Log error but don't fail the request - the chore is already marked as completed
        request.log.warn({ err: walletErr }, 'Failed to update wallet balance, but chore was approved')
      }
    }
    
    // Invalidate chore caches for both parent and child
    await cacheService.delete(cacheService.keys.userChores(authUser.id)) // parent
    await cacheService.delete(cacheService.keys.userChores(chore.assignee_id)) // child
    
    return reply.send({ chore: mapChore(updated, assignee.username) })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to update chore')
    return reply.internalServerError('Failed to update chore')
  }
}

function mapChore(chore: any, assigneeName?: string) {
  return {
    id: chore.id,
    title: chore.title,
    detail: chore.description ?? '',
    reward: (chore.reward_value_cents ?? 0) / 100,
    status: chore.status,
    assigneeId: chore.assignee_id,
    assigneeName: assigneeName ?? chore.assignee_username ?? null,
    dueDate: chore.due_date ?? null,
    recurrenceType: chore.recurrence_type ?? null,
    recurrenceConfig: chore.recurrence_config ?? null,
    parentChoreId: chore.parent_chore_id ?? null
  }
}
