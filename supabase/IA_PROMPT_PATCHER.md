# 🤖 Sistema de Patch Inteligente de Prompts com IA

## 📋 Contexto do Problema

Atualmente, estamos usando funções SQL (PL/pgSQL) para fazer "patch cirúrgico" de prompts - atualizar apenas uma seção específica de um prompt grande sem regenerar tudo. O problema é que:

1. **Regex e string manipulation são frágeis** - pequenas variações de formato quebram a detecção
2. **Formato pode variar** - diferentes versões do prompt podem ter formatação ligeiramente diferente
3. **Manutenção difícil** - qualquer mudança no formato requer atualizar múltiplas funções SQL

## 🎯 Solução Proposta: IA Generativa para Parsing e Patching

Usar uma IA (Claude/GPT) para:
1. **Entender o contexto** do prompt completo
2. **Identificar a seção específica** que precisa ser atualizada
3. **Fazer o patch cirúrgico** mantendo todo o resto intacto
4. **Ser mais tolerante a variações** de formato

## 🏗️ Arquitetura

```
flow_blocks (UPDATE) 
    ↓
Trigger PostgreSQL
    ↓
Edge Function Supabase (ou API Python)
    ↓
Chama IA (Claude/GPT) com prompt estruturado
    ↓
IA retorna prompt atualizado
    ↓
UPDATE assistentes.prompt_voz
```

## 📝 Prompt para a IA

O prompt deve instruir a IA a:
1. Receber o prompt original completo
2. Receber o novo conteúdo do bloco específico
3. Identificar a seção correspondente no prompt original
4. Substituir APENAS aquela seção
5. Manter todo o resto exatamente igual

---

# PROMPT PARA A IA (Claude/GPT)

```
Você é um especialista em processamento de texto e edição cirúrgica de documentos.

## TAREFA
Você receberá:
1. Um prompt completo de uma IA de voz (formato Markdown)
2. Um bloco específico que precisa ser atualizado (com seu ID único)
3. O novo conteúdo desse bloco

Sua tarefa é fazer um "patch cirúrgico": substituir APENAS a seção correspondente ao bloco no prompt original, mantendo TODO o resto do prompt exatamente igual.

## REGRAS ABSOLUTAS
- ✅ MANTER: Todo o texto antes da seção alvo
- ✅ MANTER: Todo o texto depois da seção alvo  
- ✅ MANTER: Formatação, espaçamentos, quebras de linha
- ✅ SUBSTITUIR: Apenas a seção específica do bloco
- ❌ NÃO ADICIONAR: Texto novo que não estava no original
- ❌ NÃO REMOVER: Nada além da seção alvo
- ❌ NÃO REFORMATAR: Manter o estilo de formatação original

## FORMATO DOS BLOCOS

Os blocos seguem este padrão:

### PRIMEIRA MENSAGEM (PM001, PM002, etc.)
```
### ABERTURA DA LIGACAO

**Ao iniciar a ligacao, fale:**

"[conteúdo da mensagem]"

**Depois:** Va para [PRÓXIMO_BLOCO]
```

### MENSAGEM (MSG001, MSG002, etc.)
```
### MENSAGEM [MSG001]

**Fale:**

"[conteúdo da mensagem]"
```

### AGUARDAR (AG001, AG002, etc.)
```
### AGUARDAR [AG001]

**Escute a resposta do lead.** 
Salvar resposta do lead em: `{{nome_da_variavel}}`

**Depois:** Va para [PRÓXIMO_BLOCO]
```

### CAMINHOS (CAM001, CAM002, etc.)
```
### CAMINHOS [CAM001]

**Analisando:** `{{variavel}}`

[rotas e caminhos...]
```

### ENCERRAR (ENC001, ENC002, etc.)
```
### ENCERRAR [ENC001]: finalizar

**Fale antes de encerrar:**

"[conteúdo da mensagem]"
```

## EXEMPLO DE PATCH

**PROMPT ORIGINAL:**
```
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

**BLOCO A ATUALIZAR:**
- ID: ENC001
- Tipo: encerrar
- Novo conteúdo: "Desculpe pelo engano. Até logooooo!"

**RESULTADO ESPERADO:**
```
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

Note que APENAS a linha do conteúdo mudou, tudo mais permaneceu igual.

## INSTRUÇÕES DE PROCESSAMENTO

1. **IDENTIFICAR** a seção no prompt original usando o block_key (ex: ENC001, MSG001)
2. **LOCALIZAR** os limites exatos da seção (início e fim)
3. **SUBSTITUIR** apenas o conteúdo interno da seção
4. **PRESERVAR** separadores (---), quebras de linha, espaçamentos
5. **MANTER** a estrutura de markdown intacta

## CASOS ESPECIAIS

- Se o bloco não for encontrado: retorne o prompt original sem alterações
- Se houver múltiplas ocorrências: substitua a primeira (ou a mais relevante)
- Se o formato variar ligeiramente: seja tolerante mas mantenha o estilo original

## FORMATO DE RESPOSTA

Retorne APENAS o prompt completo atualizado, sem explicações adicionais.
```

---

## 🔧 Implementação

### Opção 1: Edge Function Supabase (TypeScript/Deno)

### Opção 2: API Python (FastAPI)

### Opção 3: Função PostgreSQL chamando HTTP (pg_net)

---

## 📊 Vantagens da Abordagem com IA

1. ✅ **Mais robusta** - tolera variações de formato
2. ✅ **Mais inteligente** - entende contexto, não apenas padrões
3. ✅ **Mais fácil de manter** - mudanças no formato não quebram o sistema
4. ✅ **Mais precisa** - identifica seções mesmo com formatação diferente

## ⚠️ Considerações

- **Custo**: Cada chamada à IA tem custo (mas pode ser baixo com modelos menores)
- **Latência**: Chamadas à IA são mais lentas que SQL puro
- **Confiabilidade**: Depende da disponibilidade da API da IA
- **Cache**: Pode cachear resultados para blocos que não mudaram
