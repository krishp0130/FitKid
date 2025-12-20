export type DbChore = {
  id: string
  assignee_id: string
  title: string
  description: string | null
  reward_value_cents: number
  status: string
  due_date: string | null
  assignee_username?: string
}

export type ChoreStatus = 'ASSIGNED' | 'PENDING_APPROVAL' | 'COMPLETED' | 'REJECTED'
