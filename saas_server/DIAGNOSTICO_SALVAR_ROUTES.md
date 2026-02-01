# 🔍 Diagnóstico: Routes Não Estão Sendo Salvas

## 📋 Passos para Diagnosticar

### 1. Verificar Console do Navegador (F12)

Quando você editar uma route e clicar em "Salvar", verifique no console:

```
💾 [FlowEditor] Salvando: {
  flow_id: "...",
  blocks: X,
  routes: Y,
  routes_detail: [
    {block_key: "CAM001", route_key: "...", label: "..."}
  ]
}
```

**O que verificar:**
- ✅ `routes` tem o número correto de routes?
- ✅ `routes_detail` mostra a route editada com o novo `label`?
- ✅ `route_key` está presente e correto?

### 2. Verificar Resposta da API

No console, após salvar, deve aparecer:
```
✅ [FlowEditor] Flow salvo com sucesso: {success: true, version: X}
```

Se aparecer erro:
```
❌ [FlowEditor] Erro ao salvar: {status: 500, errorText: "..."}
```

### 3. Verificar Logs do Servidor

No terminal onde o servidor está rodando, procure por:
```
🔵 [API] save_flow chamado - flow_id=..., blocks=X, routes=Y
🔵 [API] Routes recebidas do frontend:
  [0] block_key=CAM001, route_key=..., label='...'
save_flow: 🗑️ Deletando routes antigas...
save_flow: ➕ Inserindo X routes...
save_flow: ✅ X routes inseridas com sucesso
```

### 4. Verificar no Banco

Execute no Supabase:
```sql
-- Ver routes do CAM001
SELECT 
    route_key,
    label,
    keywords,
    response,
    updated_at,
    created_at
FROM flow_routes
WHERE block_id = (
    SELECT id FROM flow_blocks WHERE block_key = 'CAM001' LIMIT 1
)
ORDER BY ordem;
```

**O que verificar:**
- ✅ A route editada tem o `label` atualizado?
- ✅ O `updated_at` é recente (depois de você salvar)?

## 🐛 Possíveis Problemas

### Problema 1: Routes não estão sendo enviadas
**Sintoma**: `routes: 0` no console
**Causa**: Frontend não está coletando routes dos blocos
**Solução**: Verificar se `block.routes` existe quando salva

### Problema 2: route_key não está sendo preservado
**Sintoma**: Routes são inseridas mas com `route_key` diferente
**Causa**: Frontend não está preservando `routeKey` ao carregar
**Solução**: Verificar se `route.routeKey` está sendo preservado

### Problema 3: Backend não está inserindo
**Sintoma**: Logs mostram erro ao inserir
**Causa**: Erro de constraint ou tipo de dados
**Solução**: Verificar logs do servidor para erro específico

### Problema 4: Routes são deletadas mas não inseridas
**Sintoma**: Routes somem do banco após salvar
**Causa**: Erro na inserção após deletar
**Solução**: Verificar se `block_key` está correto e existe em `block_key_to_id`

## 🔧 Solução Rápida

Se nada funcionar, execute este SQL para ver o estado atual:

```sql
-- Ver estado atual das routes
SELECT 
    fr.id,
    fr.route_key,
    fr.label,
    fr.updated_at,
    fb.block_key,
    fb.block_type
FROM flow_routes fr
JOIN flow_blocks fb ON fb.id = fr.block_id
WHERE fb.block_key = 'CAM001'
ORDER BY fr.ordem;
```

E me envie:
1. O que aparece no console quando você salva
2. Os logs do servidor
3. O resultado do SQL acima
