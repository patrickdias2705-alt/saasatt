# ✅ Correção: Salvar Routes Atualizadas

## 🔍 Problema Identificado

Quando você edita uma route no Flow Editor e salva, a mudança não estava sendo atualizada na tabela `flow_routes`.

## ✅ Correções Implementadas

### 1. Frontend (`assistente.html`)

#### Carregamento de Routes:
- ✅ Agora preserva `routeKey` original do banco
- ✅ Usa `route.route_key` como `routeKey` no objeto da route
- ✅ Mantém `id` (UUID) e `routeKey` (string) separados

#### Salvamento de Routes:
- ✅ Usa `route.routeKey` (preserva o `route_key` original)
- ✅ Se não tiver `routeKey`, gera baseado no `block_key`
- ✅ Preserva `ordem` original das routes
- ✅ Logs detalhados para debug

### 2. Backend (`flow_service.py`)

- ✅ Deleta todas as routes antigas antes de inserir
- ✅ Valida que `route_key` existe antes de inserir
- ✅ Gera `route_key` se não fornecido
- ✅ Logs detalhados para identificar problemas

## 🔄 Como Funciona Agora

1. **Ao carregar:**
   ```javascript
   {
     id: "uuid-do-banco",
     routeKey: "CAM001_route_1", // ← Preservado do banco
     label: "Confirmou que é ele",
     // ...
   }
   ```

2. **Ao editar:**
   - Você edita `label`, `keywords`, `response`
   - O objeto mantém o `routeKey` original

3. **Ao salvar:**
   ```javascript
   {
     block_key: "CAM001",
     route_key: "CAM001_route_1", // ← Usa routeKey preservado
     label: "Novo label editado",
     // ...
   }
   ```

4. **No banco:**
   - Backend deleta routes antigas
   - Insere routes novas com `route_key` correto
   - Tabela `flow_routes` é atualizada

## 🧪 Como Testar

1. **Edite uma route:**
   - Abra o Flow Editor
   - Clique no bloco CAM001
   - Edite o label de uma route (ex: "Confirmou que é ele" → "Confirmou!")
   - Clique em "Salvar"

2. **Verifique no console:**
   ```
   💾 [FlowEditor] Salvando: {
     routes_detail: [
       {block_key: "CAM001", route_key: "CAM001_route_1", label: "Confirmou!"}
     ]
   }
   ```

3. **Verifique no banco:**
   ```sql
   SELECT route_key, label, updated_at
   FROM flow_routes
   WHERE block_id = (
     SELECT id FROM flow_blocks WHERE block_key = 'CAM001' LIMIT 1
   )
   ORDER BY ordem;
   ```

4. **Resultado esperado:**
   - `label` deve estar atualizado
   - `updated_at` deve ser recente
   - `route_key` deve ser preservado (ex: "CAM001_route_1")

## ✅ O Que Foi Corrigido

1. ✅ Preservação do `route_key` original ao carregar
2. ✅ Uso do `route_key` correto ao salvar
3. ✅ Logs detalhados para debug
4. ✅ Validação no backend para garantir `route_key` válido

## 🎯 Resultado

Agora quando você edita uma route e salva:
- ✅ O `route_key` é preservado
- ✅ A route é atualizada corretamente no banco
- ✅ Você pode ver as mudanças imediatamente
