export type RequestStatus = 'PENDING' | 'APPROVED' | 'REJECTED' | 'CANCELLED'

export interface PurchaseRequestRecord {
  id: string
  family_id: string
  requester_id: string
  requester_name?: string | null
  title: string
  description: string | null
  url: string | null
  image_url: string | null
  price_cents: number
  payment_method?: string | null
  card_id?: string | null
  card_name?: string | null
  status: RequestStatus
  created_at: string
  decided_at: string | null
  decided_by: string | null
}

export interface PurchaseRequestView {
  id: string
  title: string
  description: string | null
  url: string | null
  imageUrl: string | null
  price: number // dollars for the client
  priceCents: number
  paymentMethod?: string | null
  cardId?: string | null
  cardName?: string | null
  status: RequestStatus
  requesterId: string
  requesterName?: string | null
  createdAt: string
  decidedAt?: string | null
}
