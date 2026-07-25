-- =============================================================
-- Tese AI — Migração 4/6: Usuários, planos e RLS
-- perfil (ligado a auth.users), áreas ativas, processos importados
-- e uso mensal. Isolamento por usuário como política no banco.
-- =============================================================

create table public.plano (
  id smallint generated always as identity primary key,
  slug text not null unique,
  nome text not null,
  preco_mensal_centavos integer not null default 0,
  limite_processos integer,
  limite_consultas_assistente integer,
  max_areas smallint
);

create table public.perfil (
  id uuid primary key references auth.users (id) on delete cascade,
  nome text,
  email text,
  oab text,
  plano_id smallint references public.plano (id),
  criado_em timestamptz not null default now()
);

-- Áreas do direito ativas na conta (seleção de área do painel)
create table public.perfil_area (
  perfil_id uuid not null references public.perfil (id) on delete cascade,
  area_id smallint not null references public.area (id),
  primary key (perfil_id, area_id)
);

-- Processos importados por CNJ. Privados por dono:
-- "processos do escritório nunca entram na base pública".
create table public.processo_usuario (
  id bigint generated always as identity primary key,
  perfil_id uuid not null references public.perfil (id) on delete cascade,
  numero_cnj text not null,
  apelido text,
  tribunal_id smallint references public.tribunal (id),
  area_id smallint references public.area (id),
  magistrado_id bigint references public.magistrado (id),
  vara_id bigint references public.vara (id),
  fase text,
  dados jsonb not null default '{}'::jsonb,
  criado_em timestamptz not null default now(),
  unique (perfil_id, numero_cnj)
);

-- Consumo do plano por mês (tela plano/conta — GET /api/conta/uso)
create table public.uso_mensal (
  id bigint generated always as identity primary key,
  perfil_id uuid not null references public.perfil (id) on delete cascade,
  mes date not null,
  consultas_assistente integer not null default 0,
  processos_importados integer not null default 0,
  pesquisas_padroes integer not null default 0,
  unique (perfil_id, mes)
);

-- Perfil criado automaticamente quando o Supabase Auth registra o usuário
create or replace function public.criar_perfil_no_signup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.perfil (id, nome, email, plano_id)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nome', split_part(new.email, '@', 1)),
    new.email,
    (select id from public.plano where slug = 'basico')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger criar_perfil_apos_signup
  after insert on auth.users
  for each row execute function public.criar_perfil_no_signup();

alter table public.plano enable row level security;
alter table public.perfil enable row level security;
alter table public.perfil_area enable row level security;
alter table public.processo_usuario enable row level security;
alter table public.uso_mensal enable row level security;

-- Planos aparecem na página pública de criar conta
create policy "leitura publica" on public.plano
  for select to anon, authenticated using (true);

create policy "ver o proprio perfil" on public.perfil
  for select to authenticated using (id = (select auth.uid()));
create policy "editar o proprio perfil" on public.perfil
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "gerir as proprias areas" on public.perfil_area
  for all to authenticated
  using (perfil_id = (select auth.uid()))
  with check (perfil_id = (select auth.uid()));

create policy "gerir os proprios processos" on public.processo_usuario
  for all to authenticated
  using (perfil_id = (select auth.uid()))
  with check (perfil_id = (select auth.uid()));

-- Uso: o cliente só lê; quem incrementa é o backend (service role)
create policy "ver o proprio uso" on public.uso_mensal
  for select to authenticated using (perfil_id = (select auth.uid()));
