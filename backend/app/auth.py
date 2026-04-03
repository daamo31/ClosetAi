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
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from app.config import settings

# HTTPBearer extrae automáticamente el token del header Authorization: Bearer <token>
security = HTTPBearer()


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
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            options={
                "verify_aud": False,    # Supabase no siempre incluye audience
                "verify_exp": True,     # Sí verificamos expiración
            },
        )
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
