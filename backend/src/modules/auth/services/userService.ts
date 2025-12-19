import { supabaseDb } from '../../../config/supabase.js'
import type { User as SupabaseAuthUser } from '@supabase/supabase-js'
import type { DbUser } from '../types.js'

export async function fetchUserRecord(userId: string): Promise<DbUser | null> {
  const existing = await supabaseDb
    .from('users')
    .select('id, family_id, username, email, role, current_credit_score')
    .eq('id', userId)
    .maybeSingle()

  if (existing.error) {
    throw new Error(`Failed to fetch user: ${existing.error.message}`)
  }

  return (existing.data as DbUser | null) ?? null
}

export async function fetchFamilyMembers(familyId: string): Promise<DbUser[]> {
  const result = await supabaseDb
    .from('users')
    .select('id, family_id, username, email, role, current_credit_score')
    .eq('family_id', familyId)
    .eq('role', 'CHILD') // only children in the family overview

  if (result.error) {
    throw new Error(`Failed to fetch family members: ${result.error.message}`)
  }

  return (result.data as DbUser[]) ?? []
}

export async function createFamily(name: string): Promise<string> {
  const insert = await supabaseDb
    .from('families')
    .insert({ name })
    .select('id')
    .single()

  if (insert.error || !insert.data) {
    throw new Error(`Failed to create family: ${insert.error?.message}`)
  }

  return insert.data.id
}

export async function createParentUser(authUser: SupabaseAuthUser, username: string, familyName: string): Promise<DbUser> {
  const familyId = await createFamily(familyName)

  const insert = await supabaseDb
    .from('users')
    .insert({
      id: authUser.id,
      family_id: familyId,
      username,
      email: authUser.email,
      password_hash: 'EXTERNAL',
      role: 'PARENT',
      current_credit_score: 300
    })
    .select('id, family_id, username, email, role, current_credit_score')
    .single()

  if (insert.error || !insert.data) {
    throw new Error(`Failed to create user: ${insert.error?.message}`)
  }

  return insert.data as DbUser
}

export async function createChildUser(authUser: SupabaseAuthUser, username: string, familyId: string): Promise<DbUser> {
  // ensure family exists
  const familyExists = await supabaseDb
    .from('families')
    .select('id')
    .eq('id', familyId)
    .maybeSingle()

  if (familyExists.error || !familyExists.data) {
    throw new Error('Family not found')
  }

  const insert = await supabaseDb
    .from('users')
    .insert({
      id: authUser.id,
      family_id: familyId,
      username,
      email: authUser.email,
      password_hash: 'EXTERNAL',
      role: 'CHILD',
      current_credit_score: 300
    })
    .select('id, family_id, username, email, role, current_credit_score')
    .single()

  if (insert.error || !insert.data) {
    throw new Error(`Failed to create user: ${insert.error?.message}`)
  }

  return insert.data as DbUser
}
