# Redis Cache Layer

## Overview
The FitKid app now uses Redis as a caching layer to provide instant data access with zero delay when switching between tabs. All frequently accessed data (family members, chores, wallet balances) is cached for 30 seconds.

## Features
- **Instant Tab Switching**: No loading delays when navigating between parent tabs
- **Smart Cache Invalidation**: Cache automatically updates when data changes
- **Graceful Fallback**: If Redis is unavailable, the app works normally without caching
- **30-Second TTL**: Fresh data while minimizing database queries

## Setup Instructions

### 1. Install Redis
```bash
# macOS (via Homebrew)
brew install redis

# Start Redis server
brew services start redis

# Or run Redis manually
redis-server /opt/homebrew/etc/redis.conf
```

### 2. Configure Redis (Optional)
By default, Redis runs on `localhost:6379`. To use a different Redis instance, set the environment variable:

```bash
# backend/.env
REDIS_URL=redis://localhost:6379
```

### 3. Start the Backend
```bash
cd backend
npm install  # Installs redis npm package
npm run dev
```

You should see:
```
✅ Redis connected successfully
✅ Server listening at http://localhost:3000
```

## How It Works

### Cached Endpoints
1. **Family Members** (`GET /api/family/members`)
   - Cache key: `family:{familyId}:members`
   - TTL: 30 seconds

2. **Chores List** (`GET /api/chores`)
   - Cache key: `user:{userId}:chores`
   - TTL: 30 seconds

3. **Wallet Balance** (`GET /api/wallet`)
   - Cache key: `user:{userId}:wallet`
   - TTL: 30 seconds

### Cache Invalidation
The cache is automatically invalidated when:

- **Chore Created**: Invalidates parent & child chore caches
- **Chore Updated**: Invalidates parent & child chore caches
- **Chore Submitted**: Invalidates all chore caches
- **Chore Approved**: Invalidates parent & child chore caches + child wallet cache
- **Chore Rejected**: Invalidates parent & child chore caches
- **Child Onboards**: Invalidates family members cache

## Architecture

```
┌─────────────┐
│   Client    │
│  (SwiftUI)  │
└──────┬──────┘
       │
       │ HTTP Request
       ▼
┌─────────────┐
│   Backend   │
│  (Fastify)  │
└──────┬──────┘
       │
       │ Check Cache
       ▼
┌─────────────┐     Cache Miss      ┌──────────────┐
│    Redis    │ ─────────────────▶  │   Supabase   │
│   (Cache)   │ ◀─────────────────  │  (Database)  │
└─────────────┘     Store Result    └──────────────┘
```

## Performance Impact

### Before Redis Cache:
- Tab switch: 200-500ms (database query)
- Repeated requests: 200-500ms each

### After Redis Cache:
- First request: 200-500ms (database query + cache store)
- Cached requests: <10ms (memory read)
- Tab switch: **Instant** (< 10ms)

## Monitoring Cache

### Check Redis Connection
```bash
redis-cli PING
# Should return: PONG
```

### View Cached Keys
```bash
redis-cli KEYS "*"
```

### View Cache Contents
```bash
# View a specific key
redis-cli GET "user:123e4567-e89b-12d3-a456-426614174000:chores"

# View all keys matching a pattern
redis-cli KEYS "family:*"
```

### Clear All Cache
```bash
redis-cli FLUSHALL
```

## Code Structure

```
backend/
├── src/
│   ├── config/
│   │   └── redis.ts          # Redis connection setup
│   ├── services/
│   │   └── cacheService.ts   # Cache operations (get/set/delete)
│   ├── modules/
│   │   ├── auth/
│   │   │   └── controllers/
│   │   │       ├── familyController.ts    # ✓ Cached
│   │   │       └── onboardChildController.ts  # ✓ Invalidates
│   │   ├── chores/
│   │   │   └── controllers.ts  # ✓ Cached + Invalidates
│   │   └── ledger/
│   │       └── controller.ts   # ✓ Cached
│   └── server.ts               # Redis initialization
```

## Troubleshooting

### Redis Not Starting
```bash
# Check if Redis is running
brew services list | grep redis

# Restart Redis
brew services restart redis
```

### Backend Can't Connect to Redis
- Check `REDIS_URL` in `.env` (default: `redis://localhost:6379`)
- Verify Redis is running: `redis-cli PING`
- Check firewall settings

### Cache Not Invalidating
- Verify cache invalidation calls in controller methods
- Check Redis logs: `tail -f /opt/homebrew/var/log/redis.log`
- Manually clear cache: `redis-cli FLUSHALL`

## Development Notes

- Cache TTL is set to 30 seconds to balance freshness and performance
- All cache operations fail gracefully if Redis is unavailable
- Cache keys follow the pattern: `{entity}:{id}:{data_type}`
- The frontend's 2-second auto-refresh still works, but now uses cached data

## Future Enhancements

- [ ] Add cache metrics/monitoring dashboard
- [ ] Implement cache warming on server startup
- [ ] Add cache hit/miss logging
- [ ] Configure different TTLs per endpoint
- [ ] Add Redis Sentinel for high availability


