# 🚨 Solução Rápida: Blocos Não Estão Sendo Salvos

## ⚠️ PROBLEMA IDENTIFICADO
O trigger SQL está causando timeout ao inserir blocos. **É OBRIGATÓRIO desabilitá-lo antes de salvar.**

## ✅ SOLUÇÃO EM 3 PASSOS

### Passo 1: Desabilitar Trigger no Supabase (OBRIGATÓRIO!)

1. Abra o **Supabase SQL Editor**
2. Execute este comando:

```sql
ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
```

3. Verifique se foi desabilitado:

```sql
SELECT 
    tgname,
    CASE 
        WHEN tgenabled = 'D' THEN '✅ DESABILITADO'
        WHEN tgenabled = 'O' THEN '❌ AINDA ATIVO!'
        ELSE 'Status desconhecido'
    END as status
FROM pg_trigger
WHERE tgname = 'trigger_sync_prompt_voz_on_block_change';
```

**Deve mostrar: `✅ DESABILITADO`**

### Passo 2: Reiniciar o Servidor

O servidor já foi reiniciado com as melhorias. Se precisar reiniciar novamente:

```bash
cd saas_server
./iniciar.sh
```

### Passo 3: Testar Novamente

1. Abra o Flow Editor
2. Edite um bloco
3. Clique em "Salvar"
4. **Deve funcionar agora!**

## 📋 Scripts Úteis

- **`supabase/CORRIGIR_AGORA.sql`** - Desabilita trigger e verifica status
- **`supabase/verificar_trigger_e_testar.sql`** - Diagnóstico completo

## 🔍 Se Ainda Não Funcionar

1. **Verifique os logs do servidor** - Procure por mensagens que começam com `save_flow:`
2. **Execute `CORRIGIR_AGORA.sql`** no Supabase
3. **Verifique se há blocos duplicados** (o script mostra isso)
4. **Envie os logs do servidor** para análise

## 💡 Por Que Isso Acontece?

O trigger `trigger_sync_prompt_voz_on_block_change` executa uma função pesada que atualiza o `prompt_voz` toda vez que um bloco é inserido. Isso causa timeout quando há múltiplos blocos.

**Solução temporária:** Desabilitar o trigger enquanto edita blocos.
**Solução futura:** Otimizar o trigger ou usar atualização assíncrona.

---

**Execute o Passo 1 AGORA e tente salvar novamente!**
