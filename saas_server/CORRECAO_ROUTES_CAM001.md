# ✅ Correção: Routes do CAM001 não aparecendo no Flow Editor

## 🔍 Problema Identificado

O Flow Editor mostrava "0 caminhos + fallback" mesmo quando o prompt tinha 3 routes definidas:
- `+ Confirmou que é ele`
- `x Não é a pessoa`  
- `? Não entendi` (fallback)

## ✅ Correções Implementadas

### 1. Frontend (`assistente.html`)
- ✅ Mudado para usar API nova `/api/flows/by-assistant/{id}` em vez do webhook antigo
- ✅ Adicionada lógica para associar routes aos blocos usando `block_id` → `block_key`
- ✅ Separação correta de routes normais e fallback
- ✅ Mapeamento correto de tipos (`caminhos` → `conectivos`)

### 2. Backend (`flow_service.py`)
- ✅ Adicionada verificação: se tem blocos de caminhos mas não tem routes, parseia o prompt novamente
- ✅ Gera routes automaticamente do `prompt_voz` quando faltam
- ✅ Insere routes no banco com `block_id` correto

## 🔧 Como Funciona Agora

1. **Ao carregar o flow:**
   - Backend verifica se há blocos de caminhos sem routes
   - Se faltarem routes, parseia o `prompt_voz` do assistente
   - Insere as routes no banco automaticamente

2. **Frontend recebe:**
   - `blocks`: Lista de blocos com `block_key` e `block_id`
   - `routes`: Lista de routes com `block_id` (UUID)

3. **Frontend associa:**
   - Cria mapa `block_id` → `block_key`
   - Agrupa routes por `block_key`
   - Associa routes aos blocos corretos

## 🧪 Teste

1. Abra o Flow Editor para um assistente que tem CAM001 no prompt
2. Verifique no console do navegador:
   ```
   ✅ [FlowEditor] Dados recebidos: {blocks: X, routes: Y}
   ```
3. O bloco CAM001 deve mostrar as 3 routes:
   - ✅ Confirmou que é ele (verde)
   - ❌ Não é a pessoa (vermelho)
   - ❓ Não entendi (fallback, cinza)

## 📋 Script SQL de Verificação

Se ainda não aparecer, execute no Supabase:

```sql
-- Verificar se as routes estão no banco
SELECT fr.*, fb.block_key 
FROM flow_routes fr
JOIN flow_blocks fb ON fb.id = fr.block_id
WHERE fb.block_key = 'CAM001'
ORDER BY fr.ordem;
```

Se não houver routes, execute: `VERIFICAR_E_INSERIR_ROUTES_CAM001.sql`

## 🎯 Resultado Esperado

O Flow Editor deve mostrar:
- **3 caminhos + fallback** (não mais "0 caminhos")
- Routes com labels corretos
- Keywords e respostas corretas
- Destinos corretos (MSG001, ENC001, AG001)
