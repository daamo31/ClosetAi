"""
routers/usage.py — Endpoint: POST /api/usage/log
Registra que el usuario llevó una prenda hoy.
Actualiza automáticamente el contador y el coste por uso (CPW).
"""
import uuid
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.garment import Garment
from app.models.usage_log import UsageLog
from app.schemas.usage_log import UsageLogCreate, UsageLogResponse
from app.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/usage", tags=["📊 Uso"])


@router.post("/log", response_model=UsageLogResponse, status_code=status.HTTP_201_CREATED)
async def log_usage(
    data:    UsageLogCreate,
    db:      AsyncSession = Depends(get_db),
    user_id: uuid.UUID    = Depends(get_current_user),
):
    """
    Registra el uso de una prenda.

    - Incrementa `times_used` en la prenda
    - Recalcula `cost_per_wear = purchase_price / times_used`
    - Crea un registro en usage_logs (historial inmutable)

    Llama a este endpoint cuando el usuario confirma el outfit del día
    o marca manualmente que llevó una prenda.
    """
    # ── Verificar que la prenda pertenece al usuario ───────────────────────
    result = await db.execute(
        select(Garment).where(
            Garment.id == data.garment_id,
            Garment.user_id == user_id,
        )
    )
    garment = result.scalar_one_or_none()

    if not garment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Prenda {data.garment_id} no encontrada en tu armario.",
        )

    # ── Actualizar métricas CPW ───────────────────────────────────────────
    garment.times_used += 1
    garment.recalculate_cpw()   # método del modelo: purchase_price / times_used

    # ── Crear registro de uso ─────────────────────────────────────────────
    log = UsageLog(
        user_id=user_id,
        garment_id=data.garment_id,
        outfit_id=data.outfit_id,
        occasion=data.occasion,
    )
    db.add(log)
    await db.commit()
    await db.refresh(garment)

    cpw = float(garment.cost_per_wear)
    message = (
        f"✅ '{garment.name}' usada {garment.times_used} "
        f"{'vez' if garment.times_used == 1 else 'veces'}. "
        f"Coste por uso: {cpw:.2f}€"
    )

    logger.info(f"Uso registrado: prenda='{garment.name}', CPW={cpw:.2f}€")

    return UsageLogResponse(
        id=log.id,
        garment_id=garment.id,
        garment_name=garment.name,
        times_used=garment.times_used,
        cost_per_wear=garment.cost_per_wear,
        message=message,
    )


@router.post("/log-outfit/{outfit_id}", status_code=status.HTTP_201_CREATED)
async def log_outfit_usage(
    outfit_id: uuid.UUID,
    occasion: str = "casual",
    db:      AsyncSession = Depends(get_db),
    user_id: uuid.UUID    = Depends(get_current_user),
):
    """
    Registra el uso de TODAS las prendas de un outfit de una vez.
    Útil cuando el usuario confirma "sí, llevé este outfit hoy".
    """
    from app.models.outfit import Outfit

    # Verificar que el outfit pertenece al usuario
    result = await db.execute(
        select(Outfit).where(Outfit.id == outfit_id, Outfit.user_id == user_id)
    )
    outfit = result.scalar_one_or_none()

    if not outfit:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Outfit no encontrado.",
        )

    # Cargar y actualizar cada prenda del outfit
    updated = []
    for garment_uuid in outfit.garment_ids:
        res = await db.execute(
            select(Garment).where(Garment.id == garment_uuid, Garment.user_id == user_id)
        )
        garment = res.scalar_one_or_none()
        if garment:
            garment.times_used += 1
            garment.recalculate_cpw()
            log = UsageLog(
                user_id=user_id,
                garment_id=garment.id,
                outfit_id=outfit_id,
                occasion=occasion,
            )
            db.add(log)
            updated.append(garment.name)

    await db.commit()
    return {
        "message": f"✅ Registrado uso de {len(updated)} prendas del outfit.",
        "garments_updated": updated,
    }
