"""
Rebuilder para reconstruir o prompt_base a partir dos blocos e rotas salvos.
Faz o inverso do parser: pega blocos/rotas do banco e reconstrói o prompt estruturado.
"""
from typing import List, Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)


def rebuild_prompt_from_blocks(
    blocks: List[Dict[str, Any]],
    routes: List[Dict[str, Any]],
    intro_text: Optional[str] = None
) -> str:
    """
    Reconstrói o prompt_base estruturado a partir dos blocos e rotas.
    
    Args:
        blocks: Lista de blocos ordenados por order_index
        routes: Lista de rotas (cada rota tem block_key que referencia o bloco pai)
        intro_text: Texto introdutório opcional (antes de "## FLUXO DA CONVERSA")
    
    Returns:
        Prompt estruturado no formato que o parser espera
    """
    if not blocks:
        logger.warning("rebuild_prompt_from_blocks: Nenhum bloco fornecido")
        return intro_text or ""
    
    # Ordenar blocos por order_index
    sorted_blocks = sorted(blocks, key=lambda b: b.get("order_index") or 0)
    
    # Criar mapa de rotas por block_key
    # As rotas podem ter block_id (UUID) ou block_key (string como PM001)
    # Precisamos mapear block_id -> block_key primeiro
    block_id_to_key: Dict[str, str] = {}
    for block in sorted_blocks:
        block_id = block.get("id")
        block_key = block.get("block_key")
        if block_id and block_key:
            block_id_to_key[str(block_id)] = block_key
    
    routes_by_block_key: Dict[str, List[Dict[str, Any]]] = {}
    for route in routes:
        # Tentar block_key primeiro, depois block_id
        block_key = route.get("block_key")
        if not block_key:
            block_id = route.get("block_id")
            if block_id:
                block_key = block_id_to_key.get(str(block_id))
        
        if block_key:
            if block_key not in routes_by_block_key:
                routes_by_block_key[block_key] = []
            routes_by_block_key[block_key].append(route)
    
    # Ordenar rotas por ordem dentro de cada bloco
    for block_key in routes_by_block_key:
        routes_by_block_key[block_key].sort(key=lambda r: r.get("ordem") or 0)
    
    # Construir prompt
    prompt_parts = []
    
    # Parte 1: Texto introdutório (se fornecido)
    if intro_text:
        prompt_parts.append(intro_text.strip())
        prompt_parts.append("")
        prompt_parts.append("---")
        prompt_parts.append("")
    
    # Parte 2: Cabeçalho do fluxo
    prompt_parts.append("## FLUXO DA CONVERSA")
    prompt_parts.append("")
    
    # Parte 3: Blocos formatados
    for block in sorted_blocks:
        block_section = _format_block_for_prompt(block, routes_by_block_key.get(block.get("block_key"), []))
        prompt_parts.append(block_section)
        prompt_parts.append("")
        prompt_parts.append("---")
        prompt_parts.append("")
    
    return "\n".join(prompt_parts)


