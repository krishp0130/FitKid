import { z } from 'zod'
import type { FastifyReply, FastifyRequest } from 'fastify'
import { supabaseAuth } from '../../../config/supabase.js'
import { buildAuthResponse } from '../responses.js'
import { fetchUserRecord } from '../services/userService.js'

const EmailSignInBody = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters')
})

const EmailSignUpBody = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters')
})

export async function emailSignInController(request: FastifyRequest, reply: FastifyReply) {
  const parseResult = EmailSignInBody.safeParse(request.body)
  if (!parseResult.success) {
    return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
  }

  const { email, password } = parseResult.data

  const { data, error } = await supabaseAuth.auth.signInWithPassword({
    email,
    password
  })

  if (error || !data.session || !data.user) {
    request.log.error({ error }, 'Email sign-in failed')
    const errorMessage = error?.message ?? 'Invalid email or password'
    return reply.unauthorized(`Email authentication failed: ${errorMessage}`)
  }

  const dbUser = await fetchUserRecord(data.user.id)
  const status = dbUser ? 'EXISTING_USER' : 'NEEDS_ONBOARDING'

  return reply.send(buildAuthResponse(status, data.session, dbUser))
}

export async function emailSignUpController(request: FastifyRequest, reply: FastifyReply) {
  const parseResult = EmailSignUpBody.safeParse(request.body)
  if (!parseResult.success) {
    return reply.badRequest(parseResult.error.flatten().formErrors.join('; '))
  }

  const { email, password } = parseResult.data

  const { data, error } = await supabaseAuth.auth.signUp({
    email,
    password
  })

  if (error || !data.session || !data.user) {
    request.log.error({ error }, 'Email sign-up failed')
    const errorMessage = error?.message ?? 'Failed to create account'
    
    // Check if user already exists
    if (error?.message?.includes('already registered') || error?.message?.includes('already exists')) {
      return reply.conflict('Email already registered')
    }
    
    return reply.badRequest(`Email sign-up failed: ${errorMessage}`)
  }

  // New users always need onboarding
  const dbUser = await fetchUserRecord(data.user.id)
  const status = 'NEEDS_ONBOARDING'

  return reply.code(201).send(buildAuthResponse(status, data.session, dbUser))
}

