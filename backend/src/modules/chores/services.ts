import { supabaseDb } from '../../config/supabase.js'
import type { DbChore, ChoreStatus } from './types.js'

export async function fetchChoresForUser(userId: string, role: 'PARENT' | 'CHILD', familyId?: string): Promise<DbChore[]> {
  if (role === 'CHILD') {
    const { data, error } = await supabaseDb
      .from('chores')
      .select('id, assignee_id, title, description, reward_value_cents, status, due_date')
      .eq('assignee_id', userId)
      .order('created_at', { ascending: false })

    if (error) throw new Error(error.message)
    return (data as DbChore[]) ?? []
  }

  // Parent: fetch chores for children in their family
  const { data, error } = await supabaseDb
    .from('chores')
    .select('id, assignee_id, title, description, reward_value_cents, status, due_date, users!inner(id, family_id, username)')
    .eq('users.family_id', familyId ?? '')
    .order('created_at', { ascending: false })

  if (error) throw new Error(error.message)

  return (data as any[]).map(row => ({
    id: row.id,
    assignee_id: row.assignee_id,
    title: row.title,
    description: row.description,
    reward_value_cents: row.reward_value_cents,
    status: row.status,
    due_date: row.due_date,
    assignee_username: row.users?.username
  })) as DbChore[]
}

export async function createChoreForChild(params: {
  assigneeId: string
  title: string
  description?: string | null
  rewardDollars: number
  dueDate?: string | null
}): Promise<DbChore> {
  const { assigneeId, title, description, rewardDollars, dueDate } = params
  const rewardCents = Math.round(rewardDollars * 100)
  const { data, error } = await supabaseDb
    .from('chores')
    .insert({
      assignee_id: assigneeId,
      title,
      description: description ?? null,
      reward_value_cents: rewardCents,
      status: 'ASSIGNED',
      due_date: dueDate ?? null
    })
    .select('id, assignee_id, title, description, reward_value_cents, status, due_date')
    .single()

  if (error || !data) throw new Error(error?.message ?? 'Failed to create chore')
  return data as DbChore
}

export async function updateChoreStatus(id: string, status: ChoreStatus): Promise<DbChore> {
  const { data, error } = await supabaseDb
    .from('chores')
    .update({ status })
    .eq('id', id)
    .select('id, assignee_id, title, description, reward_value_cents, status, due_date')
    .single()

  if (error || !data) throw new Error(error?.message ?? 'Failed to update chore')
  return data as DbChore
}

export async function fetchChore(id: string): Promise<DbChore | null> {
  const { data, error } = await supabaseDb
    .from('chores')
    .select('id, assignee_id, title, description, reward_value_cents, status, due_date')
    .eq('id', id)
    .maybeSingle()

  if (error) throw new Error(error.message)
  return (data as DbChore | null) ?? null
}
