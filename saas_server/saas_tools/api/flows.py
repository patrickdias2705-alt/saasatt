"""
Flow Editor API: list, get, create, save, update flows; get built prompt.
"""
from fastapi import APIRouter, HTTPException, Query
from typing import Dict, Any
import logging

from saas_tools.models.schemas import (
    FlowCreate,
    FlowUpdate,
    SaveFlowPayload,
    SaveFlowResult,
    FlowBlockUpsert,
)
from saas_tools.services import flow_service
from saas_tools.services import prompt_builder
from saas_tools.services.supabase_service import supabase_service

logger = logging.getLogger(__name__)

router = APIRouter(tags=["flows"])


def _save_block_routes(client, flow_id: str, block_key: str, routes: list, assistente_id: str, tenant_id: str) -> list:
    """
    Salva/atualiza as routes de um bloco específico.
    
    Estratégia: DELETE todas as routes antigas do bloco, depois INSERT as novas.
    Isso garante que routes removidas do canvas sejam deletadas do banco.
    """
    from saas_tools.models.schemas import FlowRouteUpsert
    
    logger.info("🔵 [API] _save_block_routes: flow_id=%s, block_key=%s, routes=%d", flow_id, block_key, len(routes))
    
    # 1. Buscar o block_id do bloco
    block_resp = client.table("flow_blocks").select("id").eq("flow_id", flow_id).eq("block_key", block_key).limit(1).execute()
    if not block_resp.data:
        logger.error("❌ [API] Bloco %s não encontrado para salvar routes", block_key)
        return []
    
    block_id = block_resp.data[0]["id"]
    logger.info("✅ [API] Block_id encontrado: %s", block_id)
    
    # 2. Deletar todas as routes antigas deste bloco
    try:
        delete_result = client.table("flow_routes").delete().eq("flow_id", flow_id).eq("block_id", block_id).execute()
        logger.info("🗑️ [API] Routes antigas deletadas do bloco %s", block_key)
    except Exception as e:
        logger.warning("⚠️ [API] Erro ao deletar routes antigas (pode não existirem): %s", str(e)[:200])
    
    # 3. Se não há routes novas, apenas retornar (já deletamos as antigas)
    if not routes:
        logger.info("ℹ️ [API] Nenhuma route para inserir (todas foram deletadas)")
        return []
    
    # 4. Preparar e inserir as novas routes
    routes_to_insert = []
    for idx, route in enumerate(routes):
        # Validar que é FlowRouteUpsert
        if isinstance(route, dict):
            route = FlowRouteUpsert(**route)
        elif not isinstance(route, FlowRouteUpsert):
            logger.warning("⚠️ [API] Route inválida no índice %d, pulando...", idx)
            continue
        
        # Garantir que route_key existe
        route_key = route.route_key
        if not route_key or route_key.strip() == "":
            route_key = f"{block_key}_route_{idx + 1}"
            logger.info("⚠️ [API] Route sem route_key, gerando: %s", route_key)
        
        route_row = {
            "flow_id": flow_id,
            "assistente_id": assistente_id,
            "tenant_id": tenant_id,
            "block_id": block_id,
            "route_key": route_key,
            "label": route.label or "",
            "ordem": route.ordem if route.ordem is not None else (idx + 1),
            "cor": route.cor or "#6b7280",
            "keywords": route.keywords or [],
            "response": route.response or "",
            "destination_type": route.destination_type or "continuar",
            "destination_block_key": route.destination_block_key,
            "max_loop_attempts": route.max_loop_attempts if route.max_loop_attempts is not None else 2,
            "is_fallback": route.is_fallback or False,
        }
        routes_to_insert.append(route_row)
        logger.debug("  ✅ Route preparada: route_key=%s, label=%s", route_key, route.label or "")
    
    # 5. Inserir todas as routes de uma vez
    if routes_to_insert:
        try:
            insert_result = client.table("flow_routes").insert(routes_to_insert).execute()
            logger.info("✅ [API] %d routes inseridas com sucesso para bloco %s", len(routes_to_insert), block_key)
            
            # Verificar se realmente foram inseridas
            verify_resp = client.table("flow_routes").select("id, route_key, label").eq("flow_id", flow_id).eq("block_id", block_id).execute()
            logger.info("🔍 [API] Verificação: %d routes encontradas no banco após inserção", len(verify_resp.data or []))
            
            return routes_to_insert
        except Exception as e:
            error_str = str(e)
            logger.error("❌ [API] Erro ao inserir routes: %s", error_str[:500])
            import traceback
            logger.error("Traceback: %s", traceback.format_exc()[:500])
            
            # Tentar inserir uma por uma como fallback
            inserted_count = 0
            for route_row in routes_to_insert:
                try:
                    client.table("flow_routes").insert([route_row]).execute()
                    inserted_count += 1
                    logger.info("✅ [API] Route inserida individualmente: %s", route_row.get("route_key"))
                except Exception as e2:
                    logger.error("❌ [API] Erro ao inserir route %s: %s", route_row.get("route_key"), str(e2)[:300])
            logger.info("✅ [API] %d de %d routes inseridas individualmente", inserted_count, len(routes_to_insert))
            return routes_to_insert[:inserted_count] if inserted_count > 0 else []
    
    return []


