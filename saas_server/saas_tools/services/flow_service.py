"""
Flow Service: CRUD operations for flows, blocks, and routes.
Includes automatic block generation from prompt_base when flow is empty.
"""
import logging
import re
from typing import Dict, Any, List, Optional

from saas_tools.services.supabase_service import supabase_service
from saas_tools.services.prompt_parser import parse_prompt_base_to_blocks
from saas_tools.services.flow_ai_analyzer import analyze_prompt_with_ai

logger = logging.getLogger(__name__)


def get_flow(flow_id: str) -> Optional[Dict[str, Any]]:
    """Get flow by ID."""
    try:
        client = supabase_service._require_client()
        resp = client.table("flows").select("*").eq("id", flow_id).limit(1).execute()
        if resp.data:
            return resp.data[0]
        return None
    except Exception as e:
        logger.error("get_flow: Erro ao buscar flow %s: %s", flow_id, e)
        return None


def get_flow_by_assistant(assistente_id: str) -> Optional[Dict[str, Any]]:
    """Get flow linked to an assistant."""
    try:
        client = supabase_service._require_client()
        resp = (
            client.table("flows")
            .select("*")
            .eq("assistente_id", assistente_id)
            .limit(1)
            .execute()
        )
        if resp.data:
            return resp.data[0]
        return None
    except Exception as e:
        logger.error("get_flow_by_assistant: Erro ao buscar flow para assistente %s: %s", assistente_id, e)
        return None


def get_flow_blocks(flow_id: str) -> List[Dict[str, Any]]:
    """Get all blocks for a flow."""
    try:
        client = supabase_service._require_client()
        # ⭐ IMPORTANTE: Incluir routes_data (JSONB) nos blocos de caminhos
        # ⚠️ EXPLICITAMENTE selecionar routes_data para garantir que vem
        try:
            # ⭐ EXPLICITAMENTE incluir routes_data no SELECT para garantir que vem
            resp = (
                client.table("flow_blocks")
                .select("*, routes_data")  # ⭐ EXPLICITAMENTE incluir routes_data
                .eq("flow_id", flow_id)
                .order("order_index")
                .execute()
            )
            blocks = resp.data or []
            logger.info("get_flow_blocks: ✅ Query executada, retornados %d blocos", len(blocks))
            
            # 🔍 DEBUG: Verificar se routes_data está presente nos blocos retornados
            if blocks:
                sample_block = blocks[0]
                logger.info("get_flow_blocks: 🔍 Exemplo de bloco retornado - propriedades: %s", list(sample_block.keys()))
                if "routes_data" in sample_block:
                    logger.info("get_flow_blocks: ✅ routes_data está presente nos blocos retornados")
                else:
                    logger.warning("get_flow_blocks: ⚠️ routes_data NÃO está presente nos blocos retornados!")
        except Exception as e:
            logger.error("get_flow_blocks: ❌ Erro ao buscar blocos: %s", str(e))
            import traceback
            logger.error("get_flow_blocks: Traceback: %s", traceback.format_exc())
            return []
        
        # 🔍 DEBUG: Log detalhado do que veio do banco ANTES de processar
        logger.info("get_flow_blocks: Retornados %d blocos do banco", len(blocks))
        caminhos_blocks = [b for b in blocks if b.get("block_type") == "caminhos"]
        if caminhos_blocks:
            logger.info("get_flow_blocks: 🔍 Encontrados %d blocos de caminhos", len(caminhos_blocks))
            for block in caminhos_blocks:
                block_key = block.get("block_key", "SEM_KEY")
                has_routes_data = "routes_data" in block
                routes_data_value = block.get("routes_data")
                routes_data_type = type(routes_data_value).__name__ if routes_data_value is not None else "None"
                routes_data_length = len(routes_data_value) if isinstance(routes_data_value, list) else "N/A"
                
                logger.info("get_flow_blocks: 🔍 Bloco %s:", block_key)
                logger.info("  - routes_data presente: %s", has_routes_data)
                logger.info("  - routes_data tipo: %s", routes_data_type)
                logger.info("  - routes_data length: %s", routes_data_length)
                logger.info("  - routes_data valor: %s", str(routes_data_value)[:200] if routes_data_value else "None")
                logger.info("  - TODAS propriedades do bloco: %s", list(block.keys()))
                
                # Se não tem routes_data mas deveria ter, tentar buscar diretamente
                if not has_routes_data:
                    logger.warning("get_flow_blocks: ⚠️ Bloco %s não tem routes_data! Tentando buscar diretamente...", block_key)
                    try:
                        block_id = block.get("id")
                        if block_id:
                            direct_resp = client.table("flow_blocks").select("routes_data").eq("id", block_id).single().execute()
                            if direct_resp.data and "routes_data" in direct_resp.data:
                                block["routes_data"] = direct_resp.data["routes_data"]
                                logger.info("get_flow_blocks: ✅ routes_data recuperado diretamente para bloco %s: %s", 
                                          block_key, str(block["routes_data"])[:100])
                            else:
                                logger.warning("get_flow_blocks: ⚠️ Busca direta também não retornou routes_data para bloco %s", block_key)
                    except Exception as e2:
                        logger.error("get_flow_blocks: ❌ Erro ao buscar routes_data diretamente: %s", str(e2))
        
        # ⭐ GARANTIR que blocos de caminhos sempre tenham routes_data (mesmo que vazio)
        for block in blocks:
            if block.get("block_type") == "caminhos":
                # Se routes_data não existe ou é None, definir como array vazio
                if "routes_data" not in block or block.get("routes_data") is None:
                    block["routes_data"] = []
                    logger.info("get_flow_blocks: Bloco %s não tinha routes_data, definido como []", block.get("block_key"))
        
        # 🔍 DEBUG: Verificar se routes_data está presente ANTES de retornar
        caminhos_blocks = [b for b in blocks if b.get("block_type") == "caminhos"]
        if caminhos_blocks:
            logger.info("get_flow_blocks: ✅ Encontrados %d blocos de caminhos", len(caminhos_blocks))
            for block in caminhos_blocks:
                block_key = block.get("block_key", "SEM_KEY")
                has_routes_data = "routes_data" in block
                routes_data_value = block.get("routes_data")
                routes_data_type = type(routes_data_value).__name__ if routes_data_value is not None else "None"
                routes_data_count = len(routes_data_value) if isinstance(routes_data_value, list) else 0
                
                logger.info("get_flow_blocks: 🔍 Bloco %s ANTES DE RETORNAR:", block_key)
                logger.info("  - has_routes_data: %s", has_routes_data)
                logger.info("  - routes_data_type: %s", routes_data_type)
                logger.info("  - routes_data_count: %d", routes_data_count)
                logger.info("  - routes_data_value: %s", str(routes_data_value)[:300] if routes_data_value else "None")
                logger.info("  - TODAS propriedades: %s", list(block.keys()))
                
                # ⚠️ VERIFICAÇÃO CRÍTICA: Se routes_data não está presente, tentar buscar novamente
                if not has_routes_data or routes_data_value is None:
                    logger.warning("get_flow_blocks: ⚠️ Bloco %s SEM routes_data antes de retornar! Tentando buscar novamente...", block_key)
                    try:
                        block_id = block.get("id")
                        if block_id:
                            direct_resp = client.table("flow_blocks").select("routes_data").eq("id", block_id).single().execute()
                            if direct_resp.data and "routes_data" in direct_resp.data:
                                block["routes_data"] = direct_resp.data["routes_data"]
                                logger.info("get_flow_blocks: ✅ routes_data recuperado para bloco %s: %d routes", 
                                          block_key, len(block["routes_data"]) if isinstance(block["routes_data"], list) else 0)
                    except Exception as e3:
                        logger.error("get_flow_blocks: ❌ Erro ao buscar routes_data novamente: %s", str(e3))
        
        # 🔍 DEBUG FINAL: Verificar CAM001 especificamente
        cam001_block = next((b for b in blocks if b.get("block_key") == "CAM001"), None)
        if cam001_block:
            logger.info("get_flow_blocks: 🔍 CAM001 FINAL:")
            logger.info("  - has_routes_data: %s", "routes_data" in cam001_block)
            logger.info("  - routes_data: %s", str(cam001_block.get("routes_data"))[:500])
            logger.info("  - routes_data_length: %s", len(cam001_block.get("routes_data", [])) if isinstance(cam001_block.get("routes_data"), list) else "N/A")
        
        return blocks
    except Exception as e:
        logger.error("get_flow_blocks: Erro ao buscar blocos para flow %s: %s", flow_id, e)
        return []


