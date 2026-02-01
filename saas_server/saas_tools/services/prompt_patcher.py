"""
Patcher para atualizar apenas seções específicas do prompt_voz do assistente.
Quando um bloco é modificado, atualiza apenas aquela seção no prompt original,
mantendo o resto do prompt intacto.
"""
import re
from typing import Dict, Any, Optional, List
import logging

logger = logging.getLogger(__name__)


def patch_prompt_block(
    original_prompt: str,
    block: Dict[str, Any],
    routes: List[Dict[str, Any]] = None
) -> str:
    """
    Atualiza apenas a seção de um bloco específico no prompt original.
    Mantém todo o resto do prompt intacto.
    
    Args:
        original_prompt: Prompt completo original do assistente
        block: Bloco modificado (com block_key, block_type, content, etc.)
        routes: Rotas do bloco (se for tipo 'caminhos')
    
    Returns:
        Prompt atualizado com apenas a seção do bloco modificada
    """
    if not original_prompt or not block:
        logger.warning("patch_prompt_block: Prompt ou bloco vazio")
        return original_prompt or ""
    
    block_key = block.get("block_key", "")
    block_type = block.get("block_type", "")
    
    if not block_key:
        logger.warning("patch_prompt_block: Bloco sem block_key")
        return original_prompt
    
    # Formatar a nova seção do bloco
    # Importar função de formatação do rebuilder
    try:
        from saas_tools.services.prompt_rebuilder import _format_block_for_prompt
        new_block_section = _format_block_for_prompt(block, routes or [])
    except ImportError:
        # Fallback: formatar manualmente se não conseguir importar
        logger.warning("patch_prompt_block: Não foi possível importar _format_block_for_prompt, usando formatação manual")
        new_block_section = _format_block_simple(block, routes or [])
    
    # Encontrar a seção do bloco no prompt original
    # Padrões para encontrar a seção baseado no tipo de bloco
    section_start = -1
    section_end = -1
    
    # Padrões específicos por tipo de bloco
    if block_type == "primeira_mensagem":
        pattern = r'###+\s*ABERTURA DA LIGACAO'
    elif block_type == "aguardar":
        pattern = rf'###+\s*AGUARDAR\s*\[{re.escape(block_key)}\]'
    elif block_type == "caminhos":
        pattern = rf'###+\s*CAMINHOS\s*\[{re.escape(block_key)}\]'
    elif block_type == "mensagem":
        pattern = rf'###+\s*MENSAGEM\s*\[{re.escape(block_key)}\]'
    elif block_type == "encerrar":
        pattern = rf'###+\s*ENCERRAR\s*\[{re.escape(block_key)}\][^\n]*'
    else:
        pattern = rf'###+\s*.*\[{re.escape(block_key)}\]'
    
    match = re.search(pattern, original_prompt, re.IGNORECASE | re.MULTILINE)
    if match:
        section_start = match.start()
        logger.info(f"patch_prompt_block: Seção do bloco {block_key} encontrada na posição {section_start}")
    else:
        logger.warning(f"patch_prompt_block: Seção do bloco {block_key} não encontrada com padrão: {pattern}")
    
    if section_start == -1:
        # Seção não encontrada, adicionar no final (antes do último --- se existir)
        logger.info(f"patch_prompt_block: Seção do bloco {block_key} não encontrada, adicionando no final")
        return _append_block_to_prompt(original_prompt, new_block_section)
    
    # Encontrar o fim da seção (próximo ### ou --- ou fim do texto)
    # Procurar pelo próximo ### ou --- após o início da seção
    remaining_text = original_prompt[section_start:]
    
    # Procurar pelo próximo ### (início de outra seção) ou --- (separador)
    # Começar a busca após os primeiros caracteres para evitar pegar o título atual
    search_start = min(100, len(remaining_text) - 1)
    next_section_match = re.search(r'\n###+', remaining_text[search_start:], re.MULTILINE)
    next_separator_match = re.search(r'\n---\s*\n', remaining_text[search_start:], re.MULTILINE)
    
    # Determinar onde termina a seção atual
    section_end = len(remaining_text)  # Default: até o fim do texto
    
    if next_section_match and next_separator_match:
        # Pegar o que vier primeiro (mas incluir o --- se ele vier antes do próximo ###)
        if next_separator_match.start() < next_section_match.start():
            # O separador vem primeiro, então a seção termina antes do separador
            section_end = section_start + search_start + next_separator_match.start()
        else:
            # O próximo ### vem primeiro, então a seção termina antes dele
            section_end = section_start + search_start + next_section_match.start()
    elif next_separator_match:
        # Só encontrou separador, terminar antes dele
        section_end = section_start + search_start + next_separator_match.start()
    elif next_section_match:
        # Só encontrou próximo ###, terminar antes dele
        section_end = section_start + search_start + next_section_match.start()
    
    # Substituir a seção
    before_section = original_prompt[:section_start].rstrip()
    section_content = original_prompt[section_start:section_end].rstrip()
    after_section = original_prompt[section_end:].lstrip()
    
    logger.debug(f"patch_prompt_block: section_start={section_start}, section_end={section_end}, section_length={section_end-section_start}")
    logger.debug(f"patch_prompt_block: section_content preview: {section_content[:150]}...")
    logger.debug(f"patch_prompt_block: after_section preview: {after_section[:50]}...")
    
    # Garantir que há separadores adequados
    if before_section and not before_section.endswith('\n'):
        before_section += '\n'
    
    # Montar o prompt atualizado
    updated_prompt = before_section + new_block_section
    
    # Adicionar separador e conteúdo após (preservar o --- se existir)
    if after_section.strip():
        # Se after_section começa com ---, manter; senão adicionar
        if not after_section.startswith('---'):
            updated_prompt += '\n---\n'
        updated_prompt += after_section
    
    logger.info(f"patch_prompt_block: Seção do bloco {block_key} atualizada no prompt (tamanho antes: {len(section_content)}, depois: {len(new_block_section)})")
    return updated_prompt


