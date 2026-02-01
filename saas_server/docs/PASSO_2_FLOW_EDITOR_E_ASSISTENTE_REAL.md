# Passo 2: Flow Editor integrado e testar com assistente real

O Flow Editor agora é servido pelo próprio projeto e usa as APIs `/api/flows` para carregar e salvar. O prompt que você edita é o do **assistente** que está sendo editado.

---

## Como testar com um assistente real

1. **Tenant e assistente**
   - No seu fluxo normal, abra a **lista de assistentes** (onde você escolhe qual assistente editar).
   - Garanta que o **tenant_id** do cliente esteja definido (ex.: em `localStorage.tenant_id` ou na URL ao abrir o SaaS).
   - Clique em **Editar** no assistente que quiser (assistente **real** com `assistente_id` real).

2. **Abrir o Flow Editor**
   - Na página **Editar Assistente**, abra a aba **Flow Editor**.
   - O iframe carrega `/flow?assistente_id=...&tenant_id=...` com o `assistente_id` e o `tenant_id` do assistente que você está editando.

3. **O que aparece**
   - Se já existir um flow para esse assistente: carrega flow, prompt base e lista de blocos/rotas.
   - Se **não** existir: a API cria um flow novo para esse assistente (create_if_missing) e o editor mostra um flow vazio (só prompt base editável).

4. **Editar e salvar**
   - Altere o **Prompt base** (cabeçalho do flow).
   - Clique em **Salvar flow**.
   - O backend atualiza o flow e reconstrói o prompt. O texto que a **IA de voz** usa para esse assistente é o retornado por **GET /api/flows/by-assistant/{assistente_id}/prompt**.

5. **Ver o prompt montado**
   - No Flow Editor, use o botão **Ver prompt montado** para abrir em nova aba o texto completo que a IA de voz usa (equivalente a GET `/api/flows/by-assistant/{assistente_id}/prompt`).

---

## Resumo

- **Quem:** assistente real (o mesmo que você escolheu em “Editar Assistente”).
- **O que muda:** o flow desse assistente (prompt_base e, no save, blocos/rotas).
- **Qual prompt “vai mexer”:** o que a IA de voz usa = **GET /api/flows/by-assistant/{assistente_id}/prompt**.

Se o seu sistema de voz (ex.: VAPI) passar a usar esse endpoint com o `assistente_id` da ligação, o prompt que você editou aqui será o usado na ligação.
