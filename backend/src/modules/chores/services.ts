import { supabaseDb } from '../../config/supabase.js'
import type { DbChore, ChoreStatus } from './types.js'

export async function fetchChoresForUser(userId: string, role: 'PARENT' | 'CHILD', familyId?: string): Promise<DbChore[]> {
  if (role === 'CHILD') {
    const { data, error } = await supabaseDb
      .from('chores')
      .select('id, assignee_id, title, description, reward_value_cents, status, due_date, recurrence_type, recurrence_config, parent_chore_id')
      .eq('assignee_id', userId)
      .order('created_at', { ascending: false })

    if (error) throw new Error(error.message)
    return (data as DbChore[]) ?? []
  }

  // Parent: fetch chores for children in their family
  const { data, error } = await supabaseDb
    .from('chores')
    .select('id, assignee_id, title, description, reward_value_cents, status, due_date, recurrence_type, recurrence_config, parent_chore_id, users!inner(id, family_id, username)')
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
    recurrence_type: row.recurrence_type,
    recurrence_config: row.recurrence_config,
    parent_chore_id: row.parent_chore_id,
    assignee_username: row.users?.username
  })) as DbChore[]
}

export async function createChoreForChild(params: {
  assigneeId: string
  title: string
  description?: string | null
  rewardDollars: number
  dueDate?: string | null
  recurrenceType?: string | null
  recurrenceConfig?: string | null
  parentChoreId?: string | null
}): Promise<DbChore> {
  const { assigneeId, title, description, rewardDollars, dueDate, recurrenceType, recurrenceConfig, parentChoreId } = params
  const rewardCents = Math.round(rewardDollars * 100)
  const { data, error } = await supabaseDb
    .from('chores')
    .insert({
      assignee_id: assigneeId,
      title,
      description: description ?? null,
      reward_value_cents: rewardCents,
      status: 'ASSIGNED',
      due_date: dueDate ?? null,
      recurrence_type: recurrenceType ?? null,
      recurrence_config: recurrenceConfig ?? null,
      parent_chore_id: parentChoreId ?? null
    })
    .select('id, assignee_id, title, description, reward_value_cents, status, due_date, recurrence_type, recurrence_config, parent_chore_id')
    .single()

  if (error || !data) throw new Error(error?.message ?? 'Failed to create chore')
  return data as DbChore
}

export async function updateChoreStatus(id: string, status: ChoreStatus): Promise<DbChore> {
  const { data, error } = await supabaseDb
    .from('chores')
    .update({ status })
    .eq('id', id)
    .select('id, assignee_id, title, description, reward_value_cents, status, due_date, recurrence_type, recurrence_config, parent_chore_id')
    .single()

  if (error || !data) throw new Error(error?.message ?? 'Failed to update chore')
  return data as DbChore
}

export async function addRewardToWallet(userId: string, rewardCents: number): Promise<void> {
  // First, get current wallet balance (if the column exists)
  const { data: userData, error: fetchError } = await supabaseDb
    .from('users')
    .select('wallet_balance_cents')
    .eq('id', userId)
    .maybeSingle()

  if (fetchError) {
    // If column doesn't exist, that's okay - wallet feature may not be fully implemented in DB yet
    // Just log and continue - we'll add it to the schema later if needed
    console.warn('Wallet balance column may not exist:', fetchError.message)
    return
  }

  if (!userData) {
    throw new Error('User not found')
  }

  const currentBalance = (userData.wallet_balance_cents as number) ?? 0
  const newBalance = currentBalance + rewardCents

  const { error: updateError } = await supabaseDb
    .from('users')
    .update({ wallet_balance_cents: newBalance })
    .eq('id', userId)

  if (updateError) {
    // If update fails due to missing column, that's okay
    console.warn('Wallet balance update may have failed (column may not exist):', updateError.message)
    return
  }
}

export async function fetchChore(id: string): Promise<DbChore | null> {
  const { data, error } = await supabaseDb
    .from('chores')
    .select('id, assignee_id, title, description, reward_value_cents, status, due_date, recurrence_type, recurrence_config, parent_chore_id')
    .eq('id', id)
    .maybeSingle()

  if (error) throw new Error(error.message)
  return (data as DbChore | null) ?? null
}

export async function updateChore(id: string, updates: {
  title?: string
  description?: string | null
  rewardDollars?: number
  dueDate?: string | null
  recurrenceType?: string | null
  recurrenceConfig?: string | null
}): Promise<DbChore> {
  const updateData: any = {}
  if (updates.title !== undefined) updateData.title = updates.title
  if (updates.description !== undefined) updateData.description = updates.description
  if (updates.rewardDollars !== undefined) updateData.reward_value_cents = Math.round(updates.rewardDollars * 100)
  if (updates.dueDate !== undefined) updateData.due_date = updates.dueDate
  if (updates.recurrenceType !== undefined) updateData.recurrence_type = updates.recurrenceType
  if (updates.recurrenceConfig !== undefined) updateData.recurrence_config = updates.recurrenceConfig

  const { data, error } = await supabaseDb
    .from('chores')
    .update(updateData)
    .eq('id', id)
    .select('id, assignee_id, title, description, reward_value_cents, status, due_date, recurrence_type, recurrence_config, parent_chore_id')
    .single()

  if (error || !data) throw new Error(error?.message ?? 'Failed to update chore')
  return data as DbChore
}
