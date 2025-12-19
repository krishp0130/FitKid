import type { User as SupabaseAuthUser } from '@supabase/supabase-js'
import { supabaseAuth } from '../../../config/supabase.js'

export async function getAuthUserFromBearer(request: any): Promise<SupabaseAuthUser | null> {
  const authHeader = request.headers.authorization as string | undefined
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null
  const token = authHeader.replace('Bearer ', '')
  const { data, error } = await supabaseAuth.auth.getUser(token)
  if (error || !data.user) return null
  return data.user
}
