import { redisClient } from '../config/redis'

interface CacheOptions {
  ttl?: number // Time to live in seconds (default: 60)
}

class CacheService {
  private defaultTTL = 60 // 60 seconds default
  private isRedisAvailable = false

  constructor() {
    // Check Redis availability
    this.checkRedisConnection()
  }

  private async checkRedisConnection() {
    try {
      if (redisClient.isOpen) {
        this.isRedisAvailable = true
      }
    } catch {
      this.isRedisAvailable = false
    }
  }

  /**
   * Get a value from cache
   */
  async get<T>(key: string): Promise<T | null> {
    if (!this.isRedisAvailable) return null

    try {
      const value = await redisClient.get(key)
      if (!value) return null
      return JSON.parse(value) as T
    } catch (err) {
      console.error(`Cache get error for key ${key}:`, err)
      return null
    }
  }

  /**
   * Set a value in cache
   */
  async set(key: string, value: any, options?: CacheOptions): Promise<void> {
    if (!this.isRedisAvailable) return

    try {
      const ttl = options?.ttl || this.defaultTTL
      const serialized = JSON.stringify(value)
      await redisClient.setEx(key, ttl, serialized)
    } catch (err) {
      console.error(`Cache set error for key ${key}:`, err)
    }
  }

  /**
   * Delete a specific key
   */
  async delete(key: string): Promise<void> {
    if (!this.isRedisAvailable) return

    try {
      await redisClient.del(key)
    } catch (err) {
      console.error(`Cache delete error for key ${key}:`, err)
    }
  }

  /**
   * Delete all keys matching a pattern
   */
  async deletePattern(pattern: string): Promise<void> {
    if (!this.isRedisAvailable) return

    try {
      const keys = await redisClient.keys(pattern)
      if (keys.length > 0) {
        await redisClient.del(keys)
      }
    } catch (err) {
      console.error(`Cache deletePattern error for pattern ${pattern}:`, err)
    }
  }

  /**
   * Invalidate all cache for a user
   */
  async invalidateUser(userId: string): Promise<void> {
    await this.deletePattern(`user:${userId}:*`)
  }

  /**
   * Invalidate all cache for a family
   */
  async invalidateFamily(familyId: string): Promise<void> {
    await this.deletePattern(`family:${familyId}:*`)
  }

  /**
   * Cache keys generator
   */
  keys = {
    userProfile: (userId: string) => `user:${userId}:profile`,
    userChores: (userId: string) => `user:${userId}:chores`,
    userWallet: (userId: string) => `user:${userId}:wallet`,
    familyMembers: (familyId: string) => `family:${familyId}:members`,
    choreDetail: (choreId: string) => `chore:${choreId}:detail`,
    userRequests: (userId: string) => `user:${userId}:requests`,
    familyRequests: (familyId: string) => `family:${familyId}:requests`
  }

  /**
   * Enable Redis after connection
   */
  enable() {
    this.isRedisAvailable = true
  }

  /**
   * Disable Redis (fallback to no cache)
   */
  disable() {
    this.isRedisAvailable = false
  }
}

export const cacheService = new CacheService()
