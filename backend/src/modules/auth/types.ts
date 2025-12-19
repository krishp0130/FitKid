export type AuthStatus = 'EXISTING_USER' | 'NEEDS_ONBOARDING'

export type DbUser = {
  id: string
  family_id: string
  username: string
  email: string | null
  role: string
  current_credit_score: number
}
