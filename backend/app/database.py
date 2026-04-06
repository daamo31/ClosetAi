"""
database.py — Motor de base de datos y sesión asíncrona
Conecta a Supabase PostgreSQL usando SQLAlchemy 2.0 + asyncpg
"""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode
from app.config import settings


# ── Adaptar DATABASE_URL para asyncpg ─────────────────────────────────────────
# Render y Supabase proporcionan postgresql:// pero asyncpg necesita postgresql+asyncpg://
_db_url = settings.DATABASE_URL
if _db_url.startswith("postgresql://"):
    _db_url = _db_url.replace("postgresql://", "postgresql+asyncpg://", 1)
elif _db_url.startswith("postgres://"):
    _db_url = _db_url.replace("postgres://", "postgresql+asyncpg://", 1)

# Algunas cadenas de Supabase incluyen params de psycopg (ej. prepared_statements)
# que asyncpg no soporta y provocan: TypeError unexpected keyword argument.
_connect_args = {}
parts = urlsplit(_db_url)
if parts.query:
    raw_pairs = parse_qsl(parts.query, keep_blank_values=True)

    # Convertir sslmode (formato psycopg/libpq) a connect_args para asyncpg.
    sslmode = next((v for k, v in raw_pairs if k == "sslmode"), None)
    if sslmode:
        if sslmode in {"require", "verify-ca", "verify-full"}:
            _connect_args["ssl"] = "require"
        elif sslmode in {"disable", "allow", "prefer"}:
            _connect_args["ssl"] = False

    query_pairs = [
        (k, v)
        for k, v in raw_pairs
        if k not in {"prepared_statements", "sslmode"}
    ]
    _db_url = urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(query_pairs), parts.fragment))


# ── Motor async ───────────────────────────────────────────────────────────────
engine = create_async_engine(
    _db_url,
    echo=(settings.APP_ENV == "development"),   # muestra SQL en logs de dev
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,     # verifica conexión antes de usar (importante en Render)
    connect_args=_connect_args,
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
