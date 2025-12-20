import type { FastifyReply, FastifyRequest } from 'fastify'
import { getAuthUserFromBearer } from '../services/authUser.js'
import { fetchUserRecord, fetchFamilyMembers } from '../services/userService.js'
import { mapUser } from '../responses.js'
import { cacheService } from '../../../services/cacheService.js'

export async function familyMembersController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  // Get the caller's family id
  const caller = await fetchUserRecord(authUser.id)
  if (!caller) return reply.forbidden('User not onboarded')

  try {
    // Try to get from cache first
    const cacheKey = cacheService.keys.familyMembers(caller.family_id)
    const cached = await cacheService.get<any[]>(cacheKey)
    
    if (cached) {
      return reply.send({ members: cached })
    }

    // Cache miss - fetch from database
    const members = await fetchFamilyMembers(caller.family_id)
    const mappedMembers = members.map(member => mapUser(member))
    
    // Store in cache for 30 seconds
    await cacheService.set(cacheKey, mappedMembers, { ttl: 30 })
    
    return reply.send({ members: mappedMembers })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to fetch family members')
    return reply.internalServerError('Failed to fetch family members')
  }
}
