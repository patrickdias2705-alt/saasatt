-- Migration: Adicionar assistente_id em flow_blocks e flow_routes
-- Execute no SQL Editor do Supabase
-- Isso permite queries diretas por assistente sem JOIN com flows

-- ============================================================================
-- 1. ADICIONAR COLUNA assistente_id EM flow_blocks
-- ============================================================================
ALTER TABLE flow_blocks
ADD COLUMN IF NOT EXISTS assistente_id TEXT;

-- Popular assistente_id dos blocos existentes baseado no flow_id
-- Só atualiza se o flow tiver assistente_id preenchido
UPDATE flow_blocks fb
SET assistente_id = f.assistente_id
FROM flows f
WHERE fb.flow_id = f.id
  AND fb.assistente_id IS NULL
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != '';

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS idx_flow_blocks_assistente ON flow_blocks(assistente_id);

-- ============================================================================
-- 2. ADICIONAR COLUNA assistente_id EM flow_routes
-- ============================================================================
ALTER TABLE flow_routes
ADD COLUMN IF NOT EXISTS assistente_id TEXT;

-- Popular assistente_id das rotas existentes baseado no flow_id
-- Só atualiza se o flow tiver assistente_id preenchido
UPDATE flow_routes fr
SET assistente_id = f.assistente_id
FROM flows f
WHERE fr.flow_id = f.id
  AND fr.assistente_id IS NULL
  AND f.assistente_id IS NOT NULL
  AND f.assistente_id != '';

-- Criar índice para performance
CREATE INDEX IF NOT EXISTS idx_flow_routes_assistente ON flow_routes(assistente_id);

-- ============================================================================
-- 3. ADICIONAR tenant_id TAMBÉM (para queries diretas por tenant)
-- ============================================================================
ALTER TABLE flow_blocks
ADD COLUMN IF NOT EXISTS tenant_id TEXT;

UPDATE flow_blocks fb
SET tenant_id = f.tenant_id
FROM flows f
WHERE fb.flow_id = f.id
  AND fb.tenant_id IS NULL
  AND f.tenant_id IS NOT NULL
  AND f.tenant_id != '';

CREATE INDEX IF NOT EXISTS idx_flow_blocks_tenant ON flow_blocks(tenant_id);

ALTER TABLE flow_routes
ADD COLUMN IF NOT EXISTS tenant_id TEXT;

UPDATE flow_routes fr
SET tenant_id = f.tenant_id
FROM flows f
WHERE fr.flow_id = f.id
  AND fr.tenant_id IS NULL
  AND f.tenant_id IS NOT NULL
  AND f.tenant_id != '';

CREATE INDEX IF NOT EXISTS idx_flow_routes_tenant ON flow_routes(tenant_id);

-- ============================================================================
-- 4. TRIGGER PARA MANTER assistente_id E tenant_id SINCRONIZADOS
-- ============================================================================
-- Quando um flow é atualizado, atualizar assistente_id e tenant_id nos blocos e rotas
CREATE OR REPLACE FUNCTION sync_assistente_tenant_to_blocks_routes()
RETURNS TRIGGER AS $$
BEGIN
  -- Atualizar flow_blocks
  UPDATE flow_blocks
  SET assistente_id = NEW.assistente_id,
      tenant_id = NEW.tenant_id
  WHERE flow_id = NEW.id;

  -- Atualizar flow_routes
  UPDATE flow_routes
  SET assistente_id = NEW.assistente_id,
      tenant_id = NEW.tenant_id
  WHERE flow_id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_flow_assistente_tenant ON flows;
CREATE TRIGGER sync_flow_assistente_tenant
  AFTER UPDATE OF assistente_id, tenant_id ON flows
  FOR EACH ROW
  WHEN (OLD.assistente_id IS DISTINCT FROM NEW.assistente_id OR OLD.tenant_id IS DISTINCT FROM NEW.tenant_id)
  EXECUTE FUNCTION sync_assistente_tenant_to_blocks_routes();

-- ============================================================================
-- 5. VERIFICAÇÃO: Ver quantos blocos/rotas foram atualizados
-- ============================================================================
SELECT 
  'flow_blocks com assistente_id' as tipo,
  COUNT(*) as total
FROM flow_blocks
WHERE assistente_id IS NOT NULL AND assistente_id != ''
UNION ALL
SELECT 
  'flow_blocks sem assistente_id' as tipo,
  COUNT(*) as total
FROM flow_blocks
WHERE assistente_id IS NULL OR assistente_id = ''
UNION ALL
SELECT 
  'flow_routes com assistente_id' as tipo,
  COUNT(*) as total
FROM flow_routes
WHERE assistente_id IS NOT NULL AND assistente_id != ''
UNION ALL
SELECT 
  'flow_routes sem assistente_id' as tipo,
  COUNT(*) as total
FROM flow_routes
WHERE assistente_id IS NULL OR assistente_id = ''
UNION ALL
SELECT 
  'flows sem assistente_id (problema!)' as tipo,
  COUNT(*) as total
FROM flows
WHERE assistente_id IS NULL OR assistente_id = ''
UNION ALL
SELECT 
  'flows sem tenant_id (problema!)' as tipo,
  COUNT(*) as total
FROM flows
WHERE tenant_id IS NULL OR tenant_id = '';

-- Verificar se há blocos/rotas com assistente_id diferente do flow
SELECT 
  'Blocos com assistente_id diferente do flow' as problema,
  COUNT(*) as total
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE fb.assistente_id IS NOT NULL 
  AND f.assistente_id IS NOT NULL
  AND fb.assistente_id != f.assistente_id
UNION ALL
SELECT 
  'Rotas com assistente_id diferente do flow' as problema,
  COUNT(*) as total
FROM flow_routes fr
JOIN flows f ON f.id = fr.flow_id
WHERE fr.assistente_id IS NOT NULL 
  AND f.assistente_id IS NOT NULL
  AND fr.assistente_id != f.assistente_id;
