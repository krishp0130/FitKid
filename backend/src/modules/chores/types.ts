export type DbChore = {
  id: string
  assignee_id: string
  title: string
  description: string | null
  reward_value_cents: number
  status: string
  due_date: string | null
  assignee_username?: string
  recurrence_type?: string | null
  recurrence_config?: string | null
  parent_chore_id?: string | null
}

export type ChoreStatus = 'ASSIGNED' | 'PENDING_APPROVAL' | 'COMPLETED' | 'REJECTED'

export type ChoreRecurrenceType = 'NONE' | 'DAILY' | 'WEEKLY' | 'MONTHLY'

export type ChorePreset = {
  id: string
  title: string
  description: string
  rewardDollars: number
  recurrenceType: ChoreRecurrenceType
  suggestedDueDay?: number // Day of week (0-6) for weekly
}
