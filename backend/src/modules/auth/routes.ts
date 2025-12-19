import { FastifyInstance } from 'fastify'
import { googleSignInController } from './controllers/googleController.js'
import { appleSignInController } from './controllers/appleController.js'
import { onboardParentController } from './controllers/onboardParentController.js'
import { onboardChildController } from './controllers/onboardChildController.js'
import { familyMembersController } from './controllers/familyController.js'

export async function authRoutes(app: FastifyInstance) {
  app.post('/api/auth/google', googleSignInController)
  app.post('/api/auth/apple', appleSignInController)

  // Canonical onboarding endpoints
  app.post('/api/onboard/parent', onboardParentController)
  app.post('/api/onboard/child', onboardChildController)

  // Backwards compatibility for older frontend builds that still post to /api/auth/onboard/*
  app.post('/api/auth/onboard/parent', onboardParentController)
  app.post('/api/auth/onboard/child', onboardChildController)

  // Family
  app.get('/api/family/members', familyMembersController)
  // Backwards compatibility if frontend still prefixes /auth
  app.get('/api/auth/family/members', familyMembersController)
}
