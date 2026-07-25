-- =============================================================
-- Tese AI — Migração 3/6: Fatos e agregados
-- decisao (particionada por ano), padrao_magistrado_demanda
-- (a tabela que o painel lê) e ingestao.decisao_bruta.
-- =============================================================

create type public.resultado_decisao as enum (
  'procedente',
  'parcialmente_procedente',
  'improcedente',
  'acordo',
  'extinto_sem_merito',
  'outro'
);

-- Fatos normalizados, append-only, particionados por data da decisão.
-- O inteiro teor NÃO fica aqui: só a referência ao bucket 'inteiro-teor'.
create table public.decisao (
  id bigint generated always as identity,
  numero_cnj text not null,
  data_decisao date not null,
  tribunal_id smallint not null references public.tribunal (id),
  vara_id bigint references public.vara (id),
  magistrado_id bigint references public.magistrado (id),
  tipo_demanda_id bigint references public.tipo_demanda (id),
  resultado public.resultado_decisao not null default 'outro',
  valor_condenacao numeric(14, 2),
  tempo_tramitacao_dias integer,
  segredo_justica boolean not null default false,
  inteiro_teor_path text,
  fonte text,
  metadados jsonb not null default '{}'::jsonb,
  criado_em timestamptz not null default now(),
  primary key (id, data_decisao)
) partition by range (data_decisao);

create table public.decisao_2020 partition of public.decisao for values from ('2020-01-01') to ('2021-01-01');
create table public.decisao_2021 partition of public.decisao for values from ('2021-01-01') to ('2022-01-01');
create table public.decisao_2022 partition of public.decisao for values from ('2022-01-01') to ('2023-01-01');
create table public.decisao_2023 partition of public.decisao for values from ('2023-01-01') to ('2024-01-01');
create table public.decisao_2024 partition of public.decisao for values from ('2024-01-01') to ('2025-01-01');
create table public.decisao_2025 partition of public.decisao for values from ('2025-01-01') to ('2026-01-01');
create table public.decisao_2026 partition of public.decisao for values from ('2026-01-01') to ('2027-01-01');
create table public.decisao_2027 partition of public.decisao for values from ('2027-01-01') to ('2028-01-01');
create table public.decisao_default partition of public.decisao default;

-- Pré-agregação: 1 linha por juiz × tipo de demanda × janela de tempo.
-- É ISTO que o painel consulta — resposta em milissegundos
-- independente do tamanho do acervo. Recalculada pelo job noturno.
create table public.padrao_magistrado_demanda (
  id bigint generated always as identity primary key,
  magistrado_id bigint not null references public.magistrado (id),
  tipo_demanda_id bigint not null references public.tipo_demanda (id),
  janela text not null check (janela in ('12m', '24m', 'historico')),
  periodo_inicio date not null,
  periodo_fim date not null,
  total_decisoes integer not null,
  taxa_procedencia numeric(5, 4),
  taxa_parcial numeric(5, 4),
  taxa_improcedencia numeric(5, 4),
  taxa_acordo numeric(5, 4),
  tempo_medio_dias integer,
  valor_medio_condenacao numeric(14, 2),
  atualizado_em timestamptz not null default now(),
  unique (magistrado_id, tipo_demanda_id, janela)
);

-- Dados crus da coleta (DataJud/tribunais). Payload integral em JSONB;
-- processado_em marca o que o job noturno já normalizou.
create table ingestao.decisao_bruta (
  id bigint generated always as identity primary key,
  fonte text not null,
  id_externo text not null,
  payload jsonb not null,
  coletado_em timestamptz not null default now(),
  processado_em timestamptz,
  erro text,
  unique (fonte, id_externo)
);

alter table public.decisao enable row level security;
alter table public.padrao_magistrado_demanda enable row level security;
alter table ingestao.decisao_bruta enable row level security;

-- Decisões em segredo de justiça nunca saem pela API.
create policy "leitura publica autenticada" on public.decisao
  for select to authenticated using (not segredo_justica);

create policy "leitura autenticada" on public.padrao_magistrado_demanda
  for select to authenticated using (true);

-- ingestao.decisao_bruta: nenhuma política = acesso só via service role.
