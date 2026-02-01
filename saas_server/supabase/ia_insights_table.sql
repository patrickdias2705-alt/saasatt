-- =============================================================================
-- Tabela ia_insights: dados que a Grazi Insights usa para organizar os 4 cards
-- (Geral, Ligações, Conversas, Agendamentos) no dashboard.
-- Aplicar no SQL Editor do Supabase. A API do saas_server lê por tenant_id + data.
-- =============================================================================

create table if not exists public.ia_insights (
  id uuid primary key default gen_random_uuid(),
  tenant_id text not null,
  data date not null,

  -- Textos por categoria (preenchidos por job/n8n/IA)
  geral text not null default '',
  calls text not null default '',
  conversas text not null default '',
  agendamentos text not null default '',
  consideracoes text not null default '',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique(tenant_id, data)
);

-- Se a tabela já existia sem consideracoes, adicionar a coluna:
alter table public.ia_insights
  add column if not exists consideracoes text not null default '';

create index if not exists ia_insights_tenant_data_idx
  on public.ia_insights (tenant_id, data);

comment on table public.ia_insights is 'Insights diários por tenant: Grazi Insights lê para os cards do dashboard';

-- RLS: permitir leitura pela service_role (API do saas_server usa SUPABASE_KEY)
alter table public.ia_insights enable row level security;

create policy "Service role pode ler ia_insights"
  on public.ia_insights for select
  using (true);

-- Exemplo: inserir um registro de teste (troque TENANT_ID pelo UUID do seu tenant)
-- insert into public.ia_insights (tenant_id, data, geral, calls, conversas, agendamentos, consideracoes)
-- values (
--   'TENANT_ID',
--   current_date,
--   'No dia de hoje houve um volume de 11 ligações, 5 conversas registradas e 2 agendamentos. Destaque para engajamento em tema de futebol.',
--   'Foram realizadas 11 chamadas. 7 sem transcrição ou encerramento rápido; 5 conversas com leads.',
--   '5 conversas registradas com leads. Tema recorrente: futebol. Ligação com Vinícius mostrou interesse; houve falha no envio do link de agendamento.',
--   '2 agendamentos no período (um pendente de confirmação).',
--   'Observar falha técnica no envio de link para Vinícius.'
-- );
