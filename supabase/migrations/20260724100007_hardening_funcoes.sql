-- =============================================================
-- Tese AI — Migração 7: Hardening (advisors de segurança)
-- Funções SECURITY DEFINER não devem ser chamáveis pela API REST.
-- Já aplicada no projeto em 2026-07-24 via MCP; mantida aqui para
-- reproduzir o ambiente do zero.
-- =============================================================

-- O trigger em auth.users continua funcionando: em disparo de trigger
-- o Postgres não reverifica EXECUTE em tempo de execução.
revoke execute on function public.criar_perfil_no_signup() from public, anon, authenticated;

-- rls_auto_enable() já existia no projeto (auto-habilita RLS em tabelas
-- novas). Condicional para não quebrar em ambientes que não a têm.
do $$
begin
  if exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = 'rls_auto_enable'
  ) then
    revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
  end if;
end;
$$;
