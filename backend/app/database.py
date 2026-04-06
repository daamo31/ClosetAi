"""
database.py — Motor de base de datos y sesión asíncrona
Conecta a Supabase PostgreSQL usando SQLAlchemy 2.0 + asyncpg
"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.config import settings


# ── Adaptar DATABASE_URL para asyncpg ─────────────────────────────────────────
# Render y Supabase proporcionan postgresql:// pero asyncpg necesita postgresql+asyncpg://
_db_url = settings.DATABASE_URL
if _db_url.startswith("postgresql://"):
    _db_url = _db_url.replace("postgresql://", "postgresql+asyncpg://", 1)
elif _db_url.startswith("postgres://"):
    _db_url = _db_url.replace("postgres://", "postgresql+asyncpg://", 1)


# ── Motor async ───────────────────────────────────────────────────────────────
engine = create_async_engine(
    _db_url,
    echo=(settings.APP_ENV == "development"),   # muestra SQL en logs de dev
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,     # verifica conexión antes de usar (importante en Render)
)

# ── Fábrica de sesiones ───────────────────────────────────────────────────────
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


# ── Clase base para todos los modelos ORM ─────────────────────────────────────
class Base(DeclarativeBase):
    pass


# ── Dependencia de FastAPI para inyección de sesión ──────────────────────────
async def get_db() -> AsyncSession:
    """
    Generador de sesión DB para usar con Depends() en los routers.
    La sesión se cierra automáticamente al terminar cada petición.
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
