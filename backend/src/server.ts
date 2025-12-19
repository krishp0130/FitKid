import Fastify from 'fastify'
import fastifyCors from '@fastify/cors'
import fastifySensible from '@fastify/sensible'
import { env } from './config/env.js'
import { authRoutes } from './modules/auth/routes.js'

async function buildServer() {
  const app = Fastify({
    logger: true
  })

  await app.register(fastifyCors, { origin: true })
  await app.register(fastifySensible)

  app.get('/health', async () => ({ status: 'ok' }))

  await app.register(authRoutes)

  return app
}

buildServer()
  .then(app => app.listen({ port: env.port, host: '0.0.0.0' }))
  .then(address => {
    console.log(`Server listening at ${address}`)
  })
  .catch(err => {
    console.error(err)
    process.exit(1)
  })
