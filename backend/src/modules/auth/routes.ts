import { FastifyInstance } from 'fastify'
import { googleSignInController } from './controllers/googleController.js'
import { appleSignInController } from './controllers/appleController.js'
import { onboardParentController } from './controllers/onboardParentController.js'
import { onboardChildController } from './controllers/onboardChildController.js'
import { familyMembersController } from './controllers/familyController.js'
import {
  listChoresController,
  createChoreController,
  updateChoreController,
  submitChoreController,
  approveChoreController,
  rejectChoreController,
  listPresetsController
} from '../chores/controllers.js'
import { walletBalanceController } from '../ledger/controller.js'
import {
  approveRequestController,
  createRequestController,
  listRequestsController,
  rejectRequestController
} from '../requests/controllers.js'
import {
  getCreditScoreController,
  listCreditCardsController,
  applyCreditCardController,
  makePurchaseController,
  makePaymentController,
  getTransactionsController,
  checkUpgradeController,
  upgradeTierController,
  approveCardController
} from '../credit/controllers.js'

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

  // Chores - presets must come before /:id routes
  app.get('/api/chores/presets', listPresetsController)
  app.get('/api/chores', listChoresController)
  app.post('/api/chores', createChoreController)
  app.put('/api/chores/:id', updateChoreController)
  app.post('/api/chores/:id/submit', submitChoreController)
  app.post('/api/chores/:id/approve', approveChoreController)
  app.post('/api/chores/:id/reject', rejectChoreController)
  // Compatibility prefix
  app.get('/api/auth/chores/presets', listPresetsController)
  app.get('/api/auth/chores', listChoresController)
  app.post('/api/auth/chores', createChoreController)
  app.put('/api/auth/chores/:id', updateChoreController)
  app.post('/api/auth/chores/:id/submit', submitChoreController)
  app.post('/api/auth/chores/:id/approve', approveChoreController)
  app.post('/api/auth/chores/:id/reject', rejectChoreController)

  // Wallet
  app.get('/api/wallet', walletBalanceController)
  app.get('/api/auth/wallet', walletBalanceController)

  // Purchase requests (children create, parents approve/reject)
  app.get('/api/requests', listRequestsController)
  app.post('/api/requests', createRequestController)
  app.post('/api/requests/:id/approve', approveRequestController)
  app.post('/api/requests/:id/reject', rejectRequestController)
  // compatibility prefix
  app.get('/api/auth/requests', listRequestsController)
  app.post('/api/auth/requests', createRequestController)
  app.post('/api/auth/requests/:id/approve', approveRequestController)
  app.post('/api/auth/requests/:id/reject', rejectRequestController)

  // Credit System
  app.get('/api/credit/score', getCreditScoreController)
  app.get('/api/credit/cards', listCreditCardsController)
  app.post('/api/credit/apply', applyCreditCardController)
  app.post('/api/credit/purchase', makePurchaseController)
  app.post('/api/credit/payment', makePaymentController)
  app.get('/api/credit/transactions/:cardId', getTransactionsController)
  app.get('/api/credit/upgrade/:cardId', checkUpgradeController)
  app.post('/api/credit/upgrade/:cardId', upgradeTierController)
  app.post('/api/credit/approve/:cardId', approveCardController)
}
