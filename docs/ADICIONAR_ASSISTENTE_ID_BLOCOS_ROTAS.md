# Adicionar assistente_id e tenant_id em flow_blocks e flow_routes

## Problema

Os blocos (`flow_blocks`) e rotas (`flow_routes`) não tinham `assistente_id` diretamente, apenas através do `flow_id`. Isso dificulta:
- Queries diretas por assistente
- Validação de integridade
- Performance (menos JOINs)

## Solução

Adicionar `assistente_id` e `tenant_id` diretamente nas tabelas `flow_blocks` e `flow_routes`.

---

## Passo 1: Executar Migration SQL

Execute o script de migration no **SQL Editor do Supabase**:

```bash
saas_server/supabase/migration_add_assistente_id_to_blocks_routes.sql
```

Este script:
1. ✅ Adiciona colunas `assistente_id` e `tenant_id` em `flow_blocks`
2. ✅ Adiciona colunas `assistente_id` e `tenant_id` em `flow_routes`
3. ✅ Popula dados existentes baseado no `flow_id`
4. ✅ Cria índices para performance
5. ✅ Cria trigger para manter sincronizado quando flow é atualizado

---

## Passo 2: Código Python Atualizado

O código Python já foi atualizado para incluir `assistente_id` e `tenant_id` ao salvar:

- ✅ `save_flow()` - inclui `assistente_id` e `tenant_id` ao inserir blocos e rotas
- ✅ `insert_default_blocks_and_routes()` - inclui `assistente_id` e `tenant_id` (caso seja usado)

---

## Benefícios

### 1. Queries Diretas
Agora você pode buscar blocos diretamente por assistente:

```sql
-- Antes (precisava JOIN):
SELECT fb.* FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'xxx';

-- Agora (direto):
SELECT * FROM flow_blocks
WHERE assistente_id = 'xxx';
```

### 2. Validação de Integridade
Garante que blocos sempre pertencem ao assistente correto:

```sql
-- Verificar se há blocos órfãos (sem assistente_id):
SELECT COUNT(*) FROM flow_blocks WHERE assistente_id IS NULL;
```

### 3. Performance
Menos JOINs = queries mais rápidas, especialmente com índices:

```sql
-- Índices criados:
CREATE INDEX idx_flow_blocks_assistente ON flow_blocks(assistente_id);
CREATE INDEX idx_flow_routes_assistente ON flow_routes(assistente_id);
CREATE INDEX idx_flow_blocks_tenant ON flow_blocks(tenant_id);
CREATE INDEX idx_flow_routes_tenant ON flow_routes(tenant_id);
```

### 4. Trigger Automático
Quando um flow é atualizado (mudança de `assistente_id` ou `tenant_id`), o trigger atualiza automaticamente todos os blocos e rotas relacionados.

---

## Verificação

Após executar a migration, verifique:

```sql
-- Ver quantos blocos/rotas têm assistente_id:
SELECT 
  'flow_blocks com assistente_id' as tipo,
  COUNT(*) as total
FROM flow_blocks
WHERE assistente_id IS NOT NULL
UNION ALL
SELECT 
  'flow_blocks sem assistente_id' as tipo,
  COUNT(*) as total
FROM flow_blocks
WHERE assistente_id IS NULL;
```

Todos devem ter `assistente_id` preenchido (exceto se houver flows sem `assistente_id`).

---

## Próximos Passos

1. ✅ Execute a migration SQL
2. ✅ Reinicie o servidor FastAPI
3. ✅ Teste salvando um flow - os blocos devem ter `assistente_id` e `tenant_id`
4. ✅ Verifique no banco que os campos estão sendo preenchidos
