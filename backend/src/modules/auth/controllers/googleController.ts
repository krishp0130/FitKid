import { z } from 'zod'
import type { FastifyReply, FastifyRequest } from 'fastify'
import { supabaseAuth } from '../../../config/supabase.js'
import { buildAuthResponse } from '../responses.js'
import { fetchUserRecord } from '../services/userService.js'

const GoogleAuthBody = z.object({
  idToken: z.string().min(10, 'idToken is required')
})

export async function googleSignInController(request: FastifyRequest, reply: FastifyReply) {
  const parseResult = GoogleAuthBody.safeParse(request.body)
  if (!parseResult.success) {
    return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
  }

  const { idToken } = parseResult.data

  const { data, error } = await supabaseAuth.auth.signInWithIdToken({
    provider: 'google',
    token: idToken
  })

  if (error || !data.session || !data.user) {
    request.log.error({ error, data }, 'Google token exchange failed')
    const errorMessage = error?.message ?? 'Invalid Google credentials'
    return reply.unauthorized(`Google authentication failed: ${errorMessage}`)
  }

  const dbUser = await fetchUserRecord(data.user.id)
  const status = dbUser ? 'EXISTING_USER' : 'NEEDS_ONBOARDING'

  return reply.send(buildAuthResponse(status, data.session, dbUser, (data.user.user_metadata as any)?.parent_code))
}
