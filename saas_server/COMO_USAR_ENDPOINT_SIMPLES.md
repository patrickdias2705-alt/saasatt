# ⚡ Como Usar o Endpoint Simples para Atualizar Blocos

## O Que Foi Implementado

### 1. Novo Endpoint Backend
**`PATCH /api/flows/{flow_id}/blocks/{block_key}`**

Atualiza **apenas um bloco específico** na tabela `flow_blocks` sem processar todos os blocos.

### 2. Salvamento Automático no Frontend

Quando você edita um bloco no **PropertiesPanel** (painel lateral direito), o sistema agora:
- ✅ Atualiza o bloco localmente (canvas)
- ✅ **Salva automaticamente** no banco usando o endpoint simples
- ✅ Apenas aquele bloco é atualizado na tabela `flow_blocks`

## Como Funciona

### Quando Você Edita um Bloco:

1. Você clica em um bloco no canvas
2. Edita o conteúdo no painel lateral (PropertiesPanel)
3. **Automaticamente** o sistema:
   - Atualiza o estado local
   - Chama `PATCH /api/flows/{flow_id}/blocks/{block_key}`
   - Apenas aquele bloco é atualizado no banco

### Quando Você Clica em "Salvar":

- Usa o endpoint completo `POST /api/flows/save`
- Processa todos os blocos (para sincronização completa)
- Útil quando você fez múltiplas mudanças

## Exemplo de Uso

### Editar Bloco "Encerrar" (ENC001):

1. Clique no bloco ENC001 no canvas
2. Edite o conteúdo no painel lateral
3. **Pronto!** O bloco é salvo automaticamente

**No console você verá:**
```
[FlowEditor] ⚡ Atualizando bloco único: ENC001 via endpoint simples
[FlowEditor] ✅ Bloco atualizado com sucesso
```

**No banco:**
- Apenas a linha do bloco ENC001 na tabela `flow_blocks` é atualizada
- Outros blocos permanecem intactos

## Vantagens

✅ **Simples**: Apenas atualiza o que você editou  
✅ **Rápido**: Não processa todos os blocos  
✅ **Automático**: Salva quando você edita (sem precisar clicar em "Salvar")  
✅ **Seguro**: Não há risco de perder outros blocos  
✅ **Direto**: Acesso direto à tabela `flow_blocks`  

## Quando Usar Cada Método

### Use Salvamento Automático (padrão):
- ✅ Quando você edita **um bloco específico**
- ✅ Funciona automaticamente ao editar no PropertiesPanel

### Use Botão "Salvar":
- ✅ Quando você fez **múltiplas mudanças** em vários blocos
- ✅ Quando você **deletou ou adicionou** blocos
- ✅ Quando quer **sincronizar tudo** de uma vez

## Próximos Passos

1. ✅ Backend criado e funcionando
2. ✅ Frontend adaptado para salvamento automático
3. ⏳ Rebuild do frontend necessário (`npm run build`)

## Rebuild do Frontend

Para aplicar as mudanças no frontend, você precisa rebuildar:

```bash
cd assist-tool-craft-main
npm run build
```

Depois, copie os arquivos gerados para o servidor ou reinicie o servidor que serve o frontend.
