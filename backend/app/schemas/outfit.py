"""
schemas/outfit.py — Pydantic v2 schemas para Outfit
"""
from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional
from app.schemas.garment import GarmentResponse


class WeatherInfo(BaseModel):
    """Datos del clima en el momento de generación del outfit."""
    city: str
    temp: float
    feels_like: float
    description: str
    humidity: int


class OutfitResponse(BaseModel):
    """
    Respuesta completa del endpoint /generate-outfit.
    Incluye las prendas completas (no solo sus IDs) para mostrar en la app.
    """
    id: UUID
    occasion: str
    garments: list[GarmentResponse]     # prendas hidratadas (con URL, nombre, etc.)
    reasoning: str                       # "Este conjunto funciona porque..."
    style_tip: str                       # "Añade un cinturón marrón para elevar el look"
    weather: WeatherInfo
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