def _format_block_simple(block: Dict[str, Any], routes: List[Dict[str, Any]]) -> str:
    """Formatação simples de bloco (fallback)."""
    block_key = block.get("block_key", "")
    block_type = block.get("block_type", "")
    content = block.get("content", "").strip()
    
    if block_type == "encerrar":
        return f"### ENCERRAR [{block_key}]: finalizar\n\n**Fale antes de encerrar:**\n\n\"{content}\""
    elif block_type == "primeira_mensagem":
        return f"### ABERTURA DA LIGACAO\n\n**Ao iniciar a ligacao, fale:**\n\n\"{content}\""
    elif block_type == "aguardar":
        return f"### AGUARDAR [{block_key}]\n\n**Escute a resposta do lead.**"
    elif block_type == "mensagem":
        return f"### MENSAGEM [{block_key}]\n\n**Fale:**\n\n\"{content}\""
    elif block_type == "caminhos":
        return f"### CAMINHOS [{block_key}]\n\n**Analisando:** `{{{{confirmacao_nome}}}}`"
    else:
        return f"### [{block_key}]\n\n{content}"


def _append_block_to_prompt(prompt: str, block_section: str) -> str:
    """Adiciona um bloco no final do prompt."""
    prompt = prompt.rstrip()
    
    # Se não tem "## FLUXO DA CONVERSA", adicionar
    if "## FLUXO DA CONVERSA" not in prompt:
        prompt += "\n\n## FLUXO DA CONVERSA\n\n"
    
    # Adicionar o bloco
    if not prompt.endswith('\n'):
        prompt += '\n'
    
    prompt += block_section
    prompt += '\n---\n'
    
    return prompt


def patch_multiple_blocks(
    original_prompt: str,
    blocks: List[Dict[str, Any]],
    routes_by_block_key: Dict[str, List[Dict[str, Any]]]
) -> str:
    """
    Atualiza múltiplas seções de blocos no prompt original.
    Processa em ordem reversa para não afetar as posições dos outros blocos.
    
    Args:
        original_prompt: Prompt completo original
        blocks: Lista de blocos modificados
        routes_by_block_key: Mapa de rotas por block_key
    
    Returns:
        Prompt atualizado
    """
    updated_prompt = original_prompt
    
    # Processar em ordem reversa (do último para o primeiro)
    # para não afetar as posições dos blocos anteriores
    sorted_blocks = sorted(blocks, key=lambda b: b.get("order_index") or 0, reverse=True)
    
    for block in sorted_blocks:
        block_key = block.get("block_key")
        routes = routes_by_block_key.get(block_key, [])
        updated_prompt = patch_prompt_block(updated_prompt, block, routes)
    
    return updated_prompt
