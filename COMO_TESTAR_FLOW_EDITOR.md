# 🧪 COMO TESTAR O FLOW EDITOR

## ✅ SIM! Agora você pode testar tudo!

O sistema está conectado ao banco de dados. Todas as operações (adicionar, editar, deletar blocos) serão salvas no banco.

## 🎯 COMO TESTAR

### 1. Adicionar Blocos

1. No Flow Editor, clique no botão **"O que o agente faz?"** ou **"+"**
2. Escolha um tipo de bloco (Primeira mensagem, Mensagem, Aguardar, etc.)
3. O bloco aparecerá no canvas
4. Clique no bloco para editar o conteúdo
5. **IMPORTANTE:** Clique no botão **💾 Salvar** (ícone de salvar no topo)

### 2. Editar Blocos

1. Clique em um bloco existente no canvas
2. Edite o conteúdo no painel lateral direito
3. Clique em **💾 Salvar**

### 3. Deletar Blocos

1. Clique em um bloco para selecioná-lo
2. No painel lateral direito, clique no botão **🗑️ Excluir**
3. Confirme a exclusão
4. Clique em **💾 Salvar**

### 4. Verificar no Banco

Após salvar, execute este SQL no Supabase para verificar:

```sql
-- Ver blocos do seu assistente (substitua o assistente_id)
SELECT 
  fb.block_key,
  fb.block_type,
  fb.content,
  fb.next_block_key,
  fb.order_index
FROM flow_blocks fb
JOIN flows f ON f.id = fb.flow_id
WHERE f.assistente_id = 'SEU_ASSISTENTE_ID'
ORDER BY fb.order_index;
```

## 🔍 O QUE ACONTECE QUANDO VOCÊ SALVA

1. **Frontend** → Converte blocos do canvas para formato do banco
2. **API** → `/api/flows/save` recebe os dados
3. **Backend** → Deleta TODOS os blocos antigos do flow
4. **Backend** → Insere os NOVOS blocos no banco
5. **Backend** → Incrementa a versão do flow
6. **Sucesso** → Você vê uma mensagem "Fluxo salvo"

## 📝 IMPORTANTE

- ⚠️ **SEMPRE clique em Salvar** após fazer mudanças
- ⚠️ Se não salvar, as mudanças **NÃO** vão para o banco
- ⚠️ Ao salvar, **TODOS** os blocos antigos são deletados e os novos são inseridos
- ✅ O `prompt_base` (texto do prompt) também é salvo automaticamente

## 🧪 TESTE COMPLETO

### Teste 1: Adicionar um bloco
1. Adicione um bloco "Primeira mensagem"
2. Digite: "Olá! Teste de salvamento"
3. Clique em **💾 Salvar**
4. Verifique no banco se o bloco apareceu

### Teste 2: Editar um bloco
1. Clique no bloco que você criou
2. Mude o texto para: "Olá! Texto editado"
3. Clique em **💾 Salvar**
4. Verifique no banco se o conteúdo mudou

### Teste 3: Deletar um bloco
1. Clique no bloco
2. Clique em **🗑️ Excluir**
3. Confirme
4. Clique em **💾 Salvar**
5. Verifique no banco se o bloco foi removido

### Teste 4: Adicionar múltiplos blocos
1. Adicione: Primeira mensagem → Aguardar → Mensagem
2. Conecte eles (defina `nextBlock`)
3. Clique em **💾 Salvar**
4. Verifique no banco se todos apareceram com as conexões corretas

## 🔍 VERIFICAR LOGS

Abra o Console do navegador (F12) e procure por:
- `[FlowEditor] 🔄 Carregando flow...`
- `[FlowEditor] ✅ Dados recebidos do banco`
- `[FlowEditor] 📡 Chamando API: /api/flows/save`
- `Flow Editor Erro:` (se houver erro)

## ✅ SUCESSO

Se tudo funcionar:
- ✅ Blocos aparecem no canvas
- ✅ Você consegue editar e salvar
- ✅ Blocos aparecem no banco de dados
- ✅ Ao recarregar a página, os blocos continuam lá

## ❌ SE DER ERRO

1. Verifique o Console do navegador (F12)
2. Verifique os logs do servidor no terminal
3. Verifique se o `assistente_id` e `tenant_id` estão corretos na URL
4. Verifique se há blocos no banco com SQL
