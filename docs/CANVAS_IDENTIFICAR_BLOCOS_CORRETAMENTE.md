# Canvas Identificar Blocos Corretamente

## Mudanças Implementadas

### 1. Removidos Dados Mockados

- ✅ Removido placeholder "Grazi" do textarea de prompt
- ✅ Removido placeholder "Grazi" do AgentConfigPanel
- ✅ Garantido que `promptMaster` vem APENAS do banco (`prompt_base` do flow)

### 2. Identificação de Blocos por `block_key`

- ✅ Canvas sempre usa `block_key` (PM001, AG001, CAM001, etc.) como `id` do bloco
- ✅ Conexões usam `next_block_key` → `nextBlock` (referência ao `block_key` do próximo)
- ✅ Rotas usam `destination_block_key` → `gotoBlockId` (referência ao `block_key` do destino)

### 3. Ordenação Automática de Blocos

- ✅ Função `orderBlocksByNextBlock()` ordena blocos seguindo a cadeia de `nextBlock`
- ✅ Garante que o canvas renderize na ordem correta: PM001 → AG001 → CAM001 → MSG001 → etc.
- ✅ Blocos desconectados são adicionados no final

### 4. Conversão Correta de Tipos

- ✅ `primeira_mensagem` → `primeira_mensagem` (canvas)
- ✅ `mensagem` → `texto` (canvas)
- ✅ `caminhos` → `conectivos` (canvas)
- ✅ `aguardar` → `aguardar` (canvas)
- ✅ `encerrar` → `encerrar` (canvas)
- ✅ `ferramenta` → `tool` (canvas)

### 5. Logs de Debug

- ✅ Logs detalhados mostram:
  - Blocos recebidos do banco (com `block_key`, `block_type`, `next_block_key`)
  - Blocos convertidos para canvas
  - Blocos ordenados (sequência final)

## Como Funciona Agora

### 1. Ao Carregar Flow

1. **API:** `GET /api/flows/by-assistant/{id}?tenant_id=...`
2. **Dados recebidos:**
   ```json
   {
     "flow": { "id": "...", "prompt_base": "..." },
     "blocks": [
       { "block_key": "PM001", "block_type": "primeira_mensagem", "next_block_key": "AG001", ... },
       { "block_key": "AG001", "block_type": "aguardar", "next_block_key": "CAM001", ... },
       ...
     ],
     "routes": [...]
   }
   ```

3. **Conversão:**
   - `block_key` → `id` do bloco no canvas
   - `block_type` → `type` (com mapeamento)
   - `next_block_key` → `nextBlock`
   - Rotas mapeadas por `block_id` → `routes` do bloco

4. **Ordenação:**
   - Segue cadeia: PM001 → AG001 → CAM001 → MSG001 → etc.
   - Usa `nextBlock` para determinar ordem

5. **Renderização:**
   - Canvas renderiza blocos na ordem correta
   - Conexões visuais seguem `nextBlock`

### 2. Identificação de Tipos

O canvas identifica automaticamente o tipo de cada bloco pelo `type`:
- `primeira_mensagem` → Renderiza como primeira mensagem
- `texto` → Renderiza como mensagem normal
- `conectivos` → Renderiza como roteador (com rotas)
- `aguardar` → Renderiza como aguardar
- `encerrar` → Renderiza como encerrar
- `tool` → Renderiza como ferramenta

### 3. Conexões entre Blocos

- **Sequência normal:** `nextBlock` conecta ao próximo bloco
- **Rotas (conectivos):** `routes[].gotoBlockId` conecta aos blocos destino
- **Fallback:** `fallback.gotoBlockId` conecta ao bloco de fallback

## Verificação

Para verificar se está funcionando:

1. Abra o Flow Editor para um assistente
2. Abra o Console do navegador (F12)
3. Procure por logs `[FlowEditor]`:
   - `📋 Blocos do banco:` - mostra blocos recebidos
   - `✅ Blocos convertidos e ordenados:` - mostra ordem final
   - `📋 Blocos ordenados:` - mostra sequência (PM001 → AG001 → ...)

## Próximos Passos

1. ✅ Teste editando um assistente existente
2. ✅ Verifique se os blocos aparecem na ordem correta no canvas
3. ✅ Verifique se as conexões estão corretas
4. ✅ Verifique se não há dados mockados sendo carregados

O canvas agora está limpo e carrega apenas dados do banco, identificando corretamente os blocos pelos seus `block_key`!
