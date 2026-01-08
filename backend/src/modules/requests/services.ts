import { supabaseDb } from '../../config/supabase.js'
import type { PurchaseRequestRecord, RequestStatus, PurchaseRequestView } from './types.js'

interface CreateRequestInput {
  familyId: string
  requesterId: string
  requesterName?: string | null
  title: string
  description?: string | null
  url?: string | null
  imageUrl?: string | null
  priceDollars: number
  paymentMethod?: string | null
  cardId?: string | null
  cardName?: string | null
}

export async function createPurchaseRequest(input: CreateRequestInput): Promise<PurchaseRequestRecord> {
  const price_cents = Math.round(input.priceDollars * 100)
  const payload = {
    family_id: input.familyId,
    requester_id: input.requesterId,
    title: input.title,
    description: input.description ?? null,
    url: input.url ?? null,
    image_url: input.imageUrl ?? null,
    price_cents,
    status: 'PENDING' as RequestStatus,
    payment_method: input.paymentMethod ?? null,
    card_id: input.cardId ?? null,
    card_name: input.cardName ?? null
  }

  const { data, error } = await supabaseDb
    .from('purchase_requests')
    .insert(payload)
    .select('*, requester:requester_id(username)')
    .single()

  if (error || !data) {
    throw new Error(`Failed to create request: ${error?.message ?? 'unknown error'}`)
  }

  return mapRecord(data)
}

export async function fetchRequestsForUser(userId: string, role: 'PARENT' | 'CHILD', familyId?: string | null) {
  const query = supabaseDb
    .from('purchase_requests')
    .select('*, requester:requester_id(username)')
    .order('created_at', { ascending: false })

  if (role === 'PARENT') {
    if (!familyId) return []
    query.eq('family_id', familyId)
  } else {
    query.eq('requester_id', userId)
  }

  const { data, error } = await query
  if (error || !data) {
    throw new Error(`Failed to fetch requests: ${error?.message ?? 'unknown error'}`)
  }

  return data.map(mapRecord)
}

export async function updateRequestStatus(
  requestId: string,
  status: RequestStatus,
  decidedBy: string
): Promise<PurchaseRequestRecord | null> {
  const { data, error } = await supabaseDb
    .from('purchase_requests')
    .update({
      status,
      decided_by: decidedBy,
      decided_at: new Date().toISOString()
    })
    .eq('id', requestId)
    .select('*, requester:requester_id(username)')
    .single()

  if (error) {
    throw new Error(`Failed to update request: ${error.message}`)
  }

  return data ? mapRecord(data) : null
}

export async function fetchRequestById(id: string): Promise<PurchaseRequestRecord | null> {
  const { data, error } = await supabaseDb
    .from('purchase_requests')
    .select('*, requester:requester_id(username)')
    .eq('id', id)
    .single()

  if (error) return null
  return data ? mapRecord(data) : null
}

export function mapRecord(record: any): PurchaseRequestRecord {
  return {
    id: record.id,
    family_id: record.family_id,
    requester_id: record.requester_id,
    requester_name: record.requester?.username ?? null,
    title: record.title,
    description: record.description,
    url: record.url,
    image_url: record.image_url,
    price_cents: record.price_cents,
    payment_method: record.payment_method ?? null,
    card_id: record.card_id ?? null,
    card_name: record.card_name ?? null,
    status: record.status,
    created_at: record.created_at,
    decided_at: record.decided_at ?? null,
    decided_by: record.decided_by ?? null
  }
}

export function toView(record: PurchaseRequestRecord): PurchaseRequestView {
  return {
    id: record.id,
    title: record.title,
    description: record.description,
    url: record.url,
    imageUrl: record.image_url,
    price: record.price_cents / 100,
    priceCents: record.price_cents,
    paymentMethod: record.payment_method ?? null,
    cardId: record.card_id ?? null,
    cardName: record.card_name ?? null,
    status: record.status,
    requesterId: record.requester_id,
    requesterName: record.requester_name,
    createdAt: record.created_at,
    decidedAt: record.decided_at
  }
}
