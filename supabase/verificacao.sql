-- =============================================================
-- Tese AI — Verificação pós-migração
-- Cole no SQL Editor do projeto e execute tudo de uma vez.
-- Cada linha do resultado deve bater com a coluna "esperado".
-- =============================================================

select 'extensoes (unaccent + pg_trgm)' as item,
       count(*)::text as valor, '2' as esperado
from pg_extension where extname in ('unaccent', 'pg_trgm')

union all
select 'tabelas no schema public',
       count(*)::text, '21'   -- 12 tabelas + 9 partições de decisao (ver nota abaixo)
from pg_tables where schemaname = 'public'

union all
select 'particoes de decisao (2020-2027 + default)',
       count(*)::text, '9'
from pg_inherits
where inhparent = 'public.decisao'::regclass

union all
select 'tabela de ingestao isolada',
       count(*)::text, '1'
from pg_tables where schemaname = 'ingestao' and tablename = 'decisao_bruta'

union all
select 'tabelas public SEM RLS (deve ser zero)',
       count(*)::text, '0'
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind in ('r', 'p') and not c.relrowsecurity

union all
select 'trigger de perfil no signup',
       count(*)::text, '1'
from pg_trigger where tgname = 'criar_perfil_apos_signup'

union all
select 'bucket inteiro-teor (privado)',
       count(*)::text, '1'
from storage.buckets where id = 'inteiro-teor' and not public

union all
select 'seed: areas', count(*)::text, '8' from public.area  -- 7 do seed + Penal (migração 8)
union all
select 'seed: planos', count(*)::text, '3' from public.plano
union all
select 'seed: tribunais', count(*)::text, '3' from public.tribunal
union all
select 'seed: tipos de demanda', count(*)::text, '12' from public.tipo_demanda;

-- Nota: "tabelas no schema public" = 12 tabelas de verdade + as 9 partições
-- de decisao, que também aparecem em pg_tables. Se você criar partições a
-- mais/menos, esse número muda junto — o que importa é a linha das
-- partições dar 9 e a linha "SEM RLS" dar 0.
