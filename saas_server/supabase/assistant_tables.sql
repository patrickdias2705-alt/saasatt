-- Supabase schema for Salesdever SaaS assistants
-- Tables:
--   - assistant_profiles: configurações globais do assistente (identidade/voz/regras etc.)
--   - assistant_flows: JSON do flow (promptMaster + blocks) e metadados
--   - prompt_import_runs (opcional): histórico do import assistido
--
-- Apply in Supabase SQL editor (or migration system).

-- Enable UUID generation helpers (Supabase usually already has this)
create extension if not exists "pgcrypto";

-- ============================================================================
-- assistant_profiles
-- ============================================================================
create table if not exists public.assistant_profiles (
  id uuid primary key default gen_random_uuid(),
  assistant_id text not null unique,

  -- High-level fields used to compose Prompt Master
  identity text not null default '',
  personality text not null default '',
  phonetic_rules text not null default '',
  absolute_rules text not null default '',
  natural_expressions text not null default '',

  -- Optional structured settings (ex: agendamento/janelas/dias úteis etc.)
  scheduling_rules jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists assistant_profiles_assistant_id_idx
  on public.assistant_profiles (assistant_id);

-- ============================================================================
-- assistant_flows
-- ============================================================================
create table if not exists public.assistant_flows (
  id uuid primary key default gen_random_uuid(),
  assistant_id text not null unique,

  -- JSON structure expected by Flow Editor (promptMaster + blocks)
  flow_json jsonb not null default '{}'::jsonb,

  -- Optional metadata
  title text not null default '',
  description text not null default '',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists assistant_flows_assistant_id_idx
  on public.assistant_flows (assistant_id);

-- ============================================================================
-- prompt_import_runs (optional)
-- ============================================================================
create table if not exists public.prompt_import_runs (
  id uuid primary key default gen_random_uuid(),
  assistant_id text not null,

  input_text text not null default '',
  extracted_globals jsonb not null default '{}'::jsonb,
  suggested_blocks jsonb not null default '[]'::jsonb,
  approved_flow jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now()
);

create index if not exists prompt_import_runs_assistant_id_idx
  on public.prompt_import_runs (assistant_id);

-- ============================================================================
-- updated_at triggers (optional)
-- ============================================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'set_updated_at_assistant_profiles'
  ) then
    create trigger set_updated_at_assistant_profiles
    before update on public.assistant_profiles
    for each row execute function public.set_updated_at();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'set_updated_at_assistant_flows'
  ) then
    create trigger set_updated_at_assistant_flows
    before update on public.assistant_flows
    for each row execute function public.set_updated_at();
  end if;
end $$;

