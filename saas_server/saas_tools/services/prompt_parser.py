"""
Parser para extrair blocos e rotas do prompt_base estruturado.
Analisa o prompt_base e gera blocos/rotas automaticamente.
"""
import re
from typing import List, Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

# Padrões para identificar blocos no prompt
BLOCK_PATTERNS = {
    'primeira_mensagem': [
        r'\[PM\d+\]',
        r'PRIMEIRA MENSAGEM',
        r'ABERTURA DA LIGACAO',
        r'Ao iniciar a ligacao',
    ],
    'aguardar': [
        r'\[AG\d+\]',
        r'AGUARDAR',
        r'Escute',
        r'Salvar resposta',
    ],
    'caminhos': [
        r'\[CAM\d+\]',
        r'CAMINHOS',
        r'Analisando',
        r'É a pessoa certa',
    ],
    'mensagem': [
        r'\[MSG\d+\]',
        r'MENSAGEM',
        r'Fale:',
    ],
    'encerrar': [
        r'\[ENC\d+\]',
        r'ENCERRAR',
        r'finalizar',
    ],
}


def extract_block_key(text: str, block_type: str = '') -> Optional[str]:
    """Extrai o block_key (ex: PM001, AG001) do texto."""
    # Procurar por padrões como [PM001], [AG001], etc.
    pattern = r'\[([A-Z]{2,3}\d+)\]'
    matches = re.findall(pattern, text)
    if matches:
        return matches[0].upper()
    
    # Se não encontrar e temos um tipo, tentar gerar baseado no tipo
    if block_type:
        prefix_map = {
            'primeira_mensagem': 'PM',
            'aguardar': 'AG',
            'caminhos': 'CAM',
            'mensagem': 'MSG',
            'encerrar': 'ENC',
        }
        prefix = prefix_map.get(block_type, 'BLK')
        # Tentar encontrar número no texto
        num_match = re.search(r'(\d+)', text)
        if num_match:
            num = num_match.group(1)
            return f"{prefix}{num.zfill(3)}"
        # Se não encontrar número, usar 001 como padrão
        return f"{prefix}001"
    
    return None


def extract_block_content(text: str, block_type: str) -> str:
    """Extrai o conteúdo do bloco do texto."""
    # Para primeira_mensagem e mensagem: procurar texto entre aspas após "Fale:"
    if block_type in ['primeira_mensagem', 'mensagem']:
        # Primeiro, procurar por linhas que têm "Fale:" seguido de aspas na mesma linha ou próxima
        # Padrão: **Ao iniciar a ligacao, fale:**\n\n"texto aqui"
        patterns = [
            r'fale[:\s]*\n\s*"([^"]+)"',  # Fale: seguido de quebra de linha e aspas duplas - PRIORIDADE
            r'(?:fale|Fale)[^\"]*"([^"]+)"',  # Qualquer coisa entre "fale" e aspas (inclui quebras de linha)
            r'fale[:\s]+"([^"]+)"',  # Fale: seguido diretamente de aspas duplas
            r'fale[:\s]+""([^"]+)""',  # Aspas duplas duplas (markdown)
            r'fale[:\s]+\'([^\']+)\'',  # Aspas simples
        ]
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE | re.DOTALL | re.MULTILINE)
            if match:
                content = match.group(1).strip()
                content = content.strip('"\'')  # Remover aspas se ainda tiver
                if content and len(content) > 5:  # Ignorar conteúdo muito curto
                    print(f"🔍 [PARSER] extract_block_content: Encontrado conteúdo com padrão: {content[:50]}")
                    return content
        print(f"⚠️ [PARSER] extract_block_content: Não encontrou conteúdo para {block_type}")
    
    # Para aguardar: procurar descrição após "Escute" ou "Salvar"
    elif block_type == 'aguardar':
        # Procurar por "Escute" seguido de descrição
        match = re.search(r'Escute[^\.]+\.', text, re.IGNORECASE)
        if match:
            content = match.group(0).strip()
            return content
        # Fallback
        return "Escute a resposta do lead"
    
    # Para encerrar: procurar mensagem após "Fale antes de encerrar" ou "Fale:"
    elif block_type == 'encerrar':
        patterns = [
            r'fale.*encerrar[:\s]*\n\s*"([^"]+)"',  # Fale antes de encerrar: seguido de quebra de linha e aspas
            r'(?:fale|Fale)[^\"]*"([^"]+)"',  # Qualquer coisa entre "fale" e aspas (inclui quebras)
            r'fale.*encerrar[:\s]+"([^"]+)"',  # Fale antes de encerrar: seguido diretamente de aspas
            r'fale:\s*"([^"]+)"',  # Apenas "Fale:" com aspas duplas simples
        ]
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE | re.DOTALL)
            if match:
                content = match.group(1).strip()
                content = content.strip('"\'')
                if content and len(content) > 5:
                    print(f"🔍 [PARSER] extract_block_content (encerrar): Encontrado: {content[:50]}")
                    return content
        print(f"⚠️ [PARSER] extract_block_content (encerrar): Não encontrou conteúdo, usando fallback")
        return "Encerrar ligação"
    
    # Para caminhos: retornar a pergunta ou análise
    elif block_type == 'caminhos':
        # Procurar por "Analisando:" ou pergunta após "É a pessoa certa?"
        match = re.search(r'Analisando[^\n]+|É [^\?]+\?', text, re.IGNORECASE)
        if match:
            return match.group(0).strip()
        return "Analisar resposta"
    
    return ''


