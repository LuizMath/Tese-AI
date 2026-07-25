-- =============================================================
-- Tese AI — Migração 5/6: Índices
-- Consultas do painel + busca de nomes sem acento (trigram).
-- =============================================================

-- Caminhos de consulta do painel e do job de agregação
create index idx_decisao_magistrado_demanda
  on public.decisao (magistrado_id, tipo_demanda_id, data_decisao desc);
create index idx_decisao_tipo_demanda
  on public.decisao (tipo_demanda_id, data_decisao desc);
create index idx_decisao_numero_cnj
  on public.decisao (numero_cnj);

create index idx_padrao_magistrado
  on public.padrao_magistrado_demanda (magistrado_id);
create index idx_padrao_tipo_demanda
  on public.padrao_magistrado_demanda (tipo_demanda_id);

-- Busca "juiz por nome" tolerante a acento e erro de digitação
create index idx_magistrado_nome_trgm
  on public.magistrado
  using gin (public.sem_acento(nome) extensions.gin_trgm_ops);
create index idx_vara_nome_trgm
  on public.vara
  using gin (public.sem_acento(nome) extensions.gin_trgm_ops);

-- Fila do job noturno: só o que ainda não foi processado
create index idx_bruta_pendente
  on ingestao.decisao_bruta (coletado_em)
  where processado_em is null;

create index idx_processo_usuario_perfil
  on public.processo_usuario (perfil_id);
