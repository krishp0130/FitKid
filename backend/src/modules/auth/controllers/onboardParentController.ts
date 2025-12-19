import { z } from 'zod'
import type { FastifyReply, FastifyRequest } from 'fastify'
import { getAuthUserFromBearer } from '../services/authUser.js'
import { createParentUser, fetchUserRecord } from '../services/userService.js'
import { mapUser } from '../responses.js'

const ParentOnboardBody = z.object({
  familyName: z.string().min(1),
  username: z.string().min(1)
})

export async function onboardParentController(request: FastifyRequest, reply: FastifyReply) {
  const authUser = await getAuthUserFromBearer(request)
  if (!authUser) return reply.unauthorized('Missing or invalid token')

  const parseResult = ParentOnboardBody.safeParse(request.body)
  if (!parseResult.success) {
    return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
  }

  const existing = await fetchUserRecord(authUser.id)
  if (existing) {
    return reply.conflict('User already onboarded')
  }

  const { familyName, username } = parseResult.data

  try {
    const newUser = await createParentUser(authUser, username, familyName)
    return reply.send({ user: mapUser(newUser) })
  } catch (err: any) {
    request.log.error({ err }, 'Failed to onboard parent')
    return reply.internalServerError('Failed to onboard parent')
  }
}
