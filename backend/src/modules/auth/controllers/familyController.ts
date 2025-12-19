import type { FastifyReply, FastifyRequest } from 'fastify'
import { getAuthUserFromBearer } from '../services/authUser.js'
import { fetchUserRecord, fetchFamilyMembers } from '../services/userService.js'
import { mapUser } from '../responses.js'

export async function familyMembersController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  // Get the caller's family id
  const caller = await fetchUserRecord(authUser.id)
  if (!caller) return reply.forbidden('User not onboarded')

  try {
    const members = await fetchFamilyMembers(caller.family_id)
    return reply.send({ members: members.map(member => mapUser(member)) })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to fetch family members')
    return reply.internalServerError('Failed to fetch family members')
  }
}
