-- =============================================================
-- Tese AI — Migração 8: Trigger de perfil v2 + área Penal
-- Já aplicada no projeto em 2026-07-24 via MCP; mantida aqui para
-- reproduzir o ambiente do zero.
-- =============================================================

-- Área Penal existe nas telas do produto mas faltou no seed inicial
insert into public.area (slug, nome) values ('penal', 'Penal')
on conflict (slug) do nothing;

-- Trigger v2: aproveita os metadados enviados pelo formulário de cadastro
-- (nome, oab, plano escolhido e área principal) em vez de fixar o Básico.
create or replace function public.criar_perfil_no_signup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_plano_id smallint;
  v_area_id smallint;
begin
  select id into v_plano_id
  from public.plano where slug = new.raw_user_meta_data ->> 'plano';
  if v_plano_id is null then
    select id into v_plano_id from public.plano where slug = 'basico';
  end if;

  insert into public.perfil (id, nome, email, oab, plano_id)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nome', split_part(new.email, '@', 1)),
    new.email,
    nullif(new.raw_user_meta_data ->> 'oab', ''),
    v_plano_id
  )
  on conflict (id) do nothing;

  select id into v_area_id
  from public.area where nome = new.raw_user_meta_data ->> 'area';
  if v_area_id is not null then
    insert into public.perfil_area (perfil_id, area_id)
    values (new.id, v_area_id)
    on conflict do nothing;
  end if;

  return new;
end;
$$;
