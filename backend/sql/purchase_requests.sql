-- Purchase Requests table (run in Supabase SQL editor)
create type request_status as enum ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');

create table if not exists purchase_requests (
    id uuid primary key default gen_random_uuid(),
    family_id uuid not null references families(id) on delete cascade,
    requester_id uuid not null references users(id) on delete cascade,
    title text not null,
    description text,
    url text,
    image_url text,
    price_cents integer not null,
    status request_status not null default 'PENDING',
    created_at timestamp with time zone default now(),
    decided_at timestamp with time zone,
    decided_by uuid references users(id)
);

create index if not exists idx_purchase_requests_family on purchase_requests(family_id);
create index if not exists idx_purchase_requests_requester on purchase_requests(requester_id);