def _format_block_for_prompt(block: Dict[str, Any], routes: List[Dict[str, Any]]) -> str:
    """Formata um bloco no formato esperado pelo parser."""
    block_key = block.get("block_key", "")
    block_type = block.get("block_type", "")
    content = block.get("content", "").strip()
    next_block_key = block.get("next_block_key")
    variable_name = block.get("variable_name")
    analyze_variable = block.get("analyze_variable")
    
    lines = []
    
    # Determinar título da seção baseado no tipo
    if block_type == "primeira_mensagem":
        title = "### ABERTURA DA LIGACAO"
    elif block_type == "aguardar":
        title = f"### AGUARDAR [{block_key}]"
    elif block_type == "caminhos":
        title = f"### CAMINHOS [{block_key}]"
    elif block_type == "mensagem":
        title = f"### MENSAGEM [{block_key}]"
    elif block_type == "encerrar":
        title = f"### ENCERRAR [{block_key}]: finalizar"
    else:
        title = f"### [{block_key}]"
    
    lines.append(title)
    lines.append("")
    
    # Formatar conteúdo baseado no tipo
    if block_type == "primeira_mensagem":
        lines.append("**Ao iniciar a ligacao, fale:**")
        lines.append("")
        if content:
            lines.append(f'"{content}"')
        lines.append("")
        if next_block_key:
            lines.append(f"**Depois:** Va para [{next_block_key}]")
    
    elif block_type == "aguardar":
        if content:
            lines.append(f"**{content}**")
        else:
            lines.append("**Escute a resposta do lead.**")
        lines.append("")
        if variable_name:
            lines.append(f"Salvar resposta do lead em: `{{{{{variable_name}}}}}`")
        lines.append("")
        if next_block_key:
            lines.append(f"**Depois:** Va para [{next_block_key}]")
    
    elif block_type == "caminhos":
        if analyze_variable:
            lines.append(f"**Analisando:** `{{{{{analyze_variable}}}}}`")
            lines.append("")
        if content:
            lines.append(f"**{content}**")
        lines.append("")
        
        # Formatar rotas
        if routes:
            for route in routes:
                if route.get("is_fallback"):
                    continue  # Fallback vai no final
                route_section = _format_route(route)
                lines.append(route_section)
                lines.append("")
            
            # Fallback no final
            fallback_routes = [r for r in routes if r.get("is_fallback")]
            if fallback_routes:
                fallback = fallback_routes[0]  # Pegar primeiro fallback
                route_section = _format_route(fallback, is_fallback=True)
                lines.append(route_section)
    
    elif block_type == "mensagem":
        lines.append("**Fale:**")
        lines.append("")
        if content:
            lines.append(f'"{content}"')
    
    elif block_type == "encerrar":
        lines.append("**Fale antes de encerrar:**")
        lines.append("")
        if content:
            lines.append(f'"{content}"')
    
    return "\n".join(lines)


def _format_route(route: Dict[str, Any], is_fallback: bool = False) -> str:
    """Formata uma rota no formato esperado pelo parser."""
    label = route.get("label", "")
    keywords = route.get("keywords", [])
    response = route.get("response", "")
    destination_type = route.get("destination_type", "continue")
    destination_block_key = route.get("destination_block_key")
    
    lines = []
    
    # Determinar símbolo da rota
    if is_fallback:
        symbol = "?"
        title_prefix = "### ? Não entendi"
    else:
        # Tentar determinar símbolo pela cor ou ordem
        ordem = route.get("ordem", 0)
        if ordem == 1:
            symbol = "+"
        elif ordem == 2:
            symbol = "x"
        else:
            symbol = "+"
        title_prefix = f"#### {symbol} {label}"
    
    lines.append(title_prefix)
    lines.append("")
    
    # Keywords
    if keywords and not is_fallback:
        keywords_str = "`, `".join(keywords)
        lines.append(f"**Quando o lead disser:** `{keywords_str}`")
        lines.append("")
    elif is_fallback:
        lines.append("**Quando nenhuma condicao acima for atendida**")
        lines.append("")
    
    # Response
    if response:
        lines.append("**Fale:**")
        lines.append(f'"{response}"')
        lines.append("")
    
    # Destination
    if destination_type == "goto" and destination_block_key:
        if destination_block_key:
            lines.append(f"**Depois:** Continue para [{destination_block_key}]")
    elif destination_type == "end" and destination_block_key:
        lines.append(f"**Depois:** Encerre em [{destination_block_key}]")
    elif destination_type == "loop" and destination_block_key:
        max_attempts = route.get("max_loop_attempts", 2)
        lines.append(f"**Depois:** Volte para [{destination_block_key}] (maximo {max_attempts} tentativas)")
    elif destination_type == "continue" and destination_block_key:
        lines.append(f"**Depois:** Continue para [{destination_block_key}]")
    
    return "\n".join(lines)
