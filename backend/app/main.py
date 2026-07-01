"""
main.py — Punto de entrada de la aplicación ClosetAI
Configura FastAPI, CORS, routers y crea las tablas al arrancar
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.database import engine, Base
from app.routers import garments, outfits, usage

# ── Logging ───────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)


# ── Lifespan (startup / shutdown) ─────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Se ejecuta al arrancar y al apagar el servidor.
    Crea las tablas en PostgreSQL si no existen (ideal para el primer deploy).
    """
    # STARTUP
    logger.info("🚀 ClosetAI API arrancando...")

    # Importar modelos para que estén registrados con Base.metadata
    import app.models  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

        # Compatibilidad con despliegues existentes: create_all no agrega columnas
        # en tablas ya creadas. Añadimos updated_at si no existe.
        await conn.execute(text("""
            ALTER TABLE garments
            ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
        """))

        logger.info("✅ Tablas verificadas / creadas en PostgreSQL")

    yield  # ← la app está corriendo aquí

    # SHUTDOWN
    await engine.dispose()
    logger.info("👋 ClosetAI API detenida correctamente")


# ── Aplicación FastAPI ────────────────────────────────────────────────────────
app = FastAPI(
    title="ClosetAI API",
    description=(
        "🧥 **ClosetAI** — Tu asesor de moda personal con IA.\n\n"
        "Sube tus prendas, registra su uso y recibe sugerencias de outfits "
        "personalizadas según el clima y la ocasión del día."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",       # Swagger UI (solo en desarrollo)
    redoc_url="/redoc",
)

# ── CORS ──────────────────────────────────────────────────────────────────────
ALLOWED_ORIGINS = [
    "https://closet-ai-omega.vercel.app",   # Web app en Vercel
    "http://localhost:5173",                 # Dev local
    "http://127.0.0.1:5173",               # Dev local (alternativo)
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,   # usamos JWT Bearer, no cookies → False evita conflicto con origins explícitos
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(garments.router)
app.include_router(outfits.router)
app.include_router(usage.router)


# ── Endpoints de utilidad ─────────────────────────────────────────────────────
@app.get("/", tags=["🏠 General"])
async def root():
    return {
        "service": "ClosetAI API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health", tags=["🏠 General"])
async def health_check():
    """
    Endpoint de salud para Render.com health checks.
    También sirve para mantener el servidor despierto (keep-alive).
    """
    return {"status": "ok", "service": "ClosetAI"}
