"""
auth.py — Verificación de JWT de Supabase Auth
Extrae el user_id del token JWT que Flutter envía en cada petición.

Cómo funciona:
  1. Flutter hace login → Supabase devuelve un JWT token
  2. Flutter guarda el token y lo envía en cada petición:
     Authorization: Bearer <token>
  3. FastAPI lo verifica aquí usando el JWT Secret de Supabase
"""
import uuid
import time
from typing import Any
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError, jwk
import httpx
from app.config import settings

# HTTPBearer extrae automáticamente el token del header Authorization: Bearer <token>
security = HTTPBearer()

# Cache simple de JWKS para evitar pedirlas en cada request.
_JWKS_CACHE: dict[str, Any] = {"keys": None, "ts": 0.0}
_JWKS_TTL_SECONDS = 3600


async def _get_supabase_jwks() -> dict[str, Any]:
    now = time.time()
    if _JWKS_CACHE["keys"] and (now - _JWKS_CACHE["ts"] < _JWKS_TTL_SECONDS):
        return _JWKS_CACHE["keys"]

    jwks_url = f"{settings.SUPABASE_URL}/auth/v1/.well-known/jwks.json"
    async with httpx.AsyncClient(timeout=10.0) as client:
        res = await client.get(jwks_url)
        res.raise_for_status()
        data = res.json()

    _JWKS_CACHE["keys"] = data
    _JWKS_CACHE["ts"] = now
    return data


async def _decode_supabase_token(token: str) -> dict[str, Any]:
    header = jwt.get_unverified_header(token)
    alg = header.get("alg")

    # Proyectos legacy de Supabase usan HS256 con JWT secret.
    if alg == "HS256":
        return jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            options={"verify_aud": False, "verify_exp": True},
        )

    # Proyectos nuevos suelen usar firma asimétrica con JWKS públicas.
    if alg in {"RS256", "ES256"}:
        jwks = await _get_supabase_jwks()
        kid = header.get("kid")
        key_data = next((k for k in jwks.get("keys", []) if k.get("kid") == kid), None)
        if not key_data:
            raise JWTError("No se encontro la clave publica (kid) para validar el token")

        public_key = jwk.construct(key_data)
        return jwt.decode(
            token,
            public_key,
            algorithms=[alg],
            options={"verify_aud": False, "verify_exp": True},
        )

    raise JWTError(f"Algoritmo JWT no soportado: {alg}")


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> uuid.UUID:
    """
    Dependencia de FastAPI → inyecta el user_id en cualquier endpoint.

    Uso en un router:
        @router.get("/mi-armario")
        async def mi_armario(user_id: uuid.UUID = Depends(get_current_user)):
            ...
    """
    token = credentials.credentials

    try:
        payload = await _decode_supabase_token(token)
        user_id_str: str = payload.get("sub")
        if not user_id_str:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido: no contiene user_id",
            )
        return uuid.UUID(user_id_str)

    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token inválido o expirado: {exc}",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token contiene un user_id con formato inválido",
        )
