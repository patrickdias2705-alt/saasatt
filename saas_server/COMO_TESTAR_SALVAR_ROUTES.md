# Como Testar o Salvamento de Routes

## ✅ Correções Implementadas

### 1. **Backend (`flows.py`)**
- ✅ Endpoint `PATCH /api/flows/{flow_id}/blocks/{block_key}` agora salva routes quando o bloco é do tipo `"caminhos"`
- ✅ Função `_save_block_routes()` criada para gerenciar o salvamento de routes
- ✅ Logs detalhados adicionados para debug

### 2. **Frontend (`assistente.html`)**
- ✅ Função `saveSingleBlock()` criada para salvar um bloco individual com suas routes
- ✅ Salvamento automático após 1 segundo de inatividade ao editar routes
- ✅ Botão manual "💾 Salvar Bloco Agora" adicionado no painel de propriedades
- ✅ Logs detalhados no console do navegador

### 3. **Schema (`schemas.py`)**
- ✅ Campo `routes: Optional[List[FlowRouteUpsert]]` adicionado em `FlowBlockUpsert`

## 🧪 Como Testar

### Teste 1: Editar Route e Aguardar Salvamento Automático

1. Abra o Flow Editor
2. Selecione um bloco do tipo "Caminhos" (CAM001)
3. Edite uma route (label, keywords ou response)
4. **Aguarde 1 segundo** sem editar nada
5. Verifique no console do navegador:
   ```
   ✅ [FlowEditor] Route atualizada: block=CAM001, route=...
   💾 [FlowEditor] Salvando bloco CAM001 automaticamente após edição de route
   📤 [FlowEditor] Enviando PATCH para /api/flows/.../blocks/CAM001
   ✅ [FlowEditor] Bloco CAM001 salvo com sucesso. Routes salvas: 3
   ```
6. Verifique no banco de dados:
   ```sql
   SELECT route_key, label, keywords, response 
   FROM flow_routes 
   WHERE block_id = (SELECT id FROM flow_blocks WHERE block_key = 'CAM001');
   ```

### Teste 2: Usar Botão Manual de Salvar

1. Abra o Flow Editor
2. Selecione um bloco do tipo "Caminhos" (CAM001)
3. Edite uma ou mais routes
4. Clique no botão **"💾 Salvar Bloco Agora"** no painel de propriedades
5. Verifique no console e no banco (mesmo processo do Teste 1)

### Teste 3: Salvar Flow Inteiro

1. Abra o Flow Editor
2. Edite várias routes em diferentes blocos de caminhos
3. Clique no botão **"Salvar"** principal (salva todo o flow)
4. Verifique no console:
   ```
   💾 [FlowEditor] Salvando: { flow_id: ..., blocks: X, routes: Y }
   ```
5. Verifique no banco que todas as routes foram salvas

## 🔍 Debug - Verificar Logs

### No Console do Navegador (F12)

Procure por estas mensagens:
- `✅ [FlowEditor] Route atualizada` - Route foi atualizada no objeto em memória
- `💾 [FlowEditor] Salvando bloco...` - Salvamento iniciado
- `📤 [FlowEditor] Enviando PATCH...` - Payload sendo enviado
- `✅ [FlowEditor] Bloco ... salvo com sucesso` - Salvamento concluído

### No Log do Servidor

Procure por estas mensagens:
- `🔵 [API] update_single_block: flow_id=..., block_key=...`
- `🔵 [API] Bloco ... é do tipo 'caminhos' com X routes`
- `🔵 [API] Routes recebidas: [...]`
- `✅ [API] X routes inseridas com sucesso`

## ⚠️ Problemas Comuns

### Problema: Routes não estão sendo salvas

**Verificar:**
1. O bloco é realmente do tipo `"caminhos"`? (verificar `block_type` no banco)
2. O frontend está enviando `routes` no payload? (verificar console do navegador)
3. O backend está recebendo `routes`? (verificar logs do servidor)
4. Há erros no console do navegador ou nos logs do servidor?

### Problema: Salvamento automático não funciona

**Solução:**
- Use o botão manual "💾 Salvar Bloco Agora"
- Ou salve o flow inteiro usando o botão "Salvar" principal

### Problema: Routes antigas não são deletadas

**Verificar:**
- A função `_save_block_routes()` está deletando routes antigas antes de inserir novas?
- Verificar logs: `🗑️ [API] Routes antigas deletadas do bloco ...`

## 📋 Estrutura Esperada dos Dados

### Payload Enviado pelo Frontend

```json
{
  "block_key": "CAM001",
  "block_type": "caminhos",
  "content": "Título do conectivo",
  "routes": [
    {
      "block_key": "CAM001",
      "route_key": "CAM001_route_1",
      "label": "Confirmou que é ele",
      "ordem": 1,
      "cor": "#22c55e",
      "keywords": ["sim", "sou eu"],
      "response": "Perfeito!",
      "destination_type": "continuar",
      "destination_block_key": "MSG001",
      "max_loop_attempts": 2,
      "is_fallback": false
    },
    {
      "block_key": "CAM001",
      "route_key": "CAM001_fallback",
      "label": "Não entendi",
      "ordem": 999,
      "cor": "#6b7280",
      "keywords": [],
      "response": "Não entendi...",
      "destination_type": "loop",
      "destination_block_key": null,
      "max_loop_attempts": 2,
      "is_fallback": true
    }
  ]
}
```

## 🎯 Próximos Passos

Se ainda não funcionar após seguir estes passos:

1. **Copie os logs completos** do console do navegador
2. **Copie os logs completos** do servidor
3. **Execute esta query SQL** para verificar o estado atual:
   ```sql
   SELECT 
     fb.block_key,
     fb.block_type,
     COUNT(fr.id) as routes_count
   FROM flow_blocks fb
   LEFT JOIN flow_routes fr ON fr.block_id = fb.id
   WHERE fb.block_key = 'CAM001'
   GROUP BY fb.block_key, fb.block_type;
   ```
4. **Envie essas informações** para análise
