# 🤖 PROMPT COMPLETO PARA CLAUDE AI - Sistema de Patch Cirúrgico de Prompts

## 📋 CONTEXTO DO PROJETO

Você está ajudando a implementar um sistema de **patch cirúrgico de prompts** para uma plataforma SaaS de assistentes de voz (IA que faz ligações telefônicas).

### O Problema que Resolvemos

Quando um usuário edita um bloco específico no Flow Editor (ex: mensagem ENC001), precisamos atualizar **APENAS aquela seção** no prompt grande que fica na tabela `assistentes.prompt_voz`, mantendo todo o resto do prompt intacto.

**Exemplo:**
- Prompt tem 5000 caracteres
- Usuário muda apenas 1 frase no bloco ENC001
- Queremos atualizar só aquela seção (50 caracteres)
- Os outros 4950 caracteres devem permanecer **exatamente iguais**

---

## 🗄️ ESTRUTURA DO BANCO DE DADOS

### Tabela: `assistentes`
Armazena os assistentes de voz e seus prompts completos.

```sql
CREATE TABLE assistentes (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    nome TEXT,
    prompt_voz TEXT,  -- ⭐ PROMPT COMPLETO (grande, ~5000+ caracteres)
    prompt_base TEXT,
    -- outros campos...
);
```

**Campo crítico:** `prompt_voz` - contém o prompt completo em formato Markdown

### Tabela: `flows`
Representa um fluxo de conversa vinculado a um assistente.

```sql
CREATE TABLE flows (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    assistente_id UUID NOT NULL,  -- ⭐ FK para assistentes.id
    name TEXT,
    prompt_base TEXT,
    version INTEGER DEFAULT 1,
    -- outros campos...
);
```

### Tabela: `flow_blocks`
Armazena os blocos individuais do fluxo (cada bloco é uma etapa da conversa).

```sql
CREATE TABLE flow_blocks (
    id UUID PRIMARY KEY,
    flow_id UUID NOT NULL,  -- ⭐ FK para flows.id
    block_key TEXT NOT NULL,  -- ⭐ ID único do bloco (ex: "ENC001", "MSG001")
    block_type TEXT NOT NULL,  -- ⭐ Tipo: "primeira_mensagem", "mensagem", "aguardar", "caminhos", "encerrar"
    content TEXT,  -- ⭐ Conteúdo do bloco (o que a IA fala ou escuta)
    next_block_key TEXT,  -- Próximo bloco na sequência
    variable_name TEXT,  -- Para blocos "aguardar": nome da variável
    analyze_variable TEXT,  -- Para blocos "caminhos": variável a analisar
    order_index INTEGER,
    position_x FLOAT,
    position_y FLOAT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

**Campos críticos:**
- `block_key`: Identificador único (ex: "ENC001", "MSG001", "AG001")
- `block_type`: Tipo do bloco
- `content`: O texto que precisa ser atualizado no `prompt_voz`

### Tabela: `flow_routes`
Armazena as rotas/condições dentro de blocos do tipo "caminhos".

```sql
CREATE TABLE flow_routes (
    id UUID PRIMARY KEY,
    flow_id UUID NOT NULL,
    block_key TEXT NOT NULL,  -- ⭐ Bloco pai (tipo "caminhos")
    route_key TEXT NOT NULL,  -- ID da rota (ex: "confirmou", "nao_e_ele")
    label TEXT,
    ordem INTEGER,
    cor TEXT,
    keywords TEXT[],  -- Array de palavras-chave
    response TEXT,  -- Resposta da IA
    destination_type TEXT,  -- "continuar", "goto", "loop", "encerrar"
    destination_block_key TEXT,  -- Bloco de destino
    is_fallback BOOLEAN DEFAULT FALSE,
    -- outros campos...
);
```

---

## 📝 FORMATO DO PROMPT (`prompt_voz`)

O `prompt_voz` é um texto grande em formato Markdown que contém:

1. **Cabeçalho** com instruções gerais
2. **Seções de blocos** identificadas por `block_key`

### Exemplo de Prompt Completo:

```markdown
# PROMPT - FLOW DO ASSISTENTE
# IA DE VOZ PARA LIGAÇÕES TELEFÔNICAS

- **Falar** = O que a IA diz em voz alta durante a ligação.
- **Aguardar** = A IA para de falar e escuta o que o lead diz.
- **Caminhos** = Decisões baseadas no que o lead FALOU.

Seja objetiva, cordial e siga o fluxo abaixo.

---

## FLUXO DA CONVERSA

### ABERTURA DA LIGACAO

**Ao iniciar a ligacao, fale:**

