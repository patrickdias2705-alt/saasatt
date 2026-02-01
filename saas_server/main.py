import os
import logging
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles

from saas_tools.api.tools import router as tools_router
from saas_tools.api.assistants import router as assistants_router
from saas_tools.api.dashboard import router as dashboard_router
from saas_tools.api.flows import router as flows_router

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

ROOT = Path(__file__).resolve().parents[1]  # workspace root
SAAS_ROOT = ROOT  # static SaaS lives in workspace root
TOOLS_UI_DIR = ROOT / "menu_principal" / "assistentes" / "tools"
# Editor de flow novo (React com ramificações e conexões) — servido em /flow
# Usar sempre o novo frontend se existir
FLOW_DIST_DIR_NEW = Path("/Users/patrickdiasparis/Downloads/assist-tool-craft-main 2/dist")
FLOW_DIST_DIR_OLD = Path("/Users/patrickdiasparis/Downloads/assist-tool-craft-main/dist")
# Priorizar novo frontend
if FLOW_DIST_DIR_NEW.exists():
    FLOW_DIST_DIR = FLOW_DIST_DIR_NEW
    print(f"✅ Usando NOVO frontend: {FLOW_DIST_DIR}")
elif FLOW_DIST_DIR_OLD.exists():
    FLOW_DIST_DIR = FLOW_DIST_DIR_OLD
    print(f"⚠️ Usando frontend ANTIGO (fallback): {FLOW_DIST_DIR}")
else:
    raise RuntimeError("Nenhum frontend encontrado!")

app = FastAPI(title="Salesdever SaaS", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# APIs do tools manager (igual vapi-tools-manager, agora dentro do SaaS)
app.include_router(tools_router, prefix="/api")
app.include_router(assistants_router, prefix="/api")
app.include_router(dashboard_router, prefix="/api")
app.include_router(flows_router, prefix="/api")

# Servir o SaaS estático inteiro
app.mount("/menu_principal", StaticFiles(directory=str(ROOT / "menu_principal")), name="menu_principal")
app.mount("/static", StaticFiles(directory=str(TOOLS_UI_DIR / "static")), name="tools_static")
app.mount("/flow", StaticFiles(directory=str(FLOW_DIST_DIR), html=True), name="flow")

# Rotas UI Tools (sem iframe, mesmo domínio)
@app.get("/tools/gerenciar-tools")
def tools_page():
    return FileResponse(str(TOOLS_UI_DIR / "gerenciar-tools.html"))


@app.get("/tools/setup-tenant")
def tools_setup_tenant():
    return FileResponse(str(TOOLS_UI_DIR / "setup-tenant.html"))


@app.get("/flow")
@app.get("/flow/")
def flow_root():
    return FileResponse(str(FLOW_DIST_DIR / "index.html"))


@app.get("/")
def root():
    """Página inicial do sistema SaaS completo."""
    return FileResponse(str(SAAS_ROOT / "index.html"))


@app.get("/health")
def health():
    return {"status": "ok"}

