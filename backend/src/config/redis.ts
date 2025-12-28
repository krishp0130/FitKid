import { createClient } from 'redis'

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379'

export const redisClient = createClient({
  url: redisUrl,
  socket: {
    reconnectStrategy: (retries) => {
      if (retries > 10) {
        console.error('Redis: Too many reconnection attempts, giving up')
        return new Error('Redis reconnection failed')
      }
      return Math.min(retries * 100, 3000)
    }
  }
})

redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err)
})

redisClient.on('connect', () => {
  console.log('✅ Redis connected successfully')
})

redisClient.on('reconnecting', () => {
  console.log('🔄 Redis reconnecting...')
})

export async function connectRedis() {
  try {
    await redisClient.connect()
  } catch (err) {
    console.error('Failed to connect to Redis:', err)
    console.warn('⚠️  Running without Redis cache layer')
  }
}

export async function disconnectRedis() {
  try {
    await redisClient.quit()
  } catch (err) {
    console.error('Error disconnecting from Redis:', err)
  }
}