@router.get("/flows")
def list_flows(tenant_id: str = Query(..., description="Tenant ID")) -> list:
    """List flows for the given tenant."""
    flows = flow_service.list_flows_by_tenant(tenant_id)
    return flows


@router.get("/flows/by-assistant/{assistente_id}")
def get_flow_by_assistant(
    assistente_id: str,
    tenant_id: str = Query(..., description="Tenant ID (used to create flow if none exists)"),
    create_if_missing: bool = Query(True, description="Create a default flow if none linked"),
) -> dict:
    """Return the flow linked to this assistant."""
    """Return the flow linked to this assistant."""
    logger.info(f"🌐 [API] get_flow_by_assistant: assistente_id={assistente_id}, tenant_id={tenant_id}")
    flow = flow_service.get_flow_by_assistant(assistente_id)
    if flow:
        logger.info(f"✅ [API] Flow encontrado: flow_id={flow.get('id')}")
        complete = flow_service.get_flow_complete(flow["id"])
        if complete:
            # ⭐ NOVO: Routes agora estão em routes_data (JSONB) dentro de flow_blocks
            # Não retornar routes separadas, apenas blocos (que já têm routes_data)
            blocks = complete.get("blocks") or []
            
            # 🔍 DEBUG CRÍTICO: Verificar se routes_data está presente nos blocos ANTES de retornar
            caminhos_blocks = [b for b in blocks if b.get("block_type") == "caminhos"]
            if caminhos_blocks:
                logger.info(f"🔍 [API] Verificando {len(caminhos_blocks)} blocos de caminhos antes de retornar")
                for block in caminhos_blocks:
                    block_key = block.get("block_key", "SEM_KEY")
                    has_routes_data = "routes_data" in block
                    routes_data_value = block.get("routes_data")
                    routes_data_type = type(routes_data_value).__name__ if routes_data_value is not None else "None"
                    routes_data_length = len(routes_data_value) if isinstance(routes_data_value, list) else "N/A"
                    
                    logger.info(f"🔍 [API] Bloco {block_key}:")
                    logger.info(f"  - has_routes_data: {has_routes_data}")
                    logger.info(f"  - routes_data_type: {routes_data_type}")
                    logger.info(f"  - routes_data_length: {routes_data_length}")
                    logger.info(f"  - routes_data_value: {str(routes_data_value)[:200] if routes_data_value else 'None'}")
                    logger.info(f"  - TODAS propriedades: {list(block.keys())}")
                    
                    # ⚠️ VERIFICAÇÃO CRÍTICA: Se CAM001 não tem routes_data, buscar diretamente
                    if block_key == "CAM001" and (not has_routes_data or routes_data_value is None):
                        logger.error(f"❌ [API] CAM001 SEM routes_data! Buscando diretamente do banco...")
                        try:
                            client = supabase_service._require_client()
                            direct_resp = client.table("flow_blocks").select("routes_data").eq("block_key", "CAM001").eq("flow_id", flow["id"]).single().execute()
                            if direct_resp.data and "routes_data" in direct_resp.data:
                                block["routes_data"] = direct_resp.data["routes_data"]
                                logger.info(f"✅ [API] routes_data recuperado para CAM001: {len(block['routes_data'])} routes")
                        except Exception as e:
                            logger.error(f"❌ [API] Erro ao buscar routes_data para CAM001: {str(e)}")
            
            # ⚠️ GARANTIR que routes_data está presente antes de serializar JSON
            for block in blocks:
                if block.get("block_type") == "caminhos" and "routes_data" not in block:
                    logger.warning(f"⚠️ [API] Bloco {block.get('block_key')} não tem routes_data antes de serializar!")
                    block["routes_data"] = []
            
            result = {
                "flow": complete.get("flow") or flow,
                "blocks": blocks,  # ⭐ Blocos com routes_data
                "routes": [],  # ⚠️ DEPRECATED: routes agora em routes_data dos blocos
            }
            
            # 🔍 DEBUG FINAL: Verificar CAM001 no resultado final ANTES de serializar
            cam001_in_result = next((b for b in result["blocks"] if b.get("block_key") == "CAM001"), None)
            if cam001_in_result:
                logger.info(f"🔍 [API] CAM001 NO RESULTADO FINAL ANTES DE SERIALIZAR:")
                logger.info(f"  - has_routes_data: {'routes_data' in cam001_in_result}")
                logger.info(f"  - routes_data_type: {type(cam001_in_result.get('routes_data')).__name__}")
                logger.info(f"  - routes_data_length: {len(cam001_in_result.get('routes_data', [])) if isinstance(cam001_in_result.get('routes_data'), list) else 'N/A'}")
                logger.info(f"  - routes_data_value: {str(cam001_in_result.get('routes_data'))[:500]}")
                logger.info(f"  - TODAS propriedades: {list(cam001_in_result.keys())}")
            
            blocks_count = len(result.get('blocks', []))
            # Contar routes em routes_data para log
            routes_in_data = sum(
                len(b.get("routes_data", [])) 
                for b in result.get("blocks", []) 
                if b.get("block_type") == "caminhos" and b.get("routes_data")
            )
            logger.info(f"✅ [API] Retornando: {blocks_count} blocos, {routes_in_data} routes em routes_data")
            
            # ⚠️ VERIFICAÇÃO FINAL: Se CAM001 não tem routes_data no resultado, buscar diretamente
            if cam001_in_result and (not cam001_in_result.get("routes_data") or len(cam001_in_result.get("routes_data", [])) == 0):
                logger.error(f"❌ [API] CAM001 SEM routes_data no resultado final! Buscando diretamente...")
                try:
                    from saas_tools.services.supabase_service import supabase_service
                    client = supabase_service._require_client()
                    direct_resp = client.table("flow_blocks").select("routes_data").eq("block_key", "CAM001").eq("flow_id", flow["id"]).single().execute()
                    if direct_resp.data and "routes_data" in direct_resp.data and direct_resp.data["routes_data"]:
                        cam001_in_result["routes_data"] = direct_resp.data["routes_data"]
                        logger.info(f"✅ [API] routes_data recuperado para CAM001 no resultado final: {len(cam001_in_result['routes_data'])} routes")
                except Exception as e:
                    logger.error(f"❌ [API] Erro ao buscar routes_data para CAM001 no resultado final: {str(e)}")
            
            return result
        return {"flow": flow, "blocks": [], "routes": []}
    if not create_if_missing:
        raise HTTPException(status_code=404, detail="Nenhum flow vinculado a este assistente")
    
    # Buscar prompt_voz do assistente antes de criar o flow
    prompt_base = None
    try:
        client = supabase_service._require_client()
        table_names = ["assistentes", "assistents", "assistants"]
        for table_name in table_names:
            try:
                resp = client.table(table_name).select("prompt_voz").eq("id", assistente_id).limit(1).execute()
                if resp.data and resp.data[0].get("prompt_voz"):
                    prompt_base = resp.data[0].get("prompt_voz") or ""
                    logger.info(f"✅ [API] Buscado prompt_voz do assistente (tabela: {table_name}), length: {len(prompt_base)}")
                    break
            except Exception:
                continue
    except Exception as e:
        logger.warning(f"⚠️ [API] Erro ao buscar prompt_voz: {e}")
    
    try:
        new_flow = flow_service.create_flow(
            tenant_id=tenant_id,
            name=f"Flow do assistente {assistente_id[:8] if len(assistente_id) >= 8 else assistente_id}",
            assistente_id=assistente_id,
            prompt_base=prompt_base,  # Usar prompt_voz do assistente
        )
    except Exception as e:
        logger.error(f"❌ [API] Erro ao criar flow: {e}")
        import traceback
        logger.debug(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Erro ao criar flow: {e!s}")
    if not new_flow:
        logger.error("❌ [API] create_flow retornou None")
        raise HTTPException(status_code=500, detail="Erro ao criar flow (resposta vazia)")
    
    # Após criar, chamar get_flow_complete que vai gerar blocos automaticamente se necessário
    complete = flow_service.get_flow_complete(new_flow["id"])
    return complete or {"flow": new_flow, "blocks": [], "routes": []}


@router.get("/flows/{flow_id}")
def get_flow_complete(flow_id: str) -> dict:
    """Return flow + blocks + routes for the editor."""
    data = flow_service.get_flow_complete(flow_id)
    if not data:
        raise HTTPException(status_code=404, detail="Flow não encontrado")
    return data


@router.post("/flows")
def create_flow(payload: FlowCreate) -> dict:
    """Create a new flow."""
    flow = flow_service.create_flow(
        tenant_id=payload.tenant_id,
        name=payload.name,
        assistente_id=payload.assistente_id,
        prompt_base=payload.prompt_base,
        description=payload.description,
    )
    if not flow:
        raise HTTPException(status_code=500, detail="Erro ao criar flow")
    return flow


@router.post("/flows/save", response_model=SaveFlowResult)
def save_flow(payload: SaveFlowPayload) -> dict:
    """Save flow blocks and routes (DELETE all + INSERT all), increment version."""
    logger.info("🔵 [API] save_flow chamado - flow_id=%s, blocks=%d, routes=%d", 
               payload.flow_id, len(payload.blocks), len(payload.routes))
    
    # Log detalhado de cada bloco recebido
    if payload.blocks:
        logger.info("🔵 [API] Blocos recebidos do frontend:")
        for idx, block in enumerate(payload.blocks):
            logger.info("  [%d] %s (%s) - content: '%s'", 
                       idx, block.block_key, block.block_type, (block.content or '')[:60])
    else:
        logger.error("🔴 [API] ⚠️ NENHUM BLOCO recebido do frontend! Isso vai deletar todos os blocos!")
    
    # Log detalhado de cada route recebida
    if payload.routes:
        logger.info("🔵 [API] Routes recebidas do frontend:")
        for idx, route in enumerate(payload.routes):
            logger.info("  [%d] block_key=%s, route_key=%s, label='%s', keywords=%s", 
                       idx, route.block_key, route.route_key, route.label or '', route.keywords or [])
    else:
        logger.warning("⚠️ [API] Nenhuma route recebida do frontend")
    
    result = flow_service.save_flow(payload)
    if not result.get("success"):
        err = result.get("error") or ""
        logger.error("❌ [API] save_flow falhou: %s", err)
        raise HTTPException(
            status_code=404 if "não encontrado" in err else 500,
            detail=err or "Erro ao salvar flow",
        )
    logger.info("✅ [API] save_flow concluído - version=%d", result.get("version", 0))
    return result


@router.patch("/flows/{flow_id}/blocks/{block_key}")
def update_single_block(
    flow_id: str,
    block_key: str,
    block: FlowBlockUpsert,
) -> dict:
    """
    ⚡ MÉTODO SIMPLES: Atualiza apenas um bloco específico na tabela flow_blocks.
    Use este endpoint quando você editar apenas um bloco no Flow Editor.
    """
    logger.info("🔵 [API] update_single_block: flow_id=%s, block_key=%s", flow_id, block_key)
    
    try:
        client = supabase_service._require_client()
        
        # Buscar o flow para pegar assistente_id e tenant_id
        flow_resp = client.table("flows").select("assistente_id, tenant_id").eq("id", flow_id).limit(1).execute()
        if not flow_resp.data:
            raise HTTPException(status_code=404, detail="Flow não encontrado")
        
        flow_data = flow_resp.data[0]
        assistente_id = flow_data.get("assistente_id")
        tenant_id = flow_data.get("tenant_id")
        
        # Preparar dados para UPDATE
        update_data = {
            "block_type": block.block_type,
            "content": block.content or "",
            "order_index": block.order_index or 0,
            "position_x": float(block.position_x) if block.position_x is not None else 0.0,
            "position_y": float(block.position_y) if block.position_y is not None else 0.0,
        }
        
        # Campos opcionais
        if block.variable_name:
            update_data["variable_name"] = block.variable_name
        if block.timeout_seconds is not None:
            update_data["timeout_seconds"] = block.timeout_seconds
        if block.analyze_variable:
            update_data["analyze_variable"] = block.analyze_variable
        if block.tool_type:
            update_data["tool_type"] = block.tool_type
        if block.tool_config:
            update_data["tool_config"] = block.tool_config if isinstance(block.tool_config, dict) else {}
        if block.end_type:
            update_data["end_type"] = block.end_type
        if block.end_metadata:
            update_data["end_metadata"] = block.end_metadata if isinstance(block.end_metadata, dict) else {}
        if block.next_block_key:
            update_data["next_block_key"] = block.next_block_key
        
        # ⭐ NOVO: Processar routes_data (JSONB) se fornecido
        if block.routes_data is not None:
            # Validar que é uma lista
            if isinstance(block.routes_data, list):
                update_data["routes_data"] = block.routes_data
                logger.info("🔵 [API] Bloco %s tem %d routes em routes_data", block_key, len(block.routes_data))
            else:
                logger.warning("⚠️ [API] routes_data não é uma lista, ignorando: %s", type(block.routes_data))
        
        # ⚠️ DEPRECATED: Manter compatibilidade com routes antigas (será removido depois)
        if block.routes is not None and block.block_type == "caminhos":
            logger.info("⚠️ [API] Bloco %s usando campo 'routes' (deprecated). Migre para 'routes_data'", block_key)
            # Converter routes antigas para routes_data
            routes_data = []
            for route in block.routes:
                routes_data.append({
                    "route_key": route.route_key or f"{block_key}_route_{len(routes_data) + 1}",
                    "label": route.label or "",
                    "ordem": route.ordem or len(routes_data) + 1,
                    "cor": route.cor or "#6b7280",
                    "keywords": route.keywords or [],
                    "response": route.response or "",
                    "destination_type": route.destination_type or "continuar",
                    "destination_block_key": route.destination_block_key,
                    "max_loop_attempts": route.max_loop_attempts or 2,
                    "is_fallback": route.is_fallback or False
                })
            update_data["routes_data"] = routes_data
            logger.info("🔵 [API] Convertido %d routes antigas para routes_data", len(routes_data))
        
        # Usar função PostgreSQL RPC para UPDATE rápido (evita timeout do PostgREST)
        try:
            logger.info("🔄 [API] Usando função RPC para atualizar bloco %s", block_key)
            
            # ⭐ Se tem routes_data, usar UPDATE direto (RPC pode não ter suporte ainda)
            if "routes_data" in update_data:
                logger.info("🔵 [API] Bloco %s tem routes_data, usando UPDATE direto em vez de RPC", block_key)
                # Verificar se existe
                existing_resp = client.table("flow_blocks").select("id").eq("flow_id", flow_id).eq("block_key", block_key).limit(1).execute()
                if existing_resp.data:
                    # UPDATE com routes_data
                    result_direct = client.table("flow_blocks").update(update_data).eq("flow_id", flow_id).eq("block_key", block_key).execute()
                    if result_direct.data:
                        routes_data_count = len(update_data.get("routes_data", [])) if isinstance(update_data.get("routes_data"), list) else 0
                        return {
                            "success": True,
                            "block_key": block_key,
                            "action": "updated",
                            "data": result_direct.data[0],
                            "routes_saved": routes_data_count,
                            "routes_data_count": routes_data_count
                        }
                else:
                    # INSERT com routes_data
                    insert_data_with_routes = {
                        "flow_id": flow_id,
                        "block_key": block_key,
                        "assistente_id": assistente_id,
                        "tenant_id": tenant_id,
                        **update_data
                    }
                    result_direct = client.table("flow_blocks").insert(insert_data_with_routes).execute()
                    if result_direct.data:
                        routes_data_count = len(update_data.get("routes_data", [])) if isinstance(update_data.get("routes_data"), list) else 0
                        return {
                            "success": True,
                            "block_key": block_key,
                            "action": "inserted",
                            "data": result_direct.data[0],
                            "routes_saved": routes_data_count,
                            "routes_data_count": routes_data_count
                        }
            
            # Se não tem routes_data, usar RPC (mais rápido)
            rpc_params = {
                "p_flow_id": flow_id,
                "p_block_key": block_key,
                "p_block_type": update_data["block_type"],
                "p_content": update_data["content"],
                "p_order_index": update_data["order_index"],
                "p_position_x": update_data["position_x"],
                "p_position_y": update_data["position_y"],
                "p_variable_name": update_data.get("variable_name"),
                "p_timeout_seconds": update_data.get("timeout_seconds"),
                "p_analyze_variable": update_data.get("analyze_variable"),
                "p_tool_type": update_data.get("tool_type"),
                "p_tool_config": update_data.get("tool_config", {}),
                "p_end_type": update_data.get("end_type"),
                "p_end_metadata": update_data.get("end_metadata", {}),
                "p_next_block_key": update_data.get("next_block_key"),
            }
            
            result = client.rpc("update_flow_block_simple", rpc_params).execute()
            
            if result.data and len(result.data) > 0:
                rpc_result = result.data[0]
                action = rpc_result.get("action", "updated")
                logger.info("✅ [API] Bloco %s %s via RPC", block_key, action)
                
                # ⭐ NOVO: Routes agora estão em routes_data (JSONB), não precisa salvar separadamente
                routes_data_count = 0
                if block.block_type == "caminhos":
                    if block.routes_data:
                        routes_data_count = len(block.routes_data) if isinstance(block.routes_data, list) else 0
                        logger.info("🔵 [API] Bloco %s é do tipo 'caminhos' com %d routes em routes_data (JSONB)", block_key, routes_data_count)
                    elif block.routes:
                        # ⚠️ DEPRECATED: Compatibilidade com formato antigo
                        logger.info("⚠️ [API] Bloco %s usando campo 'routes' (deprecated). Migre para 'routes_data'", block_key)
                        routes_data_count = len(block.routes) if isinstance(block.routes, list) else 0
                    else:
                        logger.info("🔵 [API] Bloco %s é do tipo 'caminhos' sem routes_data", block_key)
                
                # Buscar o bloco completo para retornar
                block_resp = client.table("flow_blocks").select("*").eq("flow_id", flow_id).eq("block_key", block_key).single().execute()
                
                return {
                    "success": True,
                    "block_key": block_key,
                    "action": action,
                    "data": block_resp.data if block_resp.data else {},
                    "routes_saved": routes_data_count,  # ⭐ Compatibilidade: agora conta routes_data
                    "routes_data_count": routes_data_count  # ⭐ NOVO: nome mais claro
                }
            else:
                raise HTTPException(status_code=500, detail=f"RPC não retornou dados para bloco {block_key}")
                
        except Exception as rpc_error:
            error_str = str(rpc_error)
            logger.warning("⚠️ [API] Erro ao usar RPC para %s: %s. Tentando método tradicional...", block_key, error_str[:200])
            
            # Fallback: método tradicional (pode dar timeout, mas tenta)
            try:
                # Verificar se existe
                existing_resp = client.table("flow_blocks").select("id").eq("flow_id", flow_id).eq("block_key", block_key).limit(1).execute()
                
                if existing_resp.data:
                    # UPDATE tradicional
                    result = client.table("flow_blocks").update(update_data).eq("flow_id", flow_id).eq("block_key", block_key).execute()
                    if result.data:
                        # ⭐ Routes agora estão em routes_data (JSONB), já foram salvas no UPDATE acima
                        routes_data_count = 0
                        if block.block_type == "caminhos":
                            if block.routes_data:
                                routes_data_count = len(block.routes_data) if isinstance(block.routes_data, list) else 0
                            elif block.routes:
                                routes_data_count = len(block.routes) if isinstance(block.routes, list) else 0
                        return {
                            "success": True, 
                            "block_key": block_key, 
                            "action": "updated", 
                            "data": result.data[0],
                            "routes_saved": routes_data_count,  # ⭐ Compatibilidade
                            "routes_data_count": routes_data_count  # ⭐ NOVO
                        }
                else:
                    # INSERT tradicional
                    insert_data = {
                        "flow_id": flow_id,
                        "block_key": block_key,
                        "assistente_id": assistente_id,
                        "tenant_id": tenant_id,
                        **update_data
                    }
                    result = client.table("flow_blocks").insert(insert_data).execute()
                    if result.data:
                        # ⭐ Routes agora estão em routes_data (JSONB), já foram salvas no INSERT acima
                        routes_data_count = 0
                        if block.block_type == "caminhos":
                            if block.routes_data:
                                routes_data_count = len(block.routes_data) if isinstance(block.routes_data, list) else 0
                            elif block.routes:
                                routes_data_count = len(block.routes) if isinstance(block.routes, list) else 0
                        return {
                            "success": True, 
                            "block_key": block_key, 
                            "action": "inserted", 
                            "data": result.data[0],
                            "routes_saved": routes_data_count,  # ⭐ Compatibilidade
                            "routes_data_count": routes_data_count  # ⭐ NOVO
                        }
                        
                raise HTTPException(status_code=500, detail=f"Não foi possível atualizar bloco {block_key}")
            except Exception as fallback_error:
                logger.error("❌ [API] Erro no fallback também: %s", str(fallback_error))
                raise HTTPException(status_code=500, detail=f"Erro ao atualizar bloco: {str(fallback_error)}")
                
    except HTTPException:
        raise
    except Exception as e:
        logger.error("❌ [API] Erro ao atualizar bloco %s: %s", block_key, str(e))
        import traceback
        logger.error("Traceback: %s", traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Erro ao atualizar bloco: {str(e)}")


@router.patch("/flows/{flow_id}")
def update_flow(flow_id: str, payload: FlowUpdate) -> dict:
    """Update flow metadata (name, description, prompt_base, status, is_active)."""
    flow = flow_service.get_flow(flow_id)
    if not flow:
        raise HTTPException(status_code=404, detail="Flow não encontrado")
    data = payload.model_dump(exclude_unset=True)
    ok = flow_service.update_flow(flow_id, data)
    if not ok:
        raise HTTPException(status_code=500, detail="Erro ao atualizar flow")
    updated = flow_service.get_flow(flow_id)
    return updated or flow


@router.get("/flows/{flow_id}/prompt")
def get_flow_prompt(flow_id: str) -> dict:
    """Return the built prompt text for this flow."""
    text = prompt_builder.get_prompt_for_flow(flow_id)
    if text is None:
        raise HTTPException(status_code=404, detail="Flow não encontrado")
    return {"prompt": text}


@router.get("/flows/by-assistant/{assistente_id}/prompt")
def get_prompt_by_assistant(assistente_id: str) -> dict:
    """Return the built prompt for the flow linked to this assistant."""
    flow = flow_service.get_flow_by_assistant(assistente_id)
    if not flow:
        raise HTTPException(
            status_code=404,
            detail="Nenhum flow vinculado a este assistente",
        )
    text = prompt_builder.get_prompt_for_flow(flow["id"])
    if text is None:
        raise HTTPException(status_code=404, detail="Flow não encontrado")
    return {"prompt": text, "flow_id": flow["id"]}


@router.delete("/flows/{flow_id}/blocks")
def clear_flow_blocks(flow_id: str) -> dict:
    """
    Limpa todos os blocos de um flow (reset visual).
    NÃO deleta o flow nem o prompt_base, apenas os blocos.
    Útil para testar geração automática pela IA.
    """
    logger.info(f"🧹 [API] clear_flow_blocks: flow_id={flow_id}")
    
    try:
        client = supabase_service._require_client()
        
        # Deletar todos os blocos do flow
        delete_result = client.table("flow_blocks").delete().eq("flow_id", flow_id).execute()
        deleted_count = len(delete_result.data) if delete_result.data else 0
        
        logger.info(f"✅ [API] {deleted_count} blocos deletados do flow {flow_id}")
        
        return {
            "success": True,
            "message": f"{deleted_count} blocos removidos. Ao recarregar, a IA gerará novos blocos automaticamente.",
            "deleted_count": deleted_count
        }
    except Exception as e:
        logger.error(f"❌ [API] Erro ao limpar blocos: {e}")
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Erro ao limpar blocos: {e!s}")


@router.post("/flows/parse-prompt")
def parse_prompt(payload: dict) -> dict:
    """
    Parse prompt_base e gera blocos e rotas automaticamente.
    Retorna blocos prontos para inserir no banco.
    """
    from saas_tools.services.prompt_parser import parse_prompt_base_to_blocks
    
    prompt_base = payload.get("prompt_base", "")
    flow_id = payload.get("flow_id", "")
    assistente_id = payload.get("assistente_id")
    tenant_id = payload.get("tenant_id")
    
    if not prompt_base or not prompt_base.strip():
        raise HTTPException(status_code=400, detail="prompt_base não pode estar vazio")
    
    if not flow_id:
        raise HTTPException(status_code=400, detail="flow_id é obrigatório")
    
    try:
        logger.info("🔵 [API] parse-prompt: Parseando prompt de %d caracteres", len(prompt_base))
        parsed_blocks, parsed_routes = parse_prompt_base_to_blocks(
            prompt_base, flow_id, assistente_id, tenant_id
        )
        
        logger.info("✅ [API] parse-prompt: Gerados %d blocos e %d rotas", len(parsed_blocks), len(parsed_routes))
        
        # Converter routes para routes_data nos blocos
        # Agrupar routes por block_key
        routes_by_block_key: Dict[str, List[Dict[str, Any]]] = {}
        for route in parsed_routes:
            block_key = route.get("block_key")
            if block_key:
                if block_key not in routes_by_block_key:
                    routes_by_block_key[block_key] = []
                routes_by_block_key[block_key].append({
                    "route_key": route.get("route_key", ""),
                    "label": route.get("label", ""),
                    "ordem": route.get("ordem", 0),
                    "cor": route.get("cor", "#6b7280"),
                    "keywords": route.get("keywords", []),
                    "response": route.get("response"),
                    "destination_type": route.get("destination_type", "continuar"),
                    "destination_block_key": route.get("destination_block_key"),
                    "max_loop_attempts": route.get("max_loop_attempts", 2),
                    "is_fallback": route.get("is_fallback", False),
                })
        
        # Adicionar routes_data aos blocos
        for block in parsed_blocks:
            block_key = block.get("block_key")
            if block_key in routes_by_block_key:
                block["routes_data"] = routes_by_block_key[block_key]
                logger.info("✅ [API] parse-prompt: Bloco %s tem %d routes em routes_data", 
                          block_key, len(block["routes_data"]))
        
        return {
            "success": True,
            "blocks": parsed_blocks,
            "routes": parsed_routes,  # Manter para compatibilidade
        }
    except Exception as e:
        logger.error("❌ [API] parse-prompt: Erro ao parsear prompt: %s", str(e))
        import traceback
        logger.error("Traceback: %s", traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Erro ao parsear prompt: {str(e)}")
