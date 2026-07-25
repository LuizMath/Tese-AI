/* Cliente Supabase compartilhado — Tese AI.
   Carregar DEPOIS do SDK:
   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
   <script src="tese-supabase.js"></script>
   A chave abaixo é a "publishable": pública por design, segura no navegador.
   O que protege os dados é o Row Level Security no banco. */
(function () {
  'use strict';
  var URL_SUPABASE = 'https://nyzwlljgesgtrntsnore.supabase.co';
  var CHAVE_PUBLICA = 'sb_publishable_CbLlOkhjl1GE0WTxJTYVSA_Qdp50sA_';
  window.teseSupabase = window.supabase.createClient(URL_SUPABASE, CHAVE_PUBLICA);
})();
