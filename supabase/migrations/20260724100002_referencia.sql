-- =============================================================
-- Tese AI — Migração 2/6: Tabelas de referência
-- tribunal, area, tipo_demanda, magistrado, vara.
-- Escrita só via service role (worker de ingestão); leitura autenticada.
-- =============================================================

create table public.tribunal (
  id smallint generated always as identity primary key,
  sigla text not null unique,
  nome text not null,
  uf char(2),
  esfera text not null default 'estadual'
    check (esfera in ('estadual', 'federal', 'trabalhista', 'superior')),
  criado_em timestamptz not null default now()
);

create table public.area (
  id smallint generated always as identity primary key,
  slug text not null unique,
  nome text not null
);

create table public.tipo_demanda (
  id bigint generated always as identity primary key,
  area_id smallint not null references public.area (id),
  slug text not null,
  nome text not null,
  unique (area_id, slug)
);

create table public.magistrado (
  id bigint generated always as identity primary key,
  nome text not null,
  tribunal_id smallint references public.tribunal (id),
  criado_em timestamptz not null default now()
);

create table public.vara (
  id bigint generated always as identity primary key,
  tribunal_id smallint not null references public.tribunal (id),
  comarca text,
  nome text not null
);

alter table public.tribunal enable row level security;
alter table public.area enable row level security;
alter table public.tipo_demanda enable row level security;
alter table public.magistrado enable row level security;
alter table public.vara enable row level security;

-- area é usada em páginas públicas (criar-conta); o resto exige login.
create policy "leitura publica" on public.area
  for select to anon, authenticated using (true);

create policy "leitura autenticada" on public.tribunal
  for select to authenticated using (true);
create policy "leitura autenticada" on public.tipo_demanda
  for select to authenticated using (true);
create policy "leitura autenticada" on public.magistrado
  for select to authenticated using (true);
create policy "leitura autenticada" on public.vara
  for select to authenticated using (true);
