-- =============================================================
-- Tese AI — Migração 6/6: Seed inicial
-- Planos, áreas (as 7 do painel), tribunais e tipos de demanda
-- para o recorte inicial (TJSP, cível/consumidor).
-- Sem IDs fixos: tudo referenciado por slug/sigla.
-- =============================================================

insert into public.plano (slug, nome, preco_mensal_centavos, limite_processos, limite_consultas_assistente, max_areas) values
  ('basico',        'Básico',        0, 10,  30, 1),   -- ajustar preços/limites quando o comercial fechar
  ('intermediario', 'Intermediário', 0, 50,  200, 3),
  ('avancado',      'Avançado',      0, null, null, null)
on conflict (slug) do nothing;

insert into public.area (slug, nome) values
  ('civel',          'Cível'),
  ('consumidor',     'Consumidor'),
  ('trabalhista',    'Trabalhista'),
  ('tributario',     'Tributário'),
  ('previdenciario', 'Previdenciário'),
  ('familia',        'Família'),
  ('empresarial',    'Empresarial')
on conflict (slug) do nothing;

insert into public.tribunal (sigla, nome, uf, esfera) values
  ('TJSP', 'Tribunal de Justiça de São Paulo',      'SP', 'estadual'),
  ('TJRJ', 'Tribunal de Justiça do Rio de Janeiro', 'RJ', 'estadual'),
  ('TJMG', 'Tribunal de Justiça de Minas Gerais',   'MG', 'estadual')
on conflict (sigla) do nothing;

insert into public.tipo_demanda (area_id, slug, nome)
select a.id, t.slug, t.nome
from (values
  ('consumidor', 'negativacao-indevida',       'Negativação indevida'),
  ('consumidor', 'cobranca-indevida',          'Cobrança indevida'),
  ('consumidor', 'vicio-produto',              'Vício do produto'),
  ('consumidor', 'plano-saude-negativa',       'Plano de saúde — negativa de cobertura'),
  ('consumidor', 'atraso-cancelamento-voo',    'Atraso ou cancelamento de voo'),
  ('consumidor', 'falha-servico-essencial',    'Falha em serviço essencial'),
  ('civel',      'danos-morais',               'Danos morais'),
  ('civel',      'acidente-transito',          'Acidente de trânsito'),
  ('civel',      'inadimplemento-contratual',  'Inadimplemento contratual'),
  ('civel',      'cobranca-condominial',       'Cobrança condominial'),
  ('civel',      'despejo',                    'Despejo'),
  ('civel',      'execucao-titulo',            'Execução de título extrajudicial')
) as t (area_slug, slug, nome)
join public.area a on a.slug = t.area_slug
on conflict (area_id, slug) do nothing;
