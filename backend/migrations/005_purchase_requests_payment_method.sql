alter table purchase_requests
  add column if not exists payment_method text,
  add column if not exists card_id uuid,
  add column if not exists card_name text;

create index if not exists idx_purchase_requests_card_id on purchase_requests(card_id);

