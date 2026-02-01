# ✅ Adaptação do assist-tool-craft - CONCLUÍDA

## O que foi feito

### 1. Removido editor simples
- ❌ Deletado: `menu_principal/assistentes/flow/index.html` (editor minimalista)

### 2. Adaptado `useFlowEditor.ts`

#### ✅ Removidos dados mockados:
- `INITIAL_BLOCKS` (blocos de exemplo)
- `INITIAL_PROMPT` (prompt de exemplo)

#### ✅ Carregamento do banco:
- **Antes:** `/api/assistants/{id}/flow` (formato antigo com `flow_json`)
- **Agora:** `/api/flows/by-assistant/{id}?tenant_id=...` (novo formato: `flow` + `blocks` + `routes`)

#### ✅ Conversão de dados:
- **`convertDbToCanvas()`**: Converte dados do banco para formato do canvas
  - `block_key` → `id`
  - `block_type` → `type` (com mapeamento: `mensagem` → `texto`, `caminhos` → `conectivos`)
  - `next_block_key` → `nextBlock`
  - `routes` (do banco) → `routes` (do canvas) com fallback
  - `variable_name` (aguardar) → `content`

#### ✅ Salvamento no banco:
- **Antes:** `PUT /api/assistants/{id}/flow` (com `flow_json`)
- **Agora:** `POST /api/flows/save` (com `flow_id`, `blocks`, `routes`)
- Também atualiza `prompt_base` via `PATCH /api/flows/{id}`

#### ✅ Conversão de dados:
- **`convertCanvasToDb()`**: Converte dados do canvas para formato do banco
  - `id` → `block_key`
  - `type` → `block_type` (com mapeamento reverso)
  - `nextBlock` → `next_block_key`
  - `routes` (do canvas) → `routes` (do banco) com `is_fallback`
  - `content` (aguardar) → `variable_name`

#### ✅ Leitura de parâmetros da URL:
- `assistente_id` ou `assistant_id` → `assistantId`
- `tenant_id` → `tenantId` (novo)

#### ✅ Estados adicionais:
- `flowId`: ID do flow no banco
- `isLoading`: Estado de carregamento

---

## Mapeamentos de tipos

### Block Types (Banco → Canvas)
| Banco | Canvas |
|-------|--------|
| `primeira_mensagem` | `primeira_mensagem` |
| `mensagem` | `texto` |
| `caminhos` | `conectivos` |
| `aguardar` | `aguardar` |
| `encerrar` | `encerrar` |
| `ferramenta` | `tool` |

### Tool Types (Banco → Canvas)
| Banco | Canvas |
|-------|--------|
| `buscar_dados` | `salvar_dados` |
| `verificar_agenda` | `verificar_agenda` |
| `agendar` | `agendar` |
| `consultar_documento` | `consultar_documentos` |
| `enviar_whatsapp` | `enviar_midia` |
| `transferir` | `transferir` |

### Destination Types (Banco → Canvas)
| Banco | Canvas |
|-------|--------|
| `continuar` | `continue` |
| `encerrar` | `end` |
| `loop` | `loop` |
| `goto` | `goto` |

---

## Como funciona agora

1. **Ao abrir o Flow Editor:**
   - Lê `assistente_id` e `tenant_id` da URL
   - Chama `GET /api/flows/by-assistant/{id}?tenant_id=...`
   - Converte dados do banco para formato do canvas
   - Renderiza blocos no canvas automaticamente

2. **Ao salvar:**
   - Converte dados do canvas para formato do banco
   - Chama `POST /api/flows/save` com `flow_id`, `blocks`, `routes`
   - Atualiza `prompt_base` via `PATCH /api/flows/{id}`

3. **Identificação automática:**
   - Blocos são identificados pelo `block_type` do banco
   - Rotas (caminhos) são mapeadas automaticamente
   - Fallback é preservado

---

## Próximos passos

1. **Recompilar o assist-tool-craft:**
   ```bash
   cd /Users/patrickdiasparis/Downloads/assist-tool-craft-main
   npm run build
   # ou
   bun run build
   ```

2. **Testar:**
   - Abrir Flow Editor para um assistente existente
   - Verificar se carrega blocos do banco
   - Editar e salvar
   - Verificar se salva corretamente

3. **Se houver erros:**
   - Verificar console do navegador
   - Verificar logs do servidor FastAPI
   - Verificar se `tenant_id` está sendo passado na URL do iframe

---

## Arquivos modificados

- ✅ `/Users/patrickdiasparis/Downloads/assist-tool-craft-main/src/hooks/useFlowEditor.ts`
- ✅ `/Users/patrickdiasparis/Downloads/assist-tool-craft-main/src/pages/FlowEditor.tsx` (ajuste no onClick)

## Arquivos removidos

- ❌ `/Users/patrickdiasparis/Downloads/salesdever_software_main-main 7/menu_principal/assistentes/flow/index.html`
