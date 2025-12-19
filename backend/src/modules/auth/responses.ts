import type { Session } from '@supabase/supabase-js'
import type { DbUser, AuthStatus } from './types.js'

export function mapUser(dbUser: DbUser | null, parentCode?: string) {
  if (!dbUser) return null
  return {
    id: dbUser.id,
    username: dbUser.username,
    email: dbUser.email,
    role: dbUser.role,
    familyId: dbUser.family_id,
    currentCreditScore: dbUser.current_credit_score,
    parentCode
  }
}

export function buildAuthResponse(
  status: AuthStatus,
  session: Session,
  dbUser: DbUser | null,
  parentCode?: string
) {
  return {
    accessToken: session.access_token,
    refreshToken: session.refresh_token,
    status,
    user: mapUser(dbUser, parentCode)
  }
}
