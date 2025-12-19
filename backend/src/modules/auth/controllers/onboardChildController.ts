import { z } from 'zod'
import type { FastifyReply, FastifyRequest } from 'fastify'
import { getAuthUserFromBearer } from '../services/authUser.js'
import { createChildUser, fetchUserRecord } from '../services/userService.js'
import { mapUser } from '../responses.js'

const ChildOnboardBody = z.object({
  familyId: z.string().uuid(),
  username: z.string().min(1)
})

export async function onboardChildController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const parseResult = ChildOnboardBody.safeParse(request.body)
  if (!parseResult.success) {
    return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
  }

  const existing = await fetchUserRecord(authUser.id)
  if (existing) {
    return reply.conflict('User already onboarded')
  }

  const { familyId, username } = parseResult.data

  try {
    const newUser = await createChildUser(authUser, username, familyId)
    return reply.send({ user: mapUser(newUser) })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to onboard child')
    if (err?.message === 'Family not found') {
      return reply.badRequest('Family not found')
    }
    return reply.internalServerError('Failed to onboard child')
  }
}