def get_flow_routes(flow_id: str) -> List[Dict[str, Any]]:
    """
    ⚠️ DEPRECATED: Routes agora estão em routes_data (JSONB) dentro de flow_blocks.
    Esta função retorna lista vazia para compatibilidade.
    Use get_flow_blocks() e leia routes_data de cada bloco.
    """
    # Routes agora estão em routes_data dentro de flow_blocks
    # Retornar vazio para não quebrar código que ainda espera routes separadas
    return []


def get_flow_complete(flow_id: str) -> Optional[Dict[str, Any]]:
    """
    Get flow with blocks and routes.
    If flow has no blocks but prompt_base has block structure, automatically generate blocks.
    """
    flow = get_flow(flow_id)
    if not flow:
        return None
    
    blocks = get_flow_blocks(flow_id)
    # ⚠️ DEPRECATED: routes agora estão em routes_data (JSONB) dentro de flow_blocks
    routes = []  # Não buscar mais de flow_routes separada
    
    # ⭐ VERIFICAR SE FALTAM ROUTES_DATA: Se tem blocos de caminhos mas não tem routes_data, gerar do prompt
    caminhos_blocks_without_routes = [b for b in blocks if b.get("block_type") == "caminhos" and (not b.get("routes_data") or len(b.get("routes_data", [])) == 0)]
    if blocks and caminhos_blocks_without_routes:
        # Verificar se há blocos de caminhos sem routes
        caminhos_blocks = [b for b in blocks if b.get("block_type") == "caminhos"]
        if caminhos_blocks:
            logger.info("get_flow_complete: ⚠️ Encontrados %d blocos de caminhos mas nenhuma route. Tentando gerar do prompt...", len(caminhos_blocks))
            assistente_id = flow.get("assistente_id")
            tenant_id = flow.get("tenant_id")
            
            # Buscar prompt_voz do assistente
            prompt_to_parse = ""
            if assistente_id:
                try:
                    client = supabase_service._require_client()
                    table_names = ["assistentes", "assistents", "assistants"]
                    for table_name in table_names:
                        try:
                            resp = client.table(table_name).select("prompt_voz").eq("id", assistente_id).limit(1).execute()
                            if resp.data and resp.data[0].get("prompt_voz"):
                                prompt_to_parse = resp.data[0].get("prompt_voz") or ""
                                break
                        except Exception:
                            continue
                except Exception as e:
                    logger.warning("get_flow_complete: Erro ao buscar prompt_voz para gerar routes: %s", e)
            
            # Se não encontrou prompt_voz, usar prompt_base do flow
            if not prompt_to_parse:
                prompt_to_parse = flow.get("prompt_base") or ""
            
            # Parsear apenas as routes do prompt
            if prompt_to_parse:
                try:
                    _, parsed_routes = parse_prompt_base_to_blocks(prompt_to_parse, flow_id, assistente_id, tenant_id)
                    logger.info("get_flow_complete: Parser retornou %d routes para inserir", len(parsed_routes))
                    
                    if parsed_routes:
                        client = supabase_service._require_client()
                        # Criar mapa block_key -> block_id
                        block_key_to_id = {b.get("block_key"): b.get("id") for b in blocks if b.get("block_key") and b.get("id")}
                        
                        routes_to_insert = []
                        for route in parsed_routes:
                            block_key = route.get("block_key")
                            block_id = block_key_to_id.get(block_key)
                            if block_id:
                                route_copy = route.copy()
                                route_copy["block_id"] = block_id
                                if "block_key" in route_copy:
                                    del route_copy["block_key"]
                                routes_to_insert.append(route_copy)
                        
                        # ⭐ NOVO: Inserir routes_data diretamente nos blocos (JSONB)
                        if routes_to_insert:
                            try:
                                # Agrupar routes por block_key
                                routes_by_block_key = {}
                                for route in routes_to_insert:
                                    block_key = route.get("block_key")
                                    if block_key:
                                        if block_key not in routes_by_block_key:
                                            routes_by_block_key[block_key] = []
                                        # Converter para formato routes_data
                                        route_data = {
                                            "route_key": route.get("route_key"),
                                            "label": route.get("label"),
                                            "ordem": route.get("ordem", 999),
                                            "cor": route.get("cor", "#6b7280"),
                                            "keywords": route.get("keywords", []),
                                            "response": route.get("response", ""),
                                            "destination_type": route.get("destination_type", "continuar"),
                                            "destination_block_key": route.get("destination_block_key"),
                                            "max_loop_attempts": route.get("max_loop_attempts", 2),
                                            "is_fallback": route.get("is_fallback", False)
                                        }
                                        routes_by_block_key[block_key].append(route_data)
                                
                                # Atualizar routes_data em cada bloco
                                for block_key, routes_data in routes_by_block_key.items():
                                    client.table("flow_blocks").update({
                                        "routes_data": routes_data
                                    }).eq("flow_id", flow_id).eq("block_key", block_key).execute()
                                
                                logger.info("get_flow_complete: ✅ %d routes inseridas em routes_data para %d blocos", 
                                          len(routes_to_insert), len(routes_by_block_key))
                                # Buscar blocos novamente (agora com routes_data)
                                blocks = get_flow_blocks(flow_id)
                            except Exception as e:
                                logger.error("get_flow_complete: Erro ao inserir routes_data: %s", e)
                except Exception as e:
                    logger.error("get_flow_complete: Erro ao parsear prompt para gerar routes: %s", e)
    
    # ⭐ VERIFICAR SE PRECISA USAR IA PARA ANALISAR PROMPT
    # Usar IA se:
    # 1. Não tem blocos OU
    # 2. Tem blocos mas faltam blocos dentro de rotas OU  
    # 3. Tem blocos de caminhos mas não têm routes_data completo
    assistente_id = flow.get("assistente_id")
    tenant_id = flow.get("tenant_id")
    
    # Buscar prompt_voz do assistente
    prompt_to_parse = ""
    if assistente_id:
        try:
            client = supabase_service._require_client()
            table_names = ["assistentes", "assistents", "assistants", "assistente", "assistant"]
            for table_name in table_names:
                try:
                    resp = client.table(table_name).select("prompt_voz").eq("id", assistente_id).limit(1).execute()
                    if resp.data and len(resp.data) > 0 and resp.data[0].get("prompt_voz"):
                        prompt_to_parse = resp.data[0].get("prompt_voz") or ""
                        logger.info("get_flow_complete: ✅ Buscado prompt_voz do assistente %s (tabela: %s), length: %d", 
                                   assistente_id, table_name, len(prompt_to_parse))
                        break
                except Exception:
                    continue
        except Exception as e:
            logger.warning("get_flow_complete: Erro ao buscar prompt_voz: %s", e)
    
    # Se não encontrou prompt_voz, usar prompt_base do flow como fallback
    if not prompt_to_parse or not prompt_to_parse.strip():
        prompt_to_parse = flow.get("prompt_base") or ""
        if prompt_to_parse:
            logger.info("get_flow_complete: Usando prompt_base do flow como fallback, length: %d", len(prompt_to_parse))
    
    # ⭐ SEMPRE USAR IA SE NÃO HÁ BLOCOS (primeira vez)
    # Depois, usar ordem salva do banco
    needs_ai_analysis = False
    if not blocks:
        needs_ai_analysis = True
        logger.info("get_flow_complete: ⚠️ Não há blocos. Usando IA para analisar prompt e gerar blocos automaticamente...")
    else:
        # Verificar se há blocos dentro de rotas faltando
        blocks_with_parent = [b for b in blocks if b.get("parentRouterId") or b.get("parent_router_id")]
        caminhos_blocks = [b for b in blocks if b.get("block_type") == "caminhos"]
        
        # Se tem blocos de caminhos mas não tem blocos dentro de rotas, pode estar faltando
        if caminhos_blocks and len(blocks_with_parent) == 0:
            # Verificar no prompt se há blocos dentro de rotas
            if prompt_to_parse and ("Depois:" in prompt_to_parse or "Va para" in prompt_to_parse):
                needs_ai_analysis = True
                logger.info("get_flow_complete: ⚠️ Blocos de caminhos existem mas não há blocos dentro de rotas. Usando IA para analisar...")
        
        # Verificar se routes_data está completo
        for caminhos_block in caminhos_blocks:
            routes_data = caminhos_block.get("routes_data", [])
            if not routes_data or len(routes_data) == 0:
                needs_ai_analysis = True
                logger.info("get_flow_complete: ⚠️ Bloco %s não tem routes_data completo. Usando IA para analisar...", caminhos_block.get("block_key"))
                break
    
    # ⭐ USAR IA PARA ANALISAR PROMPT E CRIAR/ATUALIZAR BLOCOS
    if needs_ai_analysis and prompt_to_parse and prompt_to_parse.strip():
        try:
            logger.info("get_flow_complete: 🤖 Chamando IA para analisar prompt completo...")
            ai_blocks = analyze_prompt_with_ai(prompt_to_parse, provider="openai")
            
            if ai_blocks and len(ai_blocks) > 0:
                logger.info("get_flow_complete: ✅ IA retornou %d blocos. Criando/atualizando no banco...", len(ai_blocks))
                
                client = supabase_service._require_client()
                
                # Criar mapa de blocos existentes por block_key
                existing_blocks_map = {b.get("block_key"): b for b in blocks if b.get("block_key")}
                
                # Processar blocos da IA
                for ai_block in ai_blocks:
                    block_key = ai_block.get("block_key")
                    if not block_key:
                        logger.warning("get_flow_complete: ⚠️ Bloco da IA sem block_key, pulando...")
                        continue
                    
                    # Preparar dados do bloco
                    # ⚠️ parentRouterId e routeId são apenas para frontend, não salvamos no banco
                    # Blocos dentro de rotas são identificados pela ordem e contexto
                    block_data = {
                        "flow_id": flow_id,
                        "assistente_id": assistente_id,
                        "tenant_id": tenant_id,
                        "block_key": block_key,
                        "block_type": ai_block.get("block_type", "mensagem"),
                        "content": ai_block.get("content", ""),
                        "next_block_key": ai_block.get("next_block_key"),
                        "variable_name": ai_block.get("variable_name"),
                        "analyze_variable": ai_block.get("analyze_variable"),
                        "order_index": ai_block.get("order_index", 0),
                        "position_x": 100,
                        "position_y": ai_block.get("order_index", 0) * 150,
                        "tool_config": {},
                        "end_metadata": {},
                    }
                    
                    # Adicionar routes_data se for bloco de caminhos
                    if ai_block.get("block_type") == "caminhos" and ai_block.get("routes_data"):
                        block_data["routes_data"] = ai_block.get("routes_data")
                    
                    # Remover None values e campos que não existem no banco
                    block_data = {k: v for k, v in block_data.items() if v is not None and k not in ["parentRouterId", "routeId"]}
                    
                    # Verificar se bloco já existe
                    existing_block = existing_blocks_map.get(block_key)
                    
                    if existing_block:
                        # Atualizar bloco existente
                        logger.info("get_flow_complete: 📝 Atualizando bloco existente %s", block_key)
                        client.table("flow_blocks").update(block_data).eq("id", existing_block.get("id")).execute()
                    else:
                        # Criar novo bloco
                        logger.info("get_flow_complete: ➕ Criando novo bloco %s", block_key)
                        client.table("flow_blocks").insert(block_data).execute()
                
                # Buscar blocos atualizados
                blocks = get_flow_blocks(flow_id)
                logger.info("get_flow_complete: ✅ Blocos criados/atualizados pela IA. Total: %d", len(blocks))
                
        except Exception as e:
            logger.error("get_flow_complete: ❌ Erro ao usar IA para analisar prompt: %s", e)
            import traceback
            logger.error("Traceback: %s", traceback.format_exc())
            # Continuar com parser normal como fallback
    
    # ⭐ FALLBACK: Parser normal se não usou IA ou IA falhou
    if not blocks and prompt_to_parse:
        # Verificar se prompt tem estrutura de blocos
        has_block_structure = bool(
            re.search(r'\[(PM|AG|CAM|MSG|ENC|FER)\d+\]', prompt_to_parse, re.IGNORECASE) or
            re.search(r'(PM|AG|CAM|MSG|ENC|FER)\d+', prompt_to_parse, re.IGNORECASE)
        )
        
        logger.info("get_flow_complete: Flow %s - prompt_to_parse length: %d, has_block_structure: %s", 
                   flow_id, len(prompt_to_parse), has_block_structure)
        
        if has_block_structure:
            logger.info("get_flow_complete: Flow %s não tem blocos mas prompt tem estrutura. Gerando blocos automaticamente...", flow_id)
            logger.info("get_flow_complete: Preview do prompt: %s", prompt_to_parse[:200] + "..." if len(prompt_to_parse) > 200 else prompt_to_parse)
            
            try:
                # Parse do prompt para gerar blocos e rotas
                logger.info("get_flow_complete: Chamando parse_prompt_base_to_blocks com prompt de %d caracteres", len(prompt_to_parse))
                parsed_blocks, parsed_routes = parse_prompt_base_to_blocks(
                    prompt_to_parse, flow_id, assistente_id, tenant_id
                )
                
                logger.info("get_flow_complete: Parser retornou %d blocos e %d rotas", len(parsed_blocks), len(parsed_routes))
                
                if parsed_blocks:
                    client = supabase_service._require_client()
                    
                    # ⚠️ NOTA: Se der timeout, desabilite o trigger manualmente:
                    # ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
                    logger.info("get_flow_complete: ⚠️ Se der timeout, execute no Supabase: ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;")
                    
                    # Inserir blocos em lotes menores para evitar timeout
                    logger.info("get_flow_complete: Inserindo %d blocos em lotes de 3...", len(parsed_blocks))
                    block_key_to_id = {}
                    
                    # Simplificar blocos antes de inserir (remover campos que podem causar problema)
                    simplified_blocks = []
                    for block in parsed_blocks:
                        simplified = {
                            "flow_id": block.get("flow_id"),
                            "assistente_id": block.get("assistente_id"),
                            "tenant_id": block.get("tenant_id"),
                            "block_key": block.get("block_key"),
                            "block_type": block.get("block_type"),
                            "content": block.get("content", ""),
                            "next_block_key": block.get("next_block_key"),
                            "variable_name": block.get("variable_name"),
                            "analyze_variable": block.get("analyze_variable"),
                            "order_index": block.get("order_index", 0),
                            "position_x": block.get("position_x", 100),
                            "position_y": block.get("position_y", 0),
                            "tool_config": block.get("tool_config") or {},
                            "end_metadata": block.get("end_metadata") or {},
                        }
                        # Remover None values
                        simplified = {k: v for k, v in simplified.items() if v is not None}
                        simplified_blocks.append(simplified)
                    
                    # Inserir em lotes de 3 (menor para evitar timeout)
                    batch_size = 3
                    for i in range(0, len(simplified_blocks), batch_size):
                        batch = simplified_blocks[i:i + batch_size]
                        try:
                            result = client.table("flow_blocks").insert(batch).execute()
                            logger.info("get_flow_complete: ✅ Lote %d-%d inserido (%d blocos)", i+1, min(i+batch_size, len(simplified_blocks)), len(batch))
                        except Exception as e:
                            logger.error("get_flow_complete: Erro ao inserir lote %d-%d: %s", i+1, min(i+batch_size, len(simplified_blocks)), str(e)[:200])
                            # Tentar inserir um por um neste lote
                            for single_block in batch:
                                try:
                                    client.table("flow_blocks").insert([single_block]).execute()
                                    logger.info("get_flow_complete: ✅ Bloco %s inserido individualmente", single_block.get("block_key"))
                                except Exception as e2:
                                    logger.error("get_flow_complete: ❌ Erro ao inserir bloco %s: %s", single_block.get("block_key"), str(e2)[:200])
                            continue
                    
                    # Buscar blocos inseridos para mapear block_key -> id
                    try:
                        resp = client.table("flow_blocks").select("id, block_key").eq("flow_id", flow_id).execute()
                        block_key_to_id = {row["block_key"]: row["id"] for row in (resp.data or [])}
                        logger.info("get_flow_complete: ✅ %d blocos mapeados com sucesso", len(block_key_to_id))
                    except Exception as e:
                        logger.error("get_flow_complete: Erro ao buscar blocos inseridos: %s", e)
                        block_key_to_id = {}
                    
                    # Atualizar rotas com block_id correto e inserir
                    if parsed_routes:
                        routes_to_insert = []
                        for route in parsed_routes:
                            block_id = block_key_to_id.get(route.get("block_key"))
                            if block_id:
                                route_copy = route.copy()
                                route_copy["block_id"] = block_id
                                if "block_key" in route_copy:
                                    del route_copy["block_key"]
                                routes_to_insert.append(route_copy)
                        
                        # ⭐ NOVO: Inserir routes_data diretamente nos blocos (JSONB)
                        if routes_to_insert:
                            # Agrupar routes por block_key e atualizar routes_data
                            routes_by_block_key = {}
                            for route in routes_to_insert:
                                block_key = route.get("block_key")
                                if block_key:
                                    if block_key not in routes_by_block_key:
                                        routes_by_block_key[block_key] = []
                                    route_data = {
                                        "route_key": route.get("route_key"),
                                        "label": route.get("label"),
                                        "ordem": route.get("ordem", 999),
                                        "cor": route.get("cor", "#6b7280"),
                                        "keywords": route.get("keywords", []),
                                        "response": route.get("response", ""),
                                        "destination_type": route.get("destination_type", "continuar"),
                                        "destination_block_key": route.get("destination_block_key"),
                                        "max_loop_attempts": route.get("max_loop_attempts", 2),
                                        "is_fallback": route.get("is_fallback", False)
                                    }
                                    routes_by_block_key[block_key].append(route_data)
                            
                            for block_key, routes_data in routes_by_block_key.items():
                                client.table("flow_blocks").update({
                                    "routes_data": routes_data
                                }).eq("flow_id", flow_id).eq("block_key", block_key).execute()
                    
                    # Buscar novamente após inserir (mesmo se alguns lotes falharam)
                    blocks = get_flow_blocks(flow_id)
                    routes = []  # ⚠️ DEPRECATED: routes agora em routes_data
                    
                    if blocks:
                        logger.info("✅ get_flow_complete: Gerados %d blocos e %d rotas automaticamente", len(blocks), len(routes))
                    else:
                        logger.warning("⚠️ get_flow_complete: Nenhum bloco foi inserido (pode ter dado timeout). Tentando inserir novamente em lotes menores...")
                        # Tentar inserir um bloco por vez como último recurso
                        for block in parsed_blocks[:3]:  # Apenas os primeiros 3 para não travar
                            try:
                                client.table("flow_blocks").insert([block]).execute()
                                logger.info("get_flow_complete: ✅ Bloco %s inserido individualmente", block.get("block_key"))
                            except Exception as e:
                                logger.error("get_flow_complete: Erro ao inserir bloco %s: %s", block.get("block_key"), e)
                        
                        # Buscar novamente
                        blocks = get_flow_blocks(flow_id)
                        routes = get_flow_routes(flow_id)
                        if blocks:
                            logger.info("✅ get_flow_complete: %d blocos inseridos após retry", len(blocks))
            except Exception as e:
                logger.error("get_flow_complete: Erro ao gerar blocos automaticamente: %s", e)
                import traceback
                logger.debug("Traceback: %s", traceback.format_exc())
                # Buscar blocos mesmo se deu erro (pode ter inserido alguns)
                blocks = get_flow_blocks(flow_id)
                routes = []  # ⚠️ DEPRECATED: routes agora em routes_data
                if blocks:
                    logger.info("get_flow_complete: Encontrados %d blocos após erro (alguns podem ter sido inseridos)", len(blocks))
        elif prompt_to_parse and not has_block_structure:
            logger.warning("get_flow_complete: Flow %s tem prompt (%d chars) mas NÃO tem estrutura de blocos detectada. Regex: %s", 
                          flow_id, len(prompt_to_parse), r'\[(PM|AG|CAM|MSG|ENC|FER)\d+\]')
            # Tentar buscar blocos de outras formas (ex: ### ENCERRAR [ENC001])
            alt_pattern = re.search(r'(PM\d+|AG\d+|CAM\d+|MSG\d+|ENC\d+|FER\d+)', prompt_to_parse)
            if alt_pattern:
                logger.info("get_flow_complete: Encontrado padrão alternativo: %s", alt_pattern.group())
        elif not prompt_to_parse:
            logger.warning("get_flow_complete: Flow %s não tem prompt_base nem prompt_voz para gerar blocos", flow_id)
    
    # ⭐ NOVO: Routes agora estão em routes_data (JSONB) dentro de flow_blocks
    return {
        "flow": flow,
        "blocks": blocks,  # Já contém routes_data para blocos de caminhos
        "routes": [],  # ⚠️ DEPRECATED: routes agora em routes_data dos blocos
    }


