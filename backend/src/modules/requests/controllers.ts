import { z } from 'zod'
import type { FastifyReply, FastifyRequest } from 'fastify'
import { getAuthUserFromBearer } from '../auth/services/authUser.js'
import { fetchUserRecord } from '../auth/services/userService.js'
import { cacheService } from '../../services/cacheService.js'
import {
  createPurchaseRequest,
  fetchRequestById,
  fetchRequestsForUser,
  toView,
  updateRequestStatus
} from './services.js'
import type { RequestStatus } from './types.js'

const CreateRequestBody = z.object({
  title: z.string().min(1),
  description: z
    .string()
    .optional()
    .nullable()
    .transform(val => (val === '' ? null : val)),
  url: z
    .string()
    .url()
    .optional()
    .nullable()
    .transform(val => (val === '' ? null : val)),
  imageUrl: z
    .string()
    .url()
    .optional()
    .nullable()
    .transform(val => (val === '' ? null : val)),
  price: z.coerce.number().positive()
})

export async function listRequestsController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller) return reply.forbidden('User not onboarded')

  const cacheKey =
    caller.role === 'PARENT'
      ? cacheService.keys.familyRequests(caller.family_id)
      : cacheService.keys.userRequests(caller.id)

  const cached = await cacheService.get<any[]>(cacheKey)
  if (cached) {
    return reply.send({ requests: cached })
  }

  try {
    const records = await fetchRequestsForUser(caller.id, caller.role as any, caller.family_id)
    const payload = records.map(toView)
    await cacheService.set(cacheKey, payload, { ttl: 1 })
    return reply.send({ requests: payload })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to fetch purchase requests')
    return reply.internalServerError(err.message || 'Failed to fetch requests')
  }
}

export async function createRequestController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller) return reply.forbidden('User not onboarded')
  if (caller.role !== 'CHILD') return reply.forbidden('Only children can request items')

  const parseResult = CreateRequestBody.safeParse(request.body)
  if (!parseResult.success) {
    const msg =
      parseResult.error.errors.map(e => `${e.path.join('.') || 'field'}: ${e.message}`).join('; ') ||
      'Invalid payload'
    return reply.badRequest(msg)
  }

  const { title, description, url, imageUrl, price } = parseResult.data

  try {
    const record = await createPurchaseRequest({
      title,
      description,
      url,
      imageUrl,
      priceDollars: price,
      familyId: caller.family_id,
      requesterId: caller.id,
      requesterName: caller.username
    })

    // Invalidate caches for family and requester
    await cacheService.delete(cacheService.keys.userRequests(caller.id))
    await cacheService.delete(cacheService.keys.familyRequests(caller.family_id))

    return reply.code(201).send({ request: toView(record) })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to create purchase request')
    return reply.internalServerError(err.message || 'Failed to create request')
  }
}

export async function approveRequestController(request: FastifyRequest, reply: FastifyReply) {
  return handleDecision(request, reply, 'APPROVED')
}

export async function rejectRequestController(request: FastifyRequest, reply: FastifyReply) {
  return handleDecision(request, reply, 'REJECTED')
}

async function handleDecision(request: FastifyRequest, reply: FastifyReply, status: RequestStatus) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')
  const requestId = (request.params as any)?.id as string
  if (!requestId) return reply.badRequest('Missing request id')

  const caller = await fetchUserRecord(authUser.id)
  if (!caller || caller.role !== 'PARENT') return reply.forbidden('Only parents can decide requests')

  const record = await fetchRequestById(requestId)
  if (!record) return reply.notFound('Request not found')
  if (record.family_id !== caller.family_id) return reply.forbidden('Not allowed')
  if (record.status !== 'PENDING') return reply.badRequest('Request already decided')

  try {
    const updated = await updateRequestStatus(requestId, status, caller.id)
    if (!updated) return reply.internalServerError('Failed to update request')

    await cacheService.delete(cacheService.keys.userRequests(record.requester_id))
    await cacheService.delete(cacheService.keys.familyRequests(record.family_id))

    return reply.send({ request: toView(updated) })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to update request status')
    return reply.internalServerError(err.message || 'Failed to update request')
  }
}
