-- Allowances table for recurring/one-off parent allowances
create table if not exists allowances (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null,
  family_id text,
  amount_cents integer not null,
  frequency text not null check (frequency in ('WEEKLY','MONTHLY','CUSTOM')),
  custom_interval_days integer,
  created_at timestamptz not null default now()
);

create index if not exists idx_allowances_child on allowances(child_id);
create index if not exists idx_allowances_family on allowances(family_id);