def list_flows_by_tenant(tenant_id: str) -> List[Dict[str, Any]]:
    """List all flows for a tenant."""
    try:
        client = supabase_service._require_client()
        resp = (
            client.table("flows")
            .select("*")
            .eq("tenant_id", tenant_id)
            .order("created_at", desc=True)
            .execute()
        )
        return resp.data or []
    except Exception as e:
        logger.error("list_flows_by_tenant: Erro ao listar flows para tenant %s: %s", tenant_id, e)
        return []


def create_flow(
    tenant_id: str,
    name: str,
    assistente_id: Optional[str] = None,
    prompt_base: Optional[str] = None,
    description: Optional[str] = None,
) -> Optional[Dict[str, Any]]:
    """Create a new flow."""
    try:
        client = supabase_service._require_client()
        data = {
            "tenant_id": tenant_id,
            "name": name,
            "prompt_base": prompt_base or "",
            "description": description,
            "version": 1,
        }
        if assistente_id:
            data["assistente_id"] = assistente_id
        
        logger.info("create_flow: Criando flow com dados: %s", {k: v for k, v in data.items() if k != "prompt_base"})
        
        resp = client.table("flows").insert(data).execute()
        
        # Se não retornou dados, buscar o flow recém-criado
        if resp.data and len(resp.data) > 0:
            logger.info("create_flow: ✅ Flow criado com sucesso: %s", resp.data[0].get("id"))
            return resp.data[0]
        else:
            # Tentar buscar pelo assistente_id ou tenant_id + name
            logger.warning("create_flow: Insert não retornou dados, buscando flow criado...")
            if assistente_id:
                flow = get_flow_by_assistant(assistente_id)
                if flow:
                    logger.info("create_flow: ✅ Flow encontrado após criação: %s", flow.get("id"))
                    return flow
            
            logger.error("create_flow: ❌ Não foi possível criar ou encontrar o flow")
            return None
    except Exception as e:
        logger.error("create_flow: Erro ao criar flow: %s", e)
        import traceback
        logger.debug("create_flow: Traceback: %s", traceback.format_exc())
        return None


