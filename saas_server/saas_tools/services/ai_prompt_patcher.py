"""
Serviço de Patch Inteligente de Prompts usando IA Generativa
Usa Claude/GPT para fazer atualizações cirúrgicas em prompts grandes
"""

import os
import logging
from typing import Dict, Any, Optional
import json

# Configurar logger
logger = logging.getLogger(__name__)

# Importar cliente da IA (Anthropic Claude ou OpenAI)
try:
    from anthropic import Anthropic
    ANTHROPIC_AVAILABLE = True
except ImportError:
    ANTHROPIC_AVAILABLE = False
    logger.warning("Anthropic SDK não disponível. Instale com: pip install anthropic")

try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    logger.warning("OpenAI SDK não disponível. Instale com: pip install openai")


class AIPromptPatcher:
    """Classe para fazer patch cirúrgico de prompts usando IA"""
    
    def __init__(self, provider: str = "anthropic"):
        """
        Inicializa o patcher com o provedor de IA
        
        Args:
            provider: "anthropic" (Claude) ou "openai" (GPT)
        """
        self.provider = provider
        
        if provider == "anthropic" and ANTHROPIC_AVAILABLE:
            api_key = os.getenv("ANTHROPIC_API_KEY")
            if not api_key:
                raise ValueError("ANTHROPIC_API_KEY não configurada")
            self.client = Anthropic(api_key=api_key)
            self.model = os.getenv("ANTHROPIC_MODEL", "claude-3-haiku-20240307")
        elif provider == "openai" and OPENAI_AVAILABLE:
            api_key = os.getenv("OPENAI_API_KEY")
            if not api_key:
                raise ValueError("OPENAI_API_KEY não configurada")
            self.client = openai.OpenAI(api_key=api_key)
            self.model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        else:
            raise ValueError(f"Provedor {provider} não disponível ou não configurado")
    
    def _build_system_prompt(self) -> str:
        """Constrói o prompt do sistema com as instruções para a IA"""
        return """Você é um especialista em processamento de texto e edição cirúrgica de documentos.

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

Retorne APENAS o prompt completo atualizado, sem explicações adicionais."""
    
    def _build_user_prompt(self, original_prompt: str, block_key: str, block_type: str, 
                          new_content: str, next_block_key: Optional[str] = None,
                          variable_name: Optional[str] = None) -> str:
        """Constrói o prompt do usuário com os dados específicos"""
        
        # Formatar a nova seção do bloco
        new_section = self._format_block_section(block_key, block_type, new_content, 
                                                next_block_key, variable_name)
        
        return f"""## PROMPT ORIGINAL (COMPLETO)

{original_prompt}

---

## BLOCO A ATUALIZAR

- **ID do Bloco:** {block_key}
- **Tipo:** {block_type}
- **Nova Seção Formatada:**

{new_section}

---

## TAREFA

Substitua APENAS a seção correspondente ao bloco `{block_key}` no prompt original acima, mantendo TODO o resto exatamente igual.

Retorne o prompt completo atualizado."""
    
    def _format_block_section(self, block_key: str, block_type: str, content: str,
                             next_block_key: Optional[str] = None,
                             variable_name: Optional[str] = None) -> str:
        """Formata uma seção de bloco no formato esperado"""
        
        if block_type == "primeira_mensagem":
            section = "### ABERTURA DA LIGACAO\n\n"
            section += "**Ao iniciar a ligacao, fale:**\n\n"
            section += f'"{content}"\n'
            if next_block_key:
                section += f'\n**Depois:** Va para [{next_block_key}]'
        
        elif block_type == "mensagem":
            section = f"### MENSAGEM [{block_key}]\n\n"
            section += "**Fale:**\n\n"
            section += f'"{content}"'
        
        elif block_type == "aguardar":
            section = f"### AGUARDAR [{block_key}]\n\n"
            section += "**Escute a resposta do lead.**\n"
            if variable_name:
                section += f'Salvar resposta do lead em: `{{{{{variable_name}}}}}`\n'
            if next_block_key:
                section += f'\n**Depois:** Va para [{next_block_key}]'
        
        elif block_type == "encerrar":
            section = f"### ENCERRAR [{block_key}]: finalizar\n\n"
            section += "**Fale antes de encerrar:**\n\n"
            section += f'"{content}"'
        
        elif block_type == "caminhos":
            section = f"### CAMINHOS [{block_key}]\n\n"
            if content:
                section += f"**{content}**\n"
            # Nota: Rotas seriam adicionadas aqui se necessário
        
        else:
            section = f"### [{block_key}]\n\n"
            section += content
        
        return section
    
    def patch_prompt(self, original_prompt: str, block_key: str, block_type: str,
                    new_content: str, next_block_key: Optional[str] = None,
                    variable_name: Optional[str] = None) -> str:
        """
        Faz patch cirúrgico no prompt usando IA
        
        Args:
            original_prompt: Prompt completo original
            block_key: ID do bloco (ex: ENC001, MSG001)
            block_type: Tipo do bloco (encerrar, mensagem, aguardar, etc.)
            new_content: Novo conteúdo do bloco
            next_block_key: Próximo bloco (opcional)
            variable_name: Nome da variável (opcional, para aguardar)
        
        Returns:
            Prompt atualizado com apenas a seção específica modificada
        """
        try:
            system_prompt = self._build_system_prompt()
            user_prompt = self._build_user_prompt(
                original_prompt, block_key, block_type, new_content,
                next_block_key, variable_name
            )
            
            logger.info(f"Fazendo patch do bloco {block_key} (tipo: {block_type}) usando {self.provider}")
            
            if self.provider == "anthropic":
                response = self.client.messages.create(
                    model=self.model,
                    max_tokens=8000,
                    system=system_prompt,
                    messages=[
                        {"role": "user", "content": user_prompt}
                    ]
                )
                updated_prompt = response.content[0].text.strip()
            
            elif self.provider == "openai":
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=[
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_prompt}
                    ],
                    temperature=0.1,  # Baixa temperatura para mais consistência
                    max_tokens=8000
                )
                updated_prompt = response.choices[0].message.content.strip()
            
            else:
                raise ValueError(f"Provedor {self.provider} não suportado")
            
            logger.info(f"✅ Patch concluído para bloco {block_key}")
            return updated_prompt
        
        except Exception as e:
            logger.error(f"❌ Erro ao fazer patch do bloco {block_key}: {str(e)}")
            # Em caso de erro, retornar o prompt original
            return original_prompt


def patch_prompt_with_ai(original_prompt: str, block_key: str, block_type: str,
                         new_content: str, provider: str = "anthropic",
                         next_block_key: Optional[str] = None,
                         variable_name: Optional[str] = None) -> str:
    """
    Função helper para fazer patch de prompt usando IA
    
    Args:
        original_prompt: Prompt completo original
        block_key: ID do bloco (ex: ENC001)
        block_type: Tipo do bloco (encerrar, mensagem, etc.)
        new_content: Novo conteúdo do bloco
        provider: "anthropic" ou "openai"
        next_block_key: Próximo bloco (opcional)
        variable_name: Nome da variável (opcional)
    
    Returns:
        Prompt atualizado
    """
    patcher = AIPromptPatcher(provider=provider)
    return patcher.patch_prompt(
        original_prompt, block_key, block_type, new_content,
        next_block_key, variable_name
    )
