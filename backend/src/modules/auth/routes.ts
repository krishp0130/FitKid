import { FastifyInstance } from 'fastify'
import { supabaseAdmin } from '../../config/supabase.js'
import { z } from 'zod'

const AppleAuthBody = z.object({
  idToken: z.string().min(10, 'idToken is required'),
  nonce: z.string().min(10, 'nonce is required')
})

const GoogleAuthBody = z.object({
  idToken: z.string().min(10, 'idToken is required')
})

export async function authRoutes(app: FastifyInstance) {
  app.post('/api/auth/apple', async (request, reply) => {
    const parseResult = AppleAuthBody.safeParse(request.body)
    if (!parseResult.success) {
      return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
    }

    const { idToken, nonce } = parseResult.data

    const { data, error } = await supabaseAdmin.auth.signInWithIdToken({
      provider: 'apple',
      token: idToken,
      nonce
    })

    if (error || !data.session || !data.user) {
      request.log.error({ error }, 'Apple token exchange failed')
      return reply.unauthorized('Invalid Apple credentials')
    }

    const { session, user } = data

    const response = {
      accessToken: session.access_token,
      refreshToken: session.refresh_token,
      user: {
        id: user.id,
        username: (user.user_metadata as any)?.name ?? user.email ?? 'Kidzone User',
        email: user.email,
        role: ((user.user_metadata as any)?.role as string | undefined) ?? 'CHILD',
        familyId: ((user.user_metadata as any)?.family_id as string | undefined) ?? '',
        currentCreditScore: ((user.user_metadata as any)?.current_credit_score as number | undefined) ?? 300,
        parentCode: (user.user_metadata as any)?.parent_code ?? undefined
      }
    }

    return reply.send(response)
  })

  app.post('/api/auth/google', async (request, reply) => {
    const parseResult = GoogleAuthBody.safeParse(request.body)
    if (!parseResult.success) {
      return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
    }

    const { idToken } = parseResult.data

    const { data, error } = await supabaseAdmin.auth.signInWithIdToken({
      provider: 'google',
      token: idToken
    })

    if (error || !data.session || !data.user) {
      request.log.error({ error }, 'Google token exchange failed')
      return reply.unauthorized('Invalid Google credentials')
    }

    const { session, user } = data

    const response = {
      accessToken: session.access_token,
      refreshToken: session.refresh_token,
      user: {
        id: user.id,
        username: (user.user_metadata as any)?.name ?? user.email ?? 'Kidzone User',
        email: user.email,
        role: ((user.user_metadata as any)?.role as string | undefined) ?? 'CHILD',
        familyId: ((user.user_metadata as any)?.family_id as string | undefined) ?? '',
        currentCreditScore: ((user.user_metadata as any)?.current_credit_score as number | undefined) ?? 300,
        parentCode: (user.user_metadata as any)?.parent_code ?? undefined
      }
    }

    return reply.send(response)
  })
}