def update_flow(flow_id: str, data: Dict[str, Any]) -> bool:
    """Update flow metadata."""
    try:
        client = supabase_service._require_client()
        client.table("flows").update(data).eq("id", flow_id).execute()
        return True
    except Exception as e:
        logger.error("update_flow: Erro ao atualizar flow %s: %s", flow_id, e)
        return False


def save_flow(payload) -> Dict[str, Any]:
    """
    Save flow blocks and routes.
    
    ESTRATÉGIA SEGURA: INSERT primeiro, DELETE depois (evita perda de dados se inserção falhar).
    - Insere blocos em lotes pequenos (2 por vez) para evitar timeout
    - Só deleta blocos antigos após inserção bem-sucedida
    - Incrementa version do flow
    
    ⚠️ IMPORTANTE: Desabilite o trigger antes de salvar:
    ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;
    """
    from saas_tools.models.schemas import SaveFlowPayload
    
    if isinstance(payload, dict):
        # Se recebeu dict, converter para SaveFlowPayload
        payload = SaveFlowPayload(**payload)
    
    flow_id = payload.flow_id
    blocks = payload.blocks
    routes = payload.routes

    flow = get_flow(flow_id)
    if not flow:
        return {"success": False, "version": 0, "error": "Flow não encontrado"}

    client = supabase_service._require_client()
    current_version = flow.get("version") or 0
    
    assistente_id = flow.get("assistente_id")
    tenant_id = flow.get("tenant_id")
    
    try:
        # ⚠️ VALIDAÇÃO: Verificar se há blocos antes de deletar
        if not blocks or len(blocks) == 0:
            logger.error("save_flow: ❌ NENHUM BLOCO recebido! Não vou deletar os blocos existentes para evitar perda de dados.")
            return {"success": False, "version": current_version, "error": "Nenhum bloco recebido. Não foi possível salvar."}
        
        # Verificar quantos blocos existem atualmente no banco
        existing_blocks_resp = client.table("flow_blocks").select("block_key").eq("flow_id", flow_id).execute()
        existing_count = len(existing_blocks_resp.data or [])
        logger.info("save_flow: 📊 Blocos existentes no banco: %d | Blocos recebidos: %d", existing_count, len(blocks))
        
        # Se tinha blocos e recebeu menos, avisar mas continuar (pode ser edição parcial)
        if existing_count > 0 and len(blocks) < existing_count:
            logger.warning("save_flow: ⚠️ ATENÇÃO: Tinha %d blocos, recebeu %d. Alguns blocos podem ser deletados!", existing_count, len(blocks))
            # Se recebeu menos de 50% dos blocos existentes, pode ser erro - não deletar
            if len(blocks) < (existing_count * 0.5):
                logger.error("save_flow: ❌ RECEBEU MENOS DE 50%% DOS BLOCOS! Não vou deletar para evitar perda de dados.")
                return {"success": False, "version": current_version, "error": f"Recebeu apenas {len(blocks)} blocos mas existem {existing_count} no banco. Possível erro no frontend."}
        
        # Log dos blocos recebidos
        logger.info("save_flow: 📦 Recebidos %d blocos para salvar", len(blocks))
        for idx, b in enumerate(blocks):
            logger.info("save_flow: Bloco[%d] - key=%s, type=%s, content='%s'", 
                       idx, b.block_key, b.block_type, (b.content or '')[:50])
        
        # Listar block_keys recebidos vs existentes
        received_keys = {b.block_key for b in blocks}
        existing_keys = {row["block_key"] for row in (existing_blocks_resp.data or [])}
        missing_keys = existing_keys - received_keys
        if missing_keys:
            logger.warning("save_flow: ⚠️ Blocos que existem mas NÃO foram recebidos: %s", list(missing_keys))
        
        # ⚠️ ESTRATÉGIA SEGURA: Inserir PRIMEIRO, depois deletar apenas os antigos que não estão na lista nova
        # Isso evita perda de dados se a inserção falhar
        
        block_key_to_id: Dict[str, str] = {}
        if blocks:
            # Log detalhado
            logger.info("save_flow: Recebidos %d blocos para salvar", len(blocks))
            for idx, b in enumerate(blocks):
                logger.info("save_flow: Bloco[%d] - key=%s, type=%s, content_length=%d", 
                           idx, b.block_key, b.block_type, len(b.content or ''))
            
            # Preparar dados para inserção
            rows = []
            for b in blocks:
                # Validação básica
                if not b.block_key or not b.block_key.strip():
                    logger.error("save_flow: ❌ Bloco sem block_key! Pulando...")
                    continue
                if not b.block_type or not b.block_type.strip():
                    logger.error("save_flow: ❌ Bloco %s sem block_type! Pulando...", b.block_key)
                    continue
                
                # Garantir que content não seja None (é NOT NULL no banco)
                content_value = b.content if b.content is not None else ""
                
                row = {
                    "flow_id": flow_id,
                    "block_key": b.block_key.strip(),
                    "block_type": b.block_type.strip(),
                    "content": content_value,  # Garantir que não seja None
                    "order_index": int(b.order_index) if b.order_index is not None else 0,
                    "position_x": float(b.position_x) if b.position_x is not None else 0.0,
                    "position_y": float(b.position_y) if b.position_y is not None else 0.0,
                }
                
                # Campos opcionais (só adicionar se não forem None)
                if assistente_id:
                    row["assistente_id"] = assistente_id
                if tenant_id:
                    row["tenant_id"] = tenant_id
                if b.variable_name:
                    row["variable_name"] = b.variable_name
                if b.timeout_seconds is not None:
                    row["timeout_seconds"] = b.timeout_seconds
                if b.analyze_variable:
                    row["analyze_variable"] = b.analyze_variable
                if b.tool_type:
                    row["tool_type"] = b.tool_type
                # tool_config e end_metadata devem ser dict ou None, nunca string vazia
                if b.tool_config and isinstance(b.tool_config, dict) and len(b.tool_config) > 0:
                    row["tool_config"] = b.tool_config
                elif b.tool_config is None or (isinstance(b.tool_config, dict) and len(b.tool_config) == 0):
                    row["tool_config"] = {}  # Valor padrão vazio como dict
                if b.end_type:
                    row["end_type"] = b.end_type
                if b.end_metadata and isinstance(b.end_metadata, dict) and len(b.end_metadata) > 0:
                    row["end_metadata"] = b.end_metadata
                elif b.end_metadata is None or (isinstance(b.end_metadata, dict) and len(b.end_metadata) == 0):
                    row["end_metadata"] = {}  # Valor padrão vazio como dict
                if b.next_block_key:
                    row["next_block_key"] = b.next_block_key
                
                # ⭐ NOVO: Adicionar routes_data se o bloco for do tipo caminhos
                if b.block_type == "caminhos" and routes:
                    # Agrupar routes por block_key
                    block_routes = [r for r in routes if r.block_key == b.block_key]
                    if block_routes:
                        routes_data = []
                        for r in block_routes:
                            routes_data.append({
                                "route_key": r.route_key or f"{b.block_key}_route_{len(routes_data) + 1}",
                                "label": r.label or "",
                                "ordem": r.ordem or len(routes_data) + 1,
                                "cor": r.cor or "#6b7280",
                                "keywords": r.keywords or [],
                                "response": r.response or "",
                                "destination_type": r.destination_type or "continuar",
                                "destination_block_key": r.destination_block_key,
                                "max_loop_attempts": r.max_loop_attempts or 2,
                                "is_fallback": r.is_fallback or False
                            })
                        row["routes_data"] = routes_data
                        logger.info("save_flow: Bloco %s preparado com %d routes em routes_data", b.block_key, len(routes_data))
                
                rows.append(row)
                
                # Log detalhado do primeiro bloco para debug
                if len(rows) == 1:
                    logger.info("save_flow: 🔍 Exemplo de dados preparados para inserção:")
                    logger.info("save_flow:   - flow_id: %s", row.get("flow_id"))
                    logger.info("save_flow:   - block_key: %s", row.get("block_key"))
                    logger.info("save_flow:   - block_type: %s", row.get("block_type"))
                    logger.info("save_flow:   - content length: %d", len(row.get("content", "")))
                    logger.info("save_flow:   - assistente_id: %s", row.get("assistente_id"))
                    logger.info("save_flow:   - tenant_id: %s", row.get("tenant_id"))
            
            # ⚡ MÉTODO SIMPLES E DIRETO: Usar UPSERT (UPDATE ou INSERT) para cada bloco
            # Sem comparações complexas, sem verificação de mudanças - apenas salva o que recebeu
            logger.info("save_flow: 📥 Salvando %d blocos usando método simples (UPSERT)...", len(rows))
            
            inserted_keys = set()
            updated_keys = set()
            
            # Processar cada bloco individualmente - método simples e direto
            for row in rows:
                block_key = row.get("block_key")
                if not block_key:
                    logger.error("save_flow: ❌ Bloco sem block_key! Pulando...")
                    continue
                
                # Validar dados básicos
                if "tool_config" in row and not isinstance(row["tool_config"], dict):
                    row["tool_config"] = {}
                if "end_metadata" in row and not isinstance(row["end_metadata"], dict):
                    row["end_metadata"] = {}
                
                try:
                    # Tentar UPDATE primeiro (se existe, atualiza; se não existe, falha silenciosamente)
                    update_result = client.table("flow_blocks").update(row).eq("flow_id", flow_id).eq("block_key", block_key).execute()
                    
                    if update_result.data and len(update_result.data) > 0:
                        # UPDATE funcionou - bloco existia
                        updated_keys.add(block_key)
                        block_key_to_id[block_key] = update_result.data[0]["id"]
                        logger.info("save_flow: ✅ Bloco %s atualizado", block_key)
                    else:
                        # UPDATE não retornou dados - pode não existir, tentar INSERT
                        logger.info("save_flow: ➕ Bloco %s não existe, inserindo...", block_key)
                        insert_result = client.table("flow_blocks").insert([row]).execute()
                        
                        if insert_result.data and len(insert_result.data) > 0:
                            inserted_keys.add(block_key)
                            block_key_to_id[block_key] = insert_result.data[0]["id"]
                            logger.info("save_flow: ✅ Bloco %s inserido", block_key)
                        else:
                            # Verificar se foi inserido mesmo sem retorno
                            check_resp = client.table("flow_blocks").select("id").eq("flow_id", flow_id).eq("block_key", block_key).limit(1).execute()
                            if check_resp.data:
                                block_key_to_id[block_key] = check_resp.data[0]["id"]
                                inserted_keys.add(block_key)
                                logger.info("save_flow: ✅ Bloco %s confirmado no banco", block_key)
                            else:
                                logger.warning("save_flow: ⚠️ Bloco %s não foi inserido nem atualizado", block_key)
                                
                except Exception as e:
                    error_str = str(e)
                    logger.error("save_flow: ❌ Erro ao salvar bloco %s: %s", block_key, error_str[:200])
                    
                    # Se for erro de duplicata no INSERT, tentar UPDATE novamente
                    if "duplicate" in error_str.lower() or "unique" in error_str.lower() or "23505" in error_str:
                        try:
                            update_retry = client.table("flow_blocks").update(row).eq("flow_id", flow_id).eq("block_key", block_key).execute()
                            if update_retry.data:
                                updated_keys.add(block_key)
                                block_key_to_id[block_key] = update_retry.data[0]["id"]
                                logger.info("save_flow: ✅ Bloco %s atualizado após erro de duplicata", block_key)
                        except Exception as e2:
                            logger.error("save_flow: ❌ Erro ao fazer UPDATE após duplicata: %s", str(e2)[:200])
            
            # Resumo do que foi salvo
            total_saved = len(inserted_keys) + len(updated_keys)
            logger.info("save_flow: 📊 Resumo: %d blocos inseridos, %d blocos atualizados, total processado: %d", 
                       len(inserted_keys), len(updated_keys), total_saved)
            
            if updated_keys:
                logger.info("save_flow: ✅ Blocos atualizados: %s", list(updated_keys)[:10])
            if inserted_keys:
                logger.info("save_flow: ✅ Blocos inseridos: %s", list(inserted_keys)[:10])
            
            # Verificar quantos blocos foram realmente salvos
            if not block_key_to_id or len(block_key_to_id) == 0:
                logger.error("save_flow: ❌ NENHUM bloco foi inserido após todas as tentativas!")
                logger.error("save_flow: 📊 Resumo: Tentamos inserir %d blocos, mas nenhum foi inserido com sucesso.", len(blocks))
                logger.error("save_flow: 🔍 Possíveis causas:")
                logger.error("save_flow:   1. ⚠️ TRIGGER AINDA ESTÁ ATIVO!")
                logger.error("save_flow:      Execute no Supabase: ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change;")
                logger.error("save_flow:   2. Erro de constraint (UNIQUE ou FOREIGN KEY)")
                logger.error("save_flow:   3. Campos obrigatórios faltando (content, block_key, block_type)")
                logger.error("save_flow:   4. Timeout do banco de dados")
                logger.error("save_flow: 💡 Verifique os logs acima para ver os erros específicos de cada tentativa de inserção.")
                logger.error("save_flow: 📋 Execute o script: supabase/CORRIGIR_AGORA.sql")
                return {
                    "success": False, 
                    "version": current_version, 
                    "error": "Erro ao inserir blocos. Nenhum bloco foi salvo. Os blocos antigos foram preservados. ⚠️ IMPORTANTE: Execute no Supabase SQL Editor: ALTER TABLE flow_blocks DISABLE TRIGGER trigger_sync_prompt_voz_on_block_change; Verifique os logs do servidor para detalhes."
                }
            
            if len(block_key_to_id) < len(blocks):
                missing = [b.block_key for b in blocks if b.block_key not in block_key_to_id]
                logger.warning("save_flow: ⚠️ Apenas %d de %d blocos foram inseridos. Blocos faltando: %s", 
                             len(block_key_to_id), len(blocks), missing)
                # Continuar mesmo assim, mas avisar
            
            logger.info("save_flow: ✅ %d blocos inseridos com sucesso. Agora deletando blocos antigos que não estão na lista nova...", len(block_key_to_id))
            
            # Agora que inserimos com sucesso, limpar duplicatas e deletar blocos antigos que não estão na lista nova
            new_block_keys = {b.block_key for b in blocks}
            try:
                # Buscar todos os blocos do flow (pode haver duplicatas temporárias)
                all_blocks_resp = client.table("flow_blocks").select("id, block_key, created_at").eq("flow_id", flow_id).order("created_at", desc=True).execute()
                all_blocks = all_blocks_resp.data or []
                
                # Agrupar por block_key e manter apenas o mais recente (deletar duplicatas antigas)
                seen_keys = {}
                duplicate_ids_to_delete = []
                for block in all_blocks:
                    key = block["block_key"]
                    if key in seen_keys:
                        # Este é uma duplicata, marcar para deletar
                        duplicate_ids_to_delete.append(block["id"])
                    else:
                        seen_keys[key] = block["id"]
                
                # Deletar duplicatas
                if duplicate_ids_to_delete:
                    logger.info("save_flow: 🗑️ Deletando %d blocos duplicados", len(duplicate_ids_to_delete))
                    client.table("flow_blocks").delete().in_("id", duplicate_ids_to_delete).execute()
                
                # Identificar blocos que precisam ser deletados (estão no banco mas não na lista nova)
                old_block_keys = set(seen_keys.keys())
                keys_to_delete = old_block_keys - new_block_keys
                
                if keys_to_delete:
                    ids_to_delete = [seen_keys[key] for key in keys_to_delete if key in seen_keys]
                    if ids_to_delete:
                        logger.info("save_flow: 🗑️ Deletando %d blocos antigos que não estão na lista nova: %s", len(keys_to_delete), list(keys_to_delete))
                        client.table("flow_blocks").delete().in_("id", ids_to_delete).execute()
                else:
                    logger.info("save_flow: ✅ Nenhum bloco antigo precisa ser deletado (todos estão na lista nova)")
            except Exception as e:
                logger.warning("save_flow: ⚠️ Erro ao limpar blocos antigos (continuando): %s", str(e)[:200])
            
            # ⚠️ DEPRECATED: Routes agora estão em routes_data (JSONB) dentro de flow_blocks
            # Não precisa deletar flow_routes separadamente
            logger.info("save_flow: ⚠️ Pulando deleção de flow_routes (routes agora em routes_data)")
            
            # Buscar IDs finais dos blocos inseridos (caso algum não tenha sido mapeado)
            try:
                final_resp = client.table("flow_blocks").select("id, block_key").eq("flow_id", flow_id).execute()
                for row in (final_resp.data or []):
                    if row["block_key"] not in block_key_to_id:
                        block_key_to_id[row["block_key"]] = row["id"]
                logger.info("save_flow: ✅ Mapeamento final: %d blocos mapeados", len(block_key_to_id))
            except Exception as e:
                logger.warning("save_flow: ⚠️ Erro ao buscar IDs finais: %s", str(e)[:200])
            
            # Verificação final: garantir que temos pelo menos alguns blocos inseridos
            if len(block_key_to_id) == 0:
                logger.error("save_flow: ❌ CRÍTICO: Nenhum bloco foi inserido após todas as tentativas!")
                return {"success": False, "version": current_version, "error": "Falha ao inserir blocos. Os blocos antigos foram preservados."}
            
            # ANTIGO CÓDIGO (removido - inserção em lote única que causava timeout):
            # try:
            #     insert_result = client.table("flow_blocks").insert(rows).execute()
            #     logger.info("save_flow: ✅ Tentativa de inserir %d blocos", len(rows))

        # 4. ⚠️ DEPRECATED: Routes agora estão em routes_data (JSONB) dentro de flow_blocks
        # Não precisa deletar/inserir em flow_routes separadamente
        logger.info("save_flow: ⚠️ Pulando inserção em flow_routes (routes agora em routes_data)")
        
        # 5. ⚠️ DEPRECATED: Routes agora estão em routes_data (JSONB) dentro de flow_blocks
        # Routes já foram salvas junto com os blocos durante a inserção acima
        logger.info("save_flow: ✅ Routes salvas em routes_data dos blocos (não precisa inserir em flow_routes)")
        
        # Código antigo removido - routes agora em routes_data
        # Routes já foram salvas junto com os blocos durante a inserção acima (linha ~600)

        # 5. REMOVIDO: Atualização de prompt_voz
        # Agora apenas atualizamos flow_blocks diretamente
        # O prompt_voz não é mais sincronizado automaticamente
        logger.info("save_flow: ✅ Blocos salvos em flow_blocks. prompt_voz não é mais atualizado automaticamente.")
        
        # 6. Incrementar version
        new_version = current_version + 1
        client.table("flows").update({"version": new_version}).eq("id", flow_id).execute()

        return {"success": True, "version": new_version}
    except Exception as e:
        import traceback
        error_str = str(e)
        error_full = traceback.format_exc()
        logger.error("save_flow: ❌ ERRO GERAL: %s", error_str)
        logger.error("save_flow: 📋 Traceback completo:\n%s", error_full)
        
        # Tentar preservar a versão atual
        try:
            current_version = flow.get("version") or 0 if flow else 0
        except:
            current_version = 0
        
        return {
            "success": False, 
            "version": current_version, 
            "error": f"Erro ao salvar flow: {error_str}. Verifique os logs do servidor para detalhes."
        }