"Olá! Aqui é a [Nome da IA]. Estou falando com [Nome do Lead]?"

**Depois:** Va para [AG001]

---

### AGUARDAR [AG001]

**Escute a confirmação do lead.** 
Salvar resposta do lead em: `{{confirmacao_nome}}`

**Depois:** Va para [CAM001]

---

### CAMINHOS [CAM001]

**Analisando:** `{{confirmacao_nome}}`

**É a pessoa certa?**

#### + Confirmou que é ele
**Quando o lead disser:** `sim`, `sou eu`, `isso`
**Fale:** "Perfeito! Em que posso ajudar?"
**Depois:** Continue para [MSG001]

#### x Não é a pessoa
**Quando o lead disser:** `não`, `engano`, `número errado`
**Fale:** "Desculpe pelo engano. Até logo!"
**Depois:** Encerre em [ENC001]

---

### MENSAGEM [MSG001]

**Fale:**

"Perfeito! Em que posso ajudar?"

---

### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"Desculpe pelo engano. Até logo!"

---
```

---

## 🎯 O QUE QUEREMOS FAZER

### Objetivo Principal

Quando um registro em `flow_blocks` é **INSERT**, **UPDATE** ou **DELETE**, queremos:

1. **Identificar** qual seção do `prompt_voz` corresponde àquele `block_key`
2. **Atualizar APENAS** aquela seção específica
3. **Manter TODO o resto** do prompt exatamente igual

### Exemplo Prático

**Situação:**
- `flow_blocks` tem um registro com `block_key = "ENC001"` e `content = "Desculpe pelo engano. Até logo!"`
- Usuário edita e muda para `content = "Desculpe pelo engano. Até logooooo!"`
- Fazemos UPDATE em `flow_blocks`

**O que deve acontecer:**
1. Trigger detecta UPDATE em `flow_blocks` onde `block_key = "ENC001"`
2. Busca `assistente_id` através de `flow_id` → `flows.assistente_id`
3. Busca `prompt_voz` atual do assistente
4. **Localiza** a seção `### ENCERRAR [ENC001]: finalizar` no prompt
5. **Substitui APENAS** o conteúdo dentro dessa seção
6. **Mantém** todo o resto do prompt (cabeçalho, outras seções, formatação)

**Resultado:**
```markdown
### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"Desculpe pelo engano. Até logooooo!"  ← ⭐ SÓ ISSO MUDOU
```

Todo o resto permanece igual.

---

## 🔍 IDENTIFICAÇÃO DE SEÇÕES

### Padrões de Identificação

Cada tipo de bloco tem um padrão de título no prompt:

| Tipo (`block_type`) | Padrão no Prompt | Exemplo |
|---------------------|------------------|---------|
| `primeira_mensagem` | `### ABERTURA DA LIGACAO` | `### ABERTURA DA LIGACAO` |
| `mensagem` | `### MENSAGEM [BLOCK_KEY]` | `### MENSAGEM [MSG001]` |
| `aguardar` | `### AGUARDAR [BLOCK_KEY]` | `### AGUARDAR [AG001]` |
| `caminhos` | `### CAMINHOS [BLOCK_KEY]` | `### CAMINHOS [CAM001]` |
| `encerrar` | `### ENCERRAR [BLOCK_KEY]: finalizar` ou `### ENCERRAR [BLOCK_KEY]` | `### ENCERRAR [ENC001]: finalizar` |

### Delimitadores de Seção

As seções são separadas por:
- `---` (três hífens) antes e depois
- Ou quebra de linha dupla `\n\n`
- Ou início de nova seção `###`

**Exemplo:**
```markdown
---

### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"Desculpe pelo engano. Até logo!"

---

### MENSAGEM [MSG001]
```

---

## 🛠️ FORMATO DE CADA TIPO DE BLOCO

### 1. `primeira_mensagem` (PM001, PM002, etc.)

**Formato no prompt:**
```markdown
### ABERTURA DA LIGACAO

**Ao iniciar a ligacao, fale:**

"[conteúdo]"

**Depois:** Va para [PRÓXIMO_BLOCO]
```

**Dados do banco:**
- `content`: Texto entre aspas
- `next_block_key`: Próximo bloco após `[`

### 2. `mensagem` (MSG001, MSG002, etc.)

**Formato no prompt:**
```markdown
### MENSAGEM [MSG001]

**Fale:**

"[conteúdo]"
```

**Dados do banco:**
- `content`: Texto entre aspas

### 3. `aguardar` (AG001, AG002, etc.)

**Formato no prompt:**
```markdown
### AGUARDAR [AG001]

**Escute a resposta do lead.** 
Salvar resposta do lead em: `{{nome_da_variavel}}`

**Depois:** Va para [PRÓXIMO_BLOCO]
```

