-- =============================================================
-- Tese AI — Migração 1/6: Fundação
-- Extensões, schema de ingestão e bucket de storage.
-- =============================================================

-- Busca textual sem acento + similaridade (trigram)
create extension if not exists unaccent with schema extensions;
create extension if not exists pg_trgm with schema extensions;

-- Schema isolado para a coleta: NÃO é exposto pela API do Supabase.
-- O worker de ingestão grava aqui via service role; o painel nunca lê daqui.
create schema if not exists ingestao;

-- Versão imutável do unaccent, exigida para uso em índices
create or replace function public.sem_acento(txt text)
returns text
language sql
immutable
parallel safe
set search_path = ''
as $$
  select extensions.unaccent('extensions.unaccent'::regdictionary, txt)
$$;

-- Bucket privado para o inteiro teor das decisões.
-- O texto integral fica AQUI (object storage), não no Postgres —
-- no banco fica só a referência (coluna inteiro_teor_path).
insert into storage.buckets (id, name, public)
values ('inteiro-teor', 'inteiro-teor', false)
on conflict (id) do nothing;
