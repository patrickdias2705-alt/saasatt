-- ============================================================================
-- FLOW EDITOR: flows, flow_blocks, flow_routes, flow_versions
-- Aplicar no SQL Editor do Supabase.
-- tenant_id = cliente (isolamento: um tenant tem N assistentes; cada assistente tem 1 flow).
-- ============================================================================

-- TABELA: flows
CREATE TABLE IF NOT EXISTS flows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id TEXT NOT NULL,
  assistente_id TEXT,

  name TEXT NOT NULL,
  description TEXT,
  prompt_base TEXT,

  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'archived')),
  is_active BOOLEAN DEFAULT false,

  version INTEGER DEFAULT 1,
  published_at TIMESTAMPTZ,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_flows_tenant ON flows(tenant_id);
CREATE INDEX IF NOT EXISTS idx_flows_assistente ON flows(assistente_id);
CREATE INDEX IF NOT EXISTS idx_flows_status ON flows(status);

-- TABELA: flow_blocks
CREATE TABLE IF NOT EXISTS flow_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flow_id UUID NOT NULL REFERENCES flows(id) ON DELETE CASCADE,

  block_key TEXT NOT NULL,
  block_type TEXT NOT NULL CHECK (block_type IN (
    'primeira_mensagem',
    'mensagem',
    'aguardar',
    'caminhos',
    'ferramenta',
    'encerrar'
  )),

  content TEXT NOT NULL,
  variable_name TEXT,
  timeout_seconds INTEGER,
  analyze_variable TEXT,

  tool_type TEXT CHECK (tool_type IN (
    'buscar_dados',
    'verificar_agenda',
    'agendar',
    'enviar_whatsapp',
    'consultar_documento',
    'webhook'
  )),
  tool_config JSONB DEFAULT '{}',

  end_type TEXT CHECK (end_type IN (
    'transferir',
    'finalizar',
    'nao_qualificado',
    'agendar_retorno'
  )),
  end_metadata JSONB DEFAULT '{}',

  next_block_key TEXT,
  order_index INTEGER DEFAULT 0,
  position_x FLOAT DEFAULT 0,
  position_y FLOAT DEFAULT 0,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE(flow_id, block_key)
);

CREATE INDEX IF NOT EXISTS idx_flow_blocks_flow ON flow_blocks(flow_id);
CREATE INDEX IF NOT EXISTS idx_flow_blocks_type ON flow_blocks(block_type);
CREATE INDEX IF NOT EXISTS idx_flow_blocks_order ON flow_blocks(flow_id, order_index);

-- TABELA: flow_routes
CREATE TABLE IF NOT EXISTS flow_routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flow_id UUID NOT NULL REFERENCES flows(id) ON DELETE CASCADE,
  block_id UUID NOT NULL REFERENCES flow_blocks(id) ON DELETE CASCADE,

  route_key TEXT NOT NULL,
  label TEXT NOT NULL,
  ordem INTEGER DEFAULT 0,
  cor TEXT DEFAULT '#6b7280',
  keywords TEXT[] DEFAULT '{}',
  response TEXT,

  destination_type TEXT DEFAULT 'continuar' CHECK (destination_type IN (
    'continuar',
    'goto',
    'loop',
    'encerrar'
  )),
  destination_block_key TEXT,
  max_loop_attempts INTEGER DEFAULT 2,
  is_fallback BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  UNIQUE(block_id, route_key)
);

CREATE INDEX IF NOT EXISTS idx_flow_routes_flow ON flow_routes(flow_id);
CREATE INDEX IF NOT EXISTS idx_flow_routes_block ON flow_routes(block_id);
CREATE INDEX IF NOT EXISTS idx_flow_routes_ordem ON flow_routes(block_id, ordem);

-- TABELA: flow_versions
CREATE TABLE IF NOT EXISTS flow_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flow_id UUID NOT NULL REFERENCES flows(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  flow_snapshot JSONB NOT NULL,
  published_by TEXT,
  published_at TIMESTAMPTZ DEFAULT now(),
  notes TEXT,
  UNIQUE(flow_id, version)
);

CREATE INDEX IF NOT EXISTS idx_flow_versions_flow ON flow_versions(flow_id);

-- RLS
ALTER TABLE flows ENABLE ROW LEVEL SECURITY;
ALTER TABLE flow_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE flow_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE flow_versions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "flows_tenant_isolation" ON flows;
CREATE POLICY "flows_tenant_isolation" ON flows
  FOR ALL USING (true);

DROP POLICY IF EXISTS "flow_blocks_tenant_isolation" ON flow_blocks;
CREATE POLICY "flow_blocks_tenant_isolation" ON flow_blocks
  FOR ALL USING (true);

DROP POLICY IF EXISTS "flow_routes_tenant_isolation" ON flow_routes;
CREATE POLICY "flow_routes_tenant_isolation" ON flow_routes
  FOR ALL USING (true);

DROP POLICY IF EXISTS "flow_versions_tenant_isolation" ON flow_versions;
CREATE POLICY "flow_versions_tenant_isolation" ON flow_versions
  FOR ALL USING (true);

-- Trigger: updated_at
CREATE OR REPLACE FUNCTION flow_editor_update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS flows_updated_at ON flows;
CREATE TRIGGER flows_updated_at
  BEFORE UPDATE ON flows
  FOR EACH ROW EXECUTE FUNCTION flow_editor_update_updated_at();

DROP TRIGGER IF EXISTS flow_blocks_updated_at ON flow_blocks;
CREATE TRIGGER flow_blocks_updated_at
  BEFORE UPDATE ON flow_blocks
  FOR EACH ROW EXECUTE FUNCTION flow_editor_update_updated_at();

DROP TRIGGER IF EXISTS flow_routes_updated_at ON flow_routes;
CREATE TRIGGER flow_routes_updated_at
  BEFORE UPDATE ON flow_routes
  FOR EACH ROW EXECUTE FUNCTION flow_editor_update_updated_at();