**Dados do banco:**
- `content`: Texto após "**Escute..." (opcional)
- `variable_name`: Nome da variável entre `{{}}`
- `next_block_key`: Próximo bloco

### 4. `caminhos` (CAM001, CAM002, etc.)

**Formato no prompt:**
```markdown
### CAMINHOS [CAM001]

**Analisando:** `{{variavel}}`

**Pergunta:** [pergunta]

#### + Caminho 1: [label]
**Quando o lead disser:** `keyword1`, `keyword2`
**Fale:** "[resposta]"
**Depois:** [destino]

#### x Caminho 2: [label]
...

#### ? Não entendi (padrão/fallback)
**Quando nenhuma condição acima for atendida**
**Fale:** "[resposta]"
**Depois:** [destino]
```

**Dados do banco:**
- `analyze_variable`: Variável após "**Analisando:**"
- `content`: Pergunta após "**Pergunta:**"
- Rotas vêm de `flow_routes` onde `block_key` = este bloco

### 5. `encerrar` (ENC001, ENC002, etc.)

**Formato no prompt:**
```markdown
### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"[conteúdo]"
```

**Dados do banco:**
- `content`: Texto entre aspas

---

## 🎯 TAREFA PARA A IA

### O que você precisa fazer:

1. **Receber:**
   - Prompt completo original (`prompt_voz`)
   - `block_key` (ex: "ENC001")
   - `block_type` (ex: "encerrar")
   - Novo conteúdo (`content`)
   - Campos opcionais (`next_block_key`, `variable_name`, etc.)

2. **Identificar:**
   - Localizar a seção correspondente no prompt usando `block_key` e `block_type`
   - Encontrar os limites exatos da seção (início e fim)

3. **Formatar:**
   - Gerar a nova seção formatada corretamente usando os dados fornecidos
   - Manter o mesmo estilo de formatação do prompt original

4. **Substituir:**
   - Substituir APENAS a seção identificada
   - Manter TODO o resto do prompt (antes e depois)
   - Preservar separadores (`---`), quebras de linha, espaçamentos

5. **Retornar:**
   - Prompt completo atualizado
   - Sem explicações adicionais (apenas o prompt)

---

## ⚠️ REGRAS ABSOLUTAS

### ✅ DEVE FAZER:
- ✅ Manter TODO o texto antes da seção alvo
- ✅ Manter TODO o texto depois da seção alvo
- ✅ Manter formatação, espaçamentos, quebras de linha
- ✅ Substituir APENAS a seção específica do bloco
- ✅ Preservar separadores (`---`)
- ✅ Manter estilo de markdown original

### ❌ NÃO DEVE FAZER:
- ❌ Adicionar texto novo que não estava no original
- ❌ Remover nada além da seção alvo
- ❌ Reformatar outras seções
- ❌ Mudar estrutura geral do prompt
- ❌ Adicionar explicações ou comentários na resposta

---

## 📊 EXEMPLO COMPLETO DE PROCESSAMENTO

### Input:

**Prompt Original:**
```markdown
# PROMPT DO ASSISTENTE

## FLUXO DA CONVERSA

### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"Desculpe pelo engano. Até logo!"

---

### MENSAGEM [MSG001]

**Fale:**

"Olá! Como posso ajudar?"
```

**Dados do Bloco:**
```json
{
  "block_key": "ENC001",
  "block_type": "encerrar",
  "new_content": "Desculpe pelo engano. Até logooooo!"
}
```

### Processamento:

1. **Identificar:** Encontrar `### ENCERRAR [ENC001]: finalizar`
2. **Localizar limites:** 
   - Início: `### ENCERRAR [ENC001]: finalizar`
   - Fim: `---` (próximo separador) ou início de `### MENSAGEM`
3. **Formatar nova seção:**
   ```markdown
   ### ENCERRAR [ENC001]: finalizar

   **Fale antes de encerrar:**

   "Desculpe pelo engano. Até logooooo!"
   ```
4. **Substituir:** Trocar apenas essa seção
5. **Manter:** Todo o resto igual

### Output:

```markdown
# PROMPT DO ASSISTENTE

## FLUXO DA CONVERSA

### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"Desculpe pelo engano. Até logooooo!"

---

### MENSAGEM [MSG001]

**Fale:**

"Olá! Como posso ajudar?"
```

**Note:** Apenas a linha `"Desculpe pelo engano. Até logooooo!"` mudou. Todo o resto permaneceu exatamente igual.

---

## 🔧 CASOS ESPECIAIS

