# Banco de dados — Tese AI (Supabase)

As migrações em `migrations/` criam o banco completo descrito na proposta de
arquitetura: referência (tribunal, área, tipo de demanda, magistrado, vara),
fatos (`decisao` particionada por ano), a pré-agregação que o painel lê
(`padrao_magistrado_demanda`), o schema isolado de ingestão, contas de usuário
com RLS e o seed inicial (TJSP + cível/consumidor).

**Ordem importa** — aplicar na sequência numérica:

| # | Arquivo | O que faz |
|---|---------|-----------|
| 1 | `20260724100001_fundacao.sql` | Extensões `unaccent`/`pg_trgm`, schema `ingestao`, bucket privado `inteiro-teor` |
| 2 | `20260724100002_referencia.sql` | `tribunal`, `area`, `tipo_demanda`, `magistrado`, `vara` + RLS de leitura |
| 3 | `20260724100003_fatos_agregados.sql` | `decisao` (partições 2020–2027), `padrao_magistrado_demanda`, `ingestao.decisao_bruta` |
| 4 | `20260724100004_usuarios_rls.sql` | `plano`, `perfil` (trigger no signup), `perfil_area`, `processo_usuario`, `uso_mensal` + políticas |
| 5 | `20260724100005_indices.sql` | Índices do painel + busca trigram sem acento |
| 6 | `20260724100006_seed.sql` | Planos, 7 áreas, TJSP/TJRJ/TJMG, 12 tipos de demanda |

## Como aplicar

**Opção A — SQL Editor do dashboard** (mais simples): no projeto Supabase,
abra *SQL Editor* e cole/execute cada arquivo na ordem da tabela acima.

**Opção B — CLI do Supabase** (recomendado para o time):

```bash
npx supabase login
npx supabase link --project-ref <ref-do-projeto>
npx supabase db push
```

## Depois de aplicar

1. **Auth** (*Authentication → Providers* no dashboard): e-mail/senha já vem
   ativo; habilitar **Google** (client ID/secret) e **TOTP (2FA)** — cobre
   exatamente o que `login.html` e `criar-conta.html` prometem.
2. **Chaves para o front** (*Settings → API*): `Project URL` + chave
   `publishable`. O front usa `supabase-js`; a chave `service_role` fica SÓ no
   worker de ingestão, nunca no navegador.
3. **Segurança**: rodar os *Advisors* do dashboard (Security e Performance)
   após qualquer mudança de schema.

## Regras de ouro do desenho

- O painel lê **só** `padrao_magistrado_demanda` — nunca varre `decisao`.
- Inteiro teor vai para o bucket `inteiro-teor` (Storage); no banco fica só
  `decisao.inteiro_teor_path`.
- `ingestao.*` e escrita nas tabelas públicas: apenas service role
  (nenhuma política de escrita para clientes).
- `decisao.segredo_justica = true` nunca sai pela API (política RLS).
- `processo_usuario` é privado por dono (`auth.uid()`): processo de escritório
  nunca entra na base pública.
