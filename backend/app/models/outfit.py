"""
models/outfit.py — Tabla de outfits generados por la IA
Guarda el historial de combinaciones de ropa sugeridas al usuario
"""
import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, Text, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, ARRAY, JSON

from app.database import Base


class Outfit(Base):
    """
    Representa un outfit generado por la IA para el usuario.

    Guarda:
      - Las prendas seleccionadas (garment_ids como array PostgreSQL)
      - El contexto del clima en el momento de la generación
      - El razonamiento del LLM (por qué eligió esas prendas)
    """
    __tablename__ = "outfits"

    # ── Identificadores ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )

    # ── Prendas seleccionadas ─────────────────────────────────────────────────
    # Array de UUIDs de las prendas que componen el outfit
    garment_ids: Mapped[list] = mapped_column(
        ARRAY(UUID(as_uuid=True)), nullable=False, default=list,
        comment="Lista de IDs de prendas que componen este outfit"
    )

    # ── Contexto ──────────────────────────────────────────────────────────────
    occasion: Mapped[str] = mapped_column(
        String(50), nullable=False,
        comment="work | casual | sport | formal"
    )

    # Clima en el momento de la generación → { city, temp, feels_like, description }
    weather_context: Mapped[dict] = mapped_column(
        JSON, nullable=True,
        comment="Datos del clima: ciudad, temperatura, descripción"
    )

    # ── Respuesta del LLM ─────────────────────────────────────────────────────
    ai_reasoning: Mapped[str] = mapped_column(
        Text, nullable=True,
        comment="Explicación del estilista IA sobre la elección"
    )
    ai_style_tip: Mapped[str] = mapped_column(
        Text, nullable=True,
        comment="Consejo de estilo adicional del LLM"
    )

    # ── Timestamp ─────────────────────────────────────────────────────────────
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    def __repr__(self) -> str:
        return (
            f"<Outfit [{self.occasion}] "
            f"{len(self.garment_ids or [])} prendas — {self.created_at}>"
        )
