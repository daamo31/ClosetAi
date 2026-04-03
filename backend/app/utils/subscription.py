"""
utils/subscription.py — Lógica del modelo Freemium
Controla los límites del plan gratuito vs. Premium
"""
import uuid
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.garment import Garment

# ── Límites del plan gratuito ─────────────────────────────────────────────────
FREE_GARMENT_LIMIT     = 30    # máximo de prendas
FREE_OUTFIT_LIMIT      = 10    # outfits generados por mes (futuro)


async def check_garment_limit(db: AsyncSession, user_id: uuid.UUID) -> None:
    """
    Verifica que el usuario no supere el límite de 30 prendas del plan gratuito.
    Lanza HTTPException 403 si se excede el límite.

    Llamar ANTES de insertar una nueva prenda en la base de datos.
    """
    result = await db.execute(
        select(func.count()).select_from(Garment).where(Garment.user_id == user_id)
    )
    current_count: int = result.scalar_one()

    if current_count >= FREE_GARMENT_LIMIT:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                f"Has alcanzado el límite de {FREE_GARMENT_LIMIT} prendas del plan gratuito. "
                f"Actualmente tienes {current_count} prendas. "
                f"Actualiza a ClosetAI Premium para añadir prendas ilimitadas."
            ),
        )


async def get_garment_count(db: AsyncSession, user_id: uuid.UUID) -> int:
    """Devuelve el número actual de prendas del usuario (útil para el dashboard)."""
    result = await db.execute(
        select(func.count()).select_from(Garment).where(Garment.user_id == user_id)
    )
    return result.scalar_one()


def can_add_garment(current_count: int) -> bool:
    """Retorna True si el usuario puede añadir más prendas con el plan free."""
    return current_count < FREE_GARMENT_LIMIT
