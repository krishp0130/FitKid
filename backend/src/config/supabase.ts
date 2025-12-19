import { createClient } from '@supabase/supabase-js'
import { env } from './env.js'

// Auth client for sign-in flows
export const supabaseAuth = createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

// DB client that never uses a user session token; always service role
export const supabaseDb = createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  },
  global: {
    headers: {
      Authorization: `Bearer ${env.supabaseServiceRoleKey}`
    }
  }
})