### 1. Bloco não encontrado
- Se não encontrar a seção no prompt original
- **Retornar o prompt original sem alterações**
- Não gerar erro, apenas manter como está

### 2. Múltiplas ocorrências
- Se houver múltiplas seções com o mesmo `block_key` (improvável, mas possível)
- Substituir a **primeira ocorrência** encontrada
- Ou a mais relevante (mais próxima do formato esperado)

### 3. Formato variado
- O prompt pode ter pequenas variações de formato
- Seja **tolerante** mas mantenha o estilo original
- Exemplo: `### ENCERRAR [ENC001]` vs `### ENCERRAR [ENC001]: finalizar`
- Ambos são válidos, use o que encontrar

### 4. DELETE de bloco
- Quando um bloco é deletado (`TG_OP = 'DELETE'`)
- Remover a seção inteira do prompt
- Manter separadores e formatação ao redor

---

## 📋 CHECKLIST DE IMPLEMENTAÇÃO

Quando implementar, verifique:

- [ ] Identifica corretamente a seção pelo `block_key` e `block_type`
- [ ] Localiza limites exatos da seção (início e fim)
- [ ] Formata nova seção corretamente conforme o tipo
- [ ] Substitui APENAS a seção identificada
- [ ] Mantém TODO o resto do prompt intacto
- [ ] Preserva separadores e formatação
- [ ] Trata casos especiais (não encontrado, múltiplas ocorrências)
- [ ] Retorna prompt completo sem explicações

---

## 🧪 TESTES SUGERIDOS

### Teste 1: Atualização simples
- Bloco: ENC001, tipo: encerrar
- Conteúdo original: "Até logo!"
- Novo conteúdo: "Até logooooo!"
- **Esperado:** Apenas essa linha muda

### Teste 2: Bloco no meio do prompt
- Bloco: MSG001, tipo: mensagem
- Está entre outras seções
- **Esperado:** Seções antes e depois permanecem iguais

### Teste 3: Bloco não encontrado
- Bloco: XXX999 que não existe no prompt
- **Esperado:** Prompt retornado sem alterações

### Teste 4: Formato variado
- Prompt tem `### ENCERRAR [ENC001]` (sem ": finalizar")
- **Esperado:** Ainda assim encontra e atualiza

### Teste 5: DELETE
- Deletar bloco ENC001
- **Esperado:** Seção removida, resto mantido

---

## 💡 DICAS DE IMPLEMENTAÇÃO

1. **Use busca case-insensitive** quando possível para encontrar seções
2. **Procure por padrões flexíveis** (com ou sem ": finalizar")
3. **Preserve espaçamentos** - não normalize espaços em branco
4. **Mantenha separadores** - `---` deve permanecer onde estava
5. **Teste com prompts reais** - use exemplos do banco de dados

---

## 📚 ESTRUTURA DE DADOS COMPLETA

### Relacionamentos:

```
assistentes (1) ←→ (N) flows
flows (1) ←→ (N) flow_blocks
flows (1) ←→ (N) flow_routes
flow_blocks (1) ←→ (N) flow_routes (onde flow_routes.block_key = flow_blocks.block_key)
```

### Fluxo de Dados:

```
Usuário edita bloco no Flow Editor
    ↓
Frontend envia UPDATE para flow_blocks
    ↓
Trigger PostgreSQL detecta mudança
    ↓
Busca assistente_id via flow_id
    ↓
Busca prompt_voz atual
    ↓
Chama IA para fazer patch cirúrgico
    ↓
IA retorna prompt atualizado
    ↓
UPDATE assistentes.prompt_voz
```

---

## ✅ RESULTADO ESPERADO

Ao final, você deve ter:

1. **Função Python** que recebe prompt + dados do bloco e retorna prompt atualizado
2. **Endpoint FastAPI** que expõe essa funcionalidade
3. **Integração** com trigger SQL (opcional, como fallback)
4. **Testes** que validam o comportamento

O sistema deve ser:
- ✅ **Robusto** - funciona mesmo com variações de formato
- ✅ **Preciso** - atualiza apenas a seção correta
- ✅ **Confiável** - não quebra o prompt original
- ✅ **Mantível** - fácil de entender e modificar

---

## 🎯 RESUMO FINAL

**Você está criando um sistema que:**

1. Recebe um prompt grande (5000+ caracteres)
2. Identifica uma seção específica (50-200 caracteres)
3. Atualiza APENAS aquela seção
4. Mantém TODO o resto intacto (4950+ caracteres)
5. Retorna o prompt completo atualizado

**É como fazer uma cirurgia em um texto:** precisa ser preciso, não pode afetar outras partes, e deve manter tudo funcionando perfeitamente.

---

**Boa sorte! 🚀**