def extract_next_block(text: str) -> Optional[str]:
    """Extrai o próximo bloco (ex: AG001) do texto."""
    # Procurar por padrões como "Va para [AG001]", "Continue para [MSG001]", etc.
    patterns = [
        r'Va para\s+\[([A-Z]+\d+)\]',
        r'Continue para\s+\[([A-Z]+\d+)\]',
        r'Encerre em\s+\[([A-Z]+\d+)\]',
        r'Volte para\s+\[([A-Z]+\d+)\]',
        r'\[([A-Z]+\d+)\]',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group(1).upper()
    
    return None


def extract_variable_name(text: str) -> Optional[str]:
    """Extrai o nome da variável (ex: confirmacao_nome) do texto."""
    # Procurar por padrões como {{variavel}} ou "Salvar em: {{variavel}}"
    patterns = [
        r'Salvar.*em:\s*\{\{([^}]+)\}\}',
        r'\{\{([^}]+)\}\}',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            var = match.group(1).strip()
            # Remover chaves se ainda tiver
            var = var.replace('{{', '').replace('}}', '').strip()
            return var if var else None
    
    return None


def parse_prompt_base_to_blocks(prompt_base: str, flow_id: str, assistente_id: Optional[str], tenant_id: Optional[str]) -> tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """
    Analisa o prompt_base e gera blocos e rotas automaticamente.
    Retorna (blocks, routes) no formato para inserir no banco.
    """
    print(f"🔍 [PARSER] parse_prompt_base_to_blocks: Iniciando parse para flow_id={flow_id}")
    print(f"🔍 [PARSER] prompt_base length: {len(prompt_base) if prompt_base else 0}")
    
    blocks: List[Dict[str, Any]] = []
    routes: List[Dict[str, Any]] = []
    
    if not prompt_base or not prompt_base.strip():
        print(f"⚠️ [PARSER] prompt_base está vazio")
        return blocks, routes
    
    # REMOVER texto introdutório antes de "## FLUXO DA CONVERSA"
    # Tudo antes de "## FLUXO DA CONVERSA" é texto introdutório e deve ser ignorado
    fluxo_start = prompt_base.find('## FLUXO DA CONVERSA')
    if fluxo_start > 0:
        prompt_base = prompt_base[fluxo_start:]
        print(f"🔍 [PARSER] Removido {fluxo_start} caracteres de texto introdutório")
    
    # Dividir o prompt em seções principais (###)
    # Usar apenas ### para dividir, não --- (que pode estar dentro das seções)
    sections = re.split(r'\n###+', prompt_base)
    print(f"🔍 [PARSER] Dividido em {len(sections)} seções após remover introdutório")
    
    # Mapear block_key para índice de ordem
    block_order: Dict[str, int] = {}
    current_order = 1
    seen_block_keys: set = set()  # Evitar blocos duplicados
    
    # Pular seções que são apenas texto introdutório (sem blocos estruturados)
    for section in sections:
        section = section.strip()
        if not section:
            continue
        
        # Pular seções que são apenas texto introdutório
        section_upper = section.upper()
        
        # Pular seção "FLUXO DA CONVERSA" (é apenas um cabeçalho)
        # Mas só pular se NÃO tiver conteúdo de bloco (só o título)
        if 'FLUXO DA CONVERSA' in section_upper:
            # Se tem apenas o título sem conteúdo de bloco, pular
            section_without_title = section.replace('FLUXO DA CONVERSA', '').replace('##', '').strip()
            # Verificar se tem blocos ou seções dentro
            has_blocks = bool(re.search(r'\[(PM|AG|CAM|MSG|ENC)\d+\]', section))
            has_sections = 'ABERTURA' in section_upper or 'AGUARDAR' in section_upper or 'CAMINHOS' in section_upper
            if len(section_without_title) < 20 and not has_blocks and not has_sections:
                print(f"🔍 [PARSER] Pulando cabeçalho 'FLUXO DA CONVERSA' (sem conteúdo)")
                continue
            else:
                print(f"🔍 [PARSER] Seção 'FLUXO DA CONVERSA' tem conteúdo, processando...")
        
        # Pular seções que contêm apenas texto introdutório (explicações sobre Falar, Aguardar, etc)
        if ('FALAR' in section_upper and '=' in section and 'ABERTURA' not in section_upper and 'AGUARDAR' not in section_upper):
            print(f"🔍 [PARSER] Pulando seção introdutória: {section[:80]}")
            continue
        
        # Detectar tipo de bloco pelo TÍTULO DA SEÇÃO primeiro (prioridade)
        # IMPORTANTE: Verificar título ANTES de procurar block_key no texto
        # porque o texto pode conter referências a outros blocos (ex: "Va para [AG001]")
        block_key = None
        block_type_from_title = None
        
        if 'ABERTURA' in section_upper or 'Ao iniciar a ligacao' in section_upper:
            block_key = 'PM001'
            block_type_from_title = 'primeira_mensagem'
            print(f"🔍 [PARSER] ✅ Detectado primeira_mensagem (ABERTURA) pelo título, usando PM001")
        elif 'AGUARDAR' in section_upper or '[AG' in section_upper:
            block_key = extract_block_key(section, 'aguardar') or 'AG001'
            block_type_from_title = 'aguardar'
            print(f"🔍 [PARSER] Detectado aguardar pelo título, block_key={block_key}")
        elif 'CAMINHOS' in section_upper or '[CAM' in section_upper:
            block_key = extract_block_key(section, 'caminhos') or 'CAM001'
            block_type_from_title = 'caminhos'
            print(f"🔍 [PARSER] Detectado caminhos pelo título, block_key={block_key}")
        elif 'MENSAGEM' in section_upper or '[MSG' in section_upper:
            block_key = extract_block_key(section, 'mensagem') or 'MSG001'
            block_type_from_title = 'mensagem'
            print(f"🔍 [PARSER] Detectado mensagem pelo título, block_key={block_key}")
        elif 'ENCERRAR' in section_upper or '[ENC' in section_upper:
            block_key = extract_block_key(section, 'encerrar') or 'ENC001'
            block_type_from_title = 'encerrar'
            print(f"🔍 [PARSER] Detectado encerrar pelo título, block_key={block_key}")
        else:
            # Se não detectou pelo título, tentar extrair block_key do texto
            block_key = extract_block_key(section, '')
            print(f"🔍 [PARSER] Não detectado pelo título, block_key extraído do texto: {block_key}")
        
        if not block_key:
            print(f"⚠️ [PARSER] Seção não reconhecida (sem block_key): {section[:100]}")
            continue
        
        # Determinar tipo baseado no título (se detectado) ou no block_key
        if block_type_from_title:
            block_type = block_type_from_title
        else:
            # Fallback: determinar pelo block_key
            if block_key.startswith('PM'):
                block_type = 'primeira_mensagem'
            elif block_key.startswith('AG'):
                block_type = 'aguardar'
            elif block_key.startswith('CAM'):
                block_type = 'caminhos'
            elif block_key.startswith('MSG'):
                block_type = 'mensagem'
            elif block_key.startswith('ENC'):
                block_type = 'encerrar'
            else:
                print(f"⚠️ [PARSER] Não foi possível determinar block_type para {block_key}")
                continue
        
        # Evitar blocos duplicados
        if block_key in seen_block_keys:
            print(f"⚠️ [PARSER] Bloco {block_key} já foi processado, pulando duplicata")
            continue
        seen_block_keys.add(block_key)
        
        # Extrair conteúdo
        content = extract_block_content(section, block_type)
        next_block = extract_next_block(section)
        variable_name = extract_variable_name(section) if block_type == 'aguardar' else None
        analyze_variable = extract_variable_name(section) if block_type == 'caminhos' else None
        
        print(f"🔍 [PARSER] Bloco {block_key}: content extraído length={len(content) if content else 0}, next_block={next_block}")
        
        # Se não encontrou conteúdo, tentar extrair de forma mais simples
        if not content or len(content.strip()) < 5:
            # Para primeira_mensagem, procurar texto entre aspas após "fale:" ou "Ao iniciar"
            if block_type == 'primeira_mensagem':
                # Tentar padrões: "fale:" seguido de aspas duplas ou simples
                patterns = [
                    r'fale[:\s]+["\']([^"\']+)["\']',  # Aspas simples ou duplas
                    r'fale[:\s]+""([^"]+)""',  # Aspas duplas duplas (markdown)
                    r'fale[:\s]+"([^"]+)"',  # Aspas duplas simples
                ]
                for pattern in patterns:
                    match = re.search(pattern, section, re.IGNORECASE | re.DOTALL)
                    if match:
                        content = match.group(1).strip()
                        break
            
            # Para mensagem, procurar texto após "Fale:"
            elif block_type == 'mensagem':
                patterns = [
                    r'Fale:\s*["\']([^"\']+)["\']',  # Aspas simples ou duplas
                    r'Fale:\s*""([^"]+)""',  # Aspas duplas duplas
                    r'Fale:\s*"([^"]+)"',  # Aspas duplas simples
                    r'Fale:\s*([^\n]+)',  # Qualquer coisa após "Fale:"
                ]
                for pattern in patterns:
                    match = re.search(pattern, section, re.IGNORECASE | re.DOTALL)
                    if match:
                        content = match.group(1).strip()
                        # Limpar aspas se ainda tiver
                        content = content.strip('"\'')
                        if content:
                            break
            
            # Para aguardar, usar descrição do texto
            elif block_type == 'aguardar':
                # Procurar por "Escute" ou "Salvar"
                match = re.search(r'(Escute[^\.]+|Salvar[^\.]+)', section, re.IGNORECASE)
                if match:
                    content = match.group(1).strip()
                else:
                    content = "Escute a resposta do lead"
            
            # Para encerrar, procurar mensagem após "Fale antes de encerrar" ou "Fale:"
            elif block_type == 'encerrar':
                patterns = [
                    r'Fale.*encerrar[:\s]+["\']([^"\']+)["\']',  # Com "encerrar" no texto
                    r'Fale:\s*["\']([^"\']+)["\']',  # Apenas "Fale:"
                    r'Fale:\s*""([^"]+)""',  # Aspas duplas duplas
                    r'Fale:\s*"([^"]+)"',  # Aspas duplas simples
                ]
                for pattern in patterns:
                    match = re.search(pattern, section, re.IGNORECASE | re.DOTALL)
                    if match:
                        content = match.group(1).strip()
                        content = content.strip('"\'')
                        if content:
                            break
                if not content:
                    content = "Encerrar ligação"
        
        # Criar bloco
        block: Dict[str, Any] = {
            "flow_id": flow_id,
            "assistente_id": assistente_id,
            "tenant_id": tenant_id,
            "block_key": block_key,
            "block_type": block_type,
            "content": content or f"Bloco {block_key}",
            "next_block_key": next_block,
            "order_index": current_order,
            "position_x": 100,
            "position_y": current_order * 150,
            "tool_config": {},
            "end_metadata": {},
        }
        
        if variable_name:
            block["variable_name"] = variable_name
        
        if analyze_variable:
            block["analyze_variable"] = analyze_variable
        
        blocks.append(block)
        block_order[block_key] = current_order
        current_order += 1
        print(f"✅ [PARSER] Bloco criado: {block_key} ({block_type}), content length: {len(content)}")
        
        # Para caminhos, extrair rotas
        if block_type == 'caminhos':
            parsed_routes = extract_routes_from_section(section, block_key, flow_id, assistente_id, tenant_id)
            routes.extend(parsed_routes)
            print(f"✅ [PARSER] {len(parsed_routes)} rotas extraídas para {block_key}")
    
    print(f"✅ [PARSER] Parse completo: {len(blocks)} blocos, {len(routes)} rotas")
    return blocks, routes


def extract_routes_from_section(section: str, block_key: str, flow_id: str, assistente_id: Optional[str], tenant_id: Optional[str]) -> List[Dict[str, Any]]:
    """Extrai rotas de uma seção de caminhos."""
    routes: List[Dict[str, Any]] = []
    
    print(f"🔍 [PARSER] extract_routes: Processando seção para {block_key}")
    print(f"🔍 [PARSER] Seção completa (primeiros 500 chars):\n{section[:500]}")
    
    # Estratégia 1: Dividir por #### seguido de espaço e símbolo (+, x, ?)
    # Padrão: #### + Confirmou que é ele
    # Usar lookahead positivo para preservar o símbolo na seção
    route_sections = re.split(r'\n(?=####+\s*[+\-x?])', section)
    print(f"🔍 [PARSER] extract_routes: Dividido em {len(route_sections)} subseções por '#### +/x/?' (com lookahead)")
    
    # Se encontrou mais de 1 seção, a primeira é o cabeçalho (antes do primeiro ####)
    # As outras são as rotas (já começam com #### +/x/?)
    if len(route_sections) > 1:
        # Manter apenas as rotas (pular cabeçalho)
        route_sections = [''] + route_sections[1:]
        print(f"🔍 [PARSER] extract_routes: {len(route_sections)-1} rotas encontradas com #### +/x/?")
    
    # Estratégia 2: Se não encontrou, tentar dividir apenas por ####
    if len(route_sections) <= 1:
        route_sections = re.split(r'\n####+', section)
        print(f"🔍 [PARSER] extract_routes: Dividido em {len(route_sections)} subseções por '####' simples")
    
    # Estratégia 3: Se ainda não encontrou, dividir por linhas que começam com +, x, ?
    if len(route_sections) <= 1:
        # Procurar por linhas que começam com símbolos de rota (+, x, ?)
        # Padrão: linha que começa com símbolo seguida de múltiplas linhas até encontrar outro símbolo ou fim
        route_lines = []
        lines = section.split('\n')
        current_route = []
        for line in lines:
            line_stripped = line.strip()
            # Se a linha começa com símbolo de rota (pode ter espaços antes), iniciar nova rota
            if re.match(r'^\s*[+\-x?]', line_stripped):
                if current_route:
                    route_lines.append('\n'.join(current_route))
                current_route = [line]
            elif current_route:
                current_route.append(line)
        if current_route:
            route_lines.append('\n'.join(current_route))
        
        if route_lines:
            print(f"🔍 [PARSER] extract_routes: Encontradas {len(route_lines)} rotas por símbolos (+, x, ?)")
            route_sections = [''] + route_lines  # Adicionar cabeçalho vazio
    
    for idx, route_section in enumerate(route_sections[1:], 1):  # Pular o cabeçalho
        route_section = route_section.strip()
        if not route_section:
            continue
        
        print(f"🔍 [PARSER] Processando rota {idx}: {route_section[:100]}")
        
        # Detectar tipo de rota baseado no símbolo inicial
        # Pode começar com: +, x, X, ?, ou #### +, #### x, etc.
        is_fallback = False
        route_symbol = ''
        route_section_clean = route_section.strip()
        
        # Verificar se começa com #### seguido de símbolo
        symbol_match = re.match(r'^####+\s*([+\-x?])', route_section_clean)
        if symbol_match:
            route_symbol = symbol_match.group(1)
        elif route_section_clean.startswith('?'):
            route_symbol = '?'
        elif route_section_clean.startswith('+'):
            route_symbol = '+'
        elif route_section_clean.startswith('x') or route_section_clean.startswith('X'):
            route_symbol = 'x'
        
        if route_symbol == '?':
            is_fallback = True
        
        # Verificar também por texto
        if not is_fallback:
            is_fallback = (
                'fallback' in route_section.lower() or 
                'não entendi' in route_section.lower() or 
                'nao entendi' in route_section.lower() or
                'Quando nenhuma' in route_section
            )
        
        # Extrair label (primeira linha após símbolo)
        # Padrão: #### + Confirmou que é ele
        # Ou: + Confirmou que é ele
        label_match = None
        
        # Tentar padrão: #### + Label ou + Label
        label_patterns = [
            r'^####+\s*[+\-x?]\s*([^:\n]+?)(?:\n|$)',  # #### + Label
            r'^[+\-x?]\s*([^:\n]+?)(?:\n|$)',  # + Label
            r'^[+\-x?✅❌]\s*([^:\n]+?)(?:\n|$)',  # + Label (com emoji)
        ]
        
        for pattern in label_patterns:
            label_match = re.search(pattern, route_section, re.MULTILINE)
            if label_match:
                break
        
        if not label_match:
            # Tentar pegar primeira linha não vazia que não seja markdown
            lines = route_section.split('\n')
            for line in lines:
                line = line.strip()
                if line and not line.startswith('**') and not line.startswith('Quando') and not line.startswith('####'):
                    # Remover símbolos do início
                    line_clean = re.sub(r'^[+\-x?✅❌####\s]+', '', line)
                    if line_clean:
                        label_match = re.search(r'^(.+?)(?:\n|$)', line_clean)
                        break
        
        label = label_match.group(1).strip() if label_match else f"Caminho {idx}"
        # Limpar label de símbolos, markdown e espaços extras
        label = re.sub(r'^[+\-x?✅❌####\s]+', '', label).strip()
        label = re.sub(r'\*\*', '', label).strip()
        label = label.strip('"\'')  # Remover aspas se houver
        
        # Extrair keywords
        keywords_match = re.search(r'Quando.*disser[:\s]+([^\n]+)', route_section, re.IGNORECASE)
        keywords = []
        if keywords_match:
            keywords_str = keywords_match.group(1)
            # Extrair palavras entre backticks ou aspas simples
            keyword_matches = re.findall(r'`([^`]+)`|["\']([^"\']+)["\']', keywords_str)
            keywords = [k[0] or k[1] for k in keyword_matches if k[0] or k[1]]
            # Se não encontrou entre aspas, tentar separar por vírgula
            if not keywords:
                keywords = [k.strip() for k in keywords_str.split(',') if k.strip()]
        
        # Extrair resposta (suporta aspas duplas duplas "")
        response_patterns = [
            r'Fale:\s*""([^"]+)""',  # Aspas duplas duplas (markdown)
            r'Fale:\s*"([^"]+)"',  # Aspas duplas simples
            r'Fale:\s*\'([^\']+)\'',  # Aspas simples
            r'Fale:\s*([^\n]+)',  # Qualquer coisa após "Fale:"
        ]
        response = ''
        for pattern in response_patterns:
            response_match = re.search(pattern, route_section, re.IGNORECASE | re.DOTALL)
            if response_match:
                response = response_match.group(1).strip()
                response = response.strip('"\'')  # Remover aspas se ainda tiver
                if response:
                    break
        
        # Extrair destino
        destination_block = extract_next_block(route_section)
        destination_type = 'continuar'
        if 'encerrar' in route_section.lower() or 'Encerre' in route_section or 'Encerre em' in route_section:
            destination_type = 'encerrar'
        elif 'volte' in route_section.lower() or 'loop' in route_section.lower() or 'Volte para' in route_section:
            destination_type = 'loop'
        
        # Cor baseada no tipo
        color = '#6b7280'  # Cinza padrão
        if '✅' in route_section or 'confirmou' in route_section.lower() or '+' in route_section[:5]:
            color = '#22c55e'  # Verde
        elif '❌' in route_section or ('não' in route_section.lower() and 'é' in route_section.lower()) or 'x' in route_section[:5]:
            color = '#ef4444'  # Vermelho
        
        route: Dict[str, Any] = {
            "flow_id": flow_id,
            "assistente_id": assistente_id,
            "tenant_id": tenant_id,
            "block_key": block_key,  # Será convertido para block_id depois
            "route_key": f"{block_key}_{'fallback' if is_fallback else f'route_{idx}'}",
            "label": label,
            "ordem": 999 if is_fallback else idx,
            "cor": color,
            "keywords": keywords,
            "response": response,
            "destination_type": destination_type,
            "destination_block_key": destination_block,
            "max_loop_attempts": 2,
            "is_fallback": is_fallback,
        }
        
        routes.append(route)
    
    return routes
