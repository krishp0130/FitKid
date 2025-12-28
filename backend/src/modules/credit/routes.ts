import type { FastifyInstance } from 'fastify'
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
} from './controllers.js'

export async function creditRoutes(app: FastifyInstance) {
  // Get credit score
  app.get('/api/credit/score', getCreditScoreController)
  
  // Credit cards
  app.get('/api/credit/cards', listCreditCardsController)
  app.post('/api/credit/apply', applyCreditCardController)
  
  // Transactions
  app.post('/api/credit/purchase', makePurchaseController)
  app.post('/api/credit/payment', makePaymentController)
  app.get('/api/credit/transactions/:cardId', getTransactionsController)
  
  // Tier management
  app.get('/api/credit/upgrade/:cardId', checkUpgradeController)
  app.post('/api/credit/upgrade/:cardId', upgradeTierController)
  
  // Parent controls
  app.post('/api/credit/approve/:cardId', approveCardController)
}


