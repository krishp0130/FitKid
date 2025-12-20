import { supabaseDb } from '../../config/supabase.js'
import type { DbChore, ChoreStatus } from './types.js'

export async function fetchChoresForUser(userId: string, role: 'PARENT' | 'CHILD', familyId?: string): Promise<DbChore[]> {
  if (role === 'CHILD') {
    // Select core columns first, then conditionally add new columns if they exist
    // For now, select all columns - if they don't exist, Supabase will return null
    const { data, error } = await supabaseDb
      .from('chores')
      .select('id, assignee_id, title, description, reward_value_cents, status, due_date')
      .eq('assignee_id', userId)
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error fetching chores for child:', error)
      throw new Error(`Database error: ${error.message} (code: ${error.code})`)
    }
    
    // Map data and add null values for optional columns if they don't exist
    return ((data as any[]) ?? []).map((row) => ({
      ...row,
      recurrence_type: row.recurrence_type ?? null,
      recurrence_config: row.recurrence_config ?? null,
      parent_chore_id: row.parent_chore_id ?? null
    })) as DbChore[]
  }

  // Parent: fetch chores for children in their family
  // Select core columns only (new columns will be added via migration)
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
    recurrence_type: row.recurrence_type ?? null,
    recurrence_config: row.recurrence_config ?? null,
    parent_chore_id: row.parent_chore_id ?? null,
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
      due_date: dueDate ?? null
      // Note: recurrence_type, recurrence_config, parent_chore_id columns don't exist yet
      // They will be added via migration. For now, insert without them.
    })
      .select('id, assignee_id, title, description, reward_value_cents, status, due_date')
      .single()

    if (error || !data) throw new Error(error?.message ?? 'Failed to create chore')
    // Add null values for optional columns that don't exist in DB yet
    return {
      ...data,
      recurrence_type: null,
      recurrence_config: null,
      parent_chore_id: null
    } as DbChore
}

export async function updateChoreStatus(id: string, status: ChoreStatus): Promise<DbChore> {
  const { data, error } = await supabaseDb
    .from('chores')
    .update({ status })
    .eq('id', id)
      .select('id, assignee_id, title, description, reward_value_cents, status, due_date')
      .single()

    if (error || !data) throw new Error(error?.message ?? 'Failed to update chore')
    // Add null values for optional columns that don't exist in DB yet
    return {
      ...data,
      recurrence_type: null,
      recurrence_config: null,
      parent_chore_id: null
    } as DbChore
}

export async function addRewardToWallet(userId: string, rewardCents: number): Promise<void> {
  // Try to update wallet balance using ledger_accounts system
  // First, find or create a "Wallet" account for this user
  const { data: walletAccount, error: accountError } = await supabaseDb
    .from('ledger_accounts')
    .select('id')
    .eq('user_id', userId)
    .eq('name', 'Wallet')
    .eq('type', 'ASSET')
    .maybeSingle()

  if (accountError) {
    console.error('Error finding wallet account:', accountError.message)
    throw new Error(`Failed to find wallet account: ${accountError.message}`)
  }

  let walletAccountId: string

  if (!walletAccount) {
    // Create wallet account if it doesn't exist
    const { data: newAccount, error: createError } = await supabaseDb
      .from('ledger_accounts')
      .insert({
        user_id: userId,
        name: 'Wallet',
        type: 'ASSET'
      })
      .select('id')
      .single()

    if (createError || !newAccount) {
      console.error('Error creating wallet account:', createError?.message)
      throw new Error(`Failed to create wallet account: ${createError?.message}`)
    }

    walletAccountId = newAccount.id
  } else {
    walletAccountId = walletAccount.id
  }

  // Create a transaction for the reward
  const { data: transaction, error: txError } = await supabaseDb
    .from('transactions')
    .insert({
      description: `Chore reward: ${rewardCents / 100} dollars`,
      status: 'CLEARED',
      metadata: { source: 'chore_reward' }
    })
    .select('id')
    .single()

  if (txError || !transaction) {
    console.error('Error creating reward transaction:', txError?.message)
    throw new Error(`Failed to create transaction: ${txError?.message}`)
  }

  // Create posting to credit the wallet (positive amount = debit to asset account)
  const { error: postingError } = await supabaseDb
    .from('postings')
    .insert({
      transaction_id: transaction.id,
      account_id: walletAccountId,
      amount: rewardCents // Positive amount = debit to asset = increase balance
    })

  if (postingError) {
    console.error('Error creating wallet posting:', postingError.message)
    throw new Error(`Failed to credit wallet: ${postingError.message}`)
  }

  console.log(`Successfully added ${rewardCents} cents ($${(rewardCents / 100).toFixed(2)}) to wallet for user ${userId}`)
}

export async function fetchChore(id: string): Promise<DbChore | null> {
  const { data, error } = await supabaseDb
    .from('chores')
    .select('id, assignee_id, title, description, reward_value_cents, status, due_date')
    .eq('id', id)
    .maybeSingle()

  if (error) throw new Error(error.message)
  if (!data) return null
  // Add null values for optional columns that may not exist in DB yet
  return {
    ...data,
    recurrence_type: null,
    recurrence_config: null,
    parent_chore_id: null
  } as DbChore
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
  // Note: recurrence_type and recurrence_config columns don't exist yet
  // They will be added via migration. For now, skip updating them.

  const { data, error } = await supabaseDb
    .from('chores')
    .update(updateData)
    .eq('id', id)
      .select('id, assignee_id, title, description, reward_value_cents, status, due_date')
      .single()

    if (error || !data) throw new Error(error?.message ?? 'Failed to update chore')
    // Add null values for optional columns that don't exist in DB yet
    return {
      ...data,
      recurrence_type: null,
      recurrence_config: null,
      parent_chore_id: null
    } as DbChore
}
