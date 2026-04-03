"""
routers/outfits.py — Endpoint: GET /api/outfits/generate
Flujo:
  1. Recibe ciudad + ocasión del usuario
  2. Consulta el clima actual (OpenWeatherMap)
  3. Carga las prendas del armario del usuario
  4. Envía el prompt al LLM (Groq) → obtiene IDs + razonamiento
  5. Guarda el outfit generado en la base de datos
  6. Devuelve el outfit completo con los objetos de prenda hidratados
"""
import uuid
import logging

from fastapi import APIRouter, Depends, Query, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.garment import Garment
from app.models.outfit import Outfit
from app.schemas.outfit import OutfitResponse, WeatherInfo
from app.schemas.garment import GarmentResponse
from app.services.weather_service import get_weather
from app.services.ai_service import generate_outfit_suggestion
from app.auth import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/outfits", tags=["✨ Outfits"])

VALID_OCCASIONS = {"work", "casual", "sport", "formal", "dinner"}


@router.get("/generate", response_model=OutfitResponse)
async def generate_outfit(
    city:     str = Query(...,      description="Ciudad para el clima, ej: 'Madrid'"),
    occasion: str = Query("casual", description="work | casual | sport | formal | dinner"),
    db:      AsyncSession = Depends(get_db),
    user_id: uuid.UUID    = Depends(get_current_user),
):
    """
    Genera el outfit del día con IA.

    Combina el clima de tu ciudad con tu armario y la ocasión del día
    para sugerirte la combinación perfecta.
    """
    # ── Validar ocasión ───────────────────────────────────────────────────
    if occasion not in VALID_OCCASIONS:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Ocasión inválida. Usa: {sorted(VALID_OCCASIONS)}",
        )

    # ── 1. Obtener clima ──────────────────────────────────────────────────
    weather = await get_weather(city)

    # ── 2. Cargar armario del usuario ────────────────────────────────────
    result = await db.execute(
        select(Garment).where(Garment.user_id == user_id)
    )
    garments = result.scalars().all()

    if not garments:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Tu armario está vacío. "
                "Añade algunas prendas con el botón '+' antes de generar un outfit."
            ),
        )

    if len(garments) < 3:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=(
                f"Tienes solo {len(garments)} prenda(s). "
                "Añade al menos 3 prendas para generar un outfit completo."
            ),
        )

    # ── 3. Llamar al LLM ─────────────────────────────────────────────────
    logger.info(f"Generando outfit para user={user_id}, ciudad={city}, ocasión={occasion}")
    suggestion = await generate_outfit_suggestion(garments, weather, occasion)

    # ── 4. Guardar outfit en la base de datos ─────────────────────────────
    selected_ids = [uuid.UUID(gid) for gid in suggestion["garment_ids"]]
    outfit = Outfit(
        user_id=user_id,
        garment_ids=selected_ids,
        occasion=occasion,
        weather_context=weather,
        ai_reasoning=suggestion.get("reasoning", ""),
        ai_style_tip=suggestion.get("style_tip", ""),
    )
    db.add(outfit)
    await db.commit()
    await db.refresh(outfit)

    # ── 5. Hidratar prendas seleccionadas ─────────────────────────────────
    garment_map = {str(g.id): g for g in garments}
    selected_garments = [
        garment_map[gid]
        for gid in suggestion["garment_ids"]
        if gid in garment_map
    ]

    return OutfitResponse(
        id=outfit.id,
        occasion=occasion,
        garments=selected_garments,
        reasoning=suggestion.get("reasoning", ""),
        style_tip=suggestion.get("style_tip", ""),
        weather=WeatherInfo(**weather),
        created_at=outfit.created_at,
    )


@router.get("/history", response_model=list[OutfitResponse])
async def outfit_history(
    limit: int = Query(default=10, le=50),
    db:      AsyncSession = Depends(get_db),
    user_id: uuid.UUID    = Depends(get_current_user),
):
    """Devuelve el historial de los últimos outfits generados."""
    result = await db.execute(
        select(Outfit)
        .where(Outfit.user_id == user_id)
        .order_by(Outfit.created_at.desc())
        .limit(limit)
    )
    outfits = result.scalars().all()

    # Cargar todas las prendas del usuario de una vez (evitar N+1)
    garments_result = await db.execute(
        select(Garment).where(Garment.user_id == user_id)
    )
    garment_map = {str(g.id): g for g in garments_result.scalars().all()}

    responses = []
    for outfit in outfits:
        selected = [garment_map[str(gid)] for gid in outfit.garment_ids if str(gid) in garment_map]
        weather_data = outfit.weather_context or {}
        responses.append(
            OutfitResponse(
                id=outfit.id,
                occasion=outfit.occasion,
                garments=selected,
                reasoning=outfit.ai_reasoning or "",
                style_tip=outfit.ai_style_tip or "",
                weather=WeatherInfo(
                    city=weather_data.get("city", ""),
                    country=weather_data.get("country", ""),
                    temp=weather_data.get("temp", 0),
                    feels_like=weather_data.get("feels_like", 0),
                    description=weather_data.get("description", ""),
                    humidity=weather_data.get("humidity", 0),
                ),
                created_at=outfit.created_at,
            )
        )
    return responses
