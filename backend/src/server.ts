import Fastify from 'fastify'
import fastifyCors from '@fastify/cors'
import fastifySensible from '@fastify/sensible'
import { env } from './config/env.js'
import { authRoutes } from './modules/auth/routes.js'
import { connectRedis, disconnectRedis } from './config/redis.js'
import { cacheService } from './services/cacheService.js'
import { supabaseDb } from './config/supabase.js'

async function buildServer() {
  const app = Fastify({
    logger: true
  })

  await app.register(fastifyCors, { origin: true })
  await app.register(fastifySensible)

  app.get('/health', async () => ({ status: 'ok' }))

  // Verify Supabase env without exposing secrets (for debugging auth issues)
  app.get('/health/supabase', async (_request, reply) => {
    try {
      const { error } = await supabaseDb.from('users').select('id').limit(1)
      if (error) {
        return reply.send({ status: 'ok', supabase: 'error', message: error.message })
      }
      return reply.send({ status: 'ok', supabase: 'connected' })
    } catch (err: any) {
      return reply.send({ status: 'ok', supabase: 'error', message: err?.message ?? 'Connection failed' })
    }
  })

  await app.register(authRoutes)

  return app
}

async function start() {
  try {
    // Connect to Redis first
    await connectRedis()
    cacheService.enable()
    
    const app = await buildServer()
    const address = await app.listen({ port: env.port, host: '0.0.0.0' })
    console.log(`✅ Server listening at ${address}`)
    
    // Handle graceful shutdown
    process.on('SIGTERM', async () => {
      console.log('SIGTERM received, shutting down gracefully...')
      await disconnectRedis()
      await app.close()
      process.exit(0)
    })

    process.on('SIGINT', async () => {
      console.log('SIGINT received, shutting down gracefully...')
      await disconnectRedis()
      await app.close()
      process.exit(0)
    })
  } catch (err) {
    console.error('Failed to start server:', err)
    process.exit(1)
  }
}

start()
