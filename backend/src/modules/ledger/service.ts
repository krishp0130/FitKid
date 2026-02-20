import { supabaseDb } from '../../config/supabase.js'

type AccountRow = {
  id: string
  name: string
  type: string
}

async function ensureAccount(userId: string, name: string, type: 'ASSET' | 'REVENUE'): Promise<string> {
  const { data, error } = await supabaseDb
    .from('ledger_accounts')
    .select('id')
    .eq('user_id', userId)
    .eq('name', name)
    .eq('type', type)
    .order('created_at', { ascending: true })

  if (error) throw new Error(error.message)
  if (data && data.length > 0 && data[0]?.id) return data[0].id

  const insert = await supabaseDb
    .from('ledger_accounts')
    .insert({ user_id: userId, name, type })
    .select('id')
    .single()
  if (insert.error || !insert.data) throw new Error(insert.error?.message ?? 'Failed to create account')
  return insert.data.id
}

export async function ensureWalletAndIncomeAccounts(userId: string) {
  const walletId = await ensureAccount(userId, 'Wallet', 'ASSET')
  const incomeId = await ensureAccount(userId, 'Chores Income', 'REVENUE')
  return { walletId, incomeId }
}

export async function createTransactionWithPostings(params: {
  description: string
  postings: { account_id: string; amount: number }[] // amount in cents, + debit, - credit
  metadata?: any
}) {
  const { description, postings, metadata } = params
  const { data: tx, error: txErr } = await supabaseDb
    .from('transactions')
    .insert({
      description,
      status: 'CLEARED',
      metadata: metadata ?? null
    })
    .select('id')
    .single()

  if (txErr || !tx) throw new Error(txErr?.message ?? 'Failed to create transaction')

  const postingsRows = postings.map(p => ({
    transaction_id: tx.id,
    account_id: p.account_id,
    amount: p.amount
  }))

  const { error: postErr } = await supabaseDb.from('postings').insert(postingsRows)
  if (postErr) throw new Error(postErr.message)

  return tx.id as string
}

export async function getWalletBalanceCents(userId: string): Promise<number> {
  // ensure wallet exists
  const { walletId } = await ensureWalletAndIncomeAccounts(userId)
  const { data, error } = await supabaseDb
    .from('postings')
    .select('amount')
    .eq('account_id', walletId)

  if (error) throw new Error(error.message)
  return (data ?? []).reduce((sum, row: any) => sum + Number(row.amount ?? 0), 0)
}
