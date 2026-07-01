"""
models/usage_log.py — Tabla de registros de uso de prendas
Cada registro = "hoy usé esta prenda en esta ocasión"
Alimenta el cálculo de coste por uso (CPW) en la tabla garments
"""
import uuid
from datetime import datetime

from sqlalchemy import String, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, ENUM

from app.database import Base

occasion_enum = ENUM('work', 'casual', 'sport', 'formal',
                     name='occasion_enum', create_type=False)


class UsageLog(Base):
    """
    Registro inmutable de cada vez que el usuario usa una prenda.

    Flujo:
      1. Usuario confirma outfit del día → Flutter llama POST /api/usage/log
      2. Se crea un UsageLog por cada prenda del outfit
      3. El router incrementa Garment.times_used y recalcula CPW
    """
    __tablename__ = "usage_logs"

    # ── Identificadores ───────────────────────────────────────────────────────
    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )
    garment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True,
        comment="Prenda que fue usada"
    )

    # ── Contexto del uso ──────────────────────────────────────────────────────
    # outfit_id es opcional: el usuario puede registrar el uso de una prenda
    # individual sin necesidad de haberla obtenido de un outfit generado
    outfit_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=True,
        comment="Outfit del que formaba parte (si aplica)"
    )
    occasion: Mapped[str] = mapped_column(
        occasion_enum, nullable=True,
        comment="work | casual | sport | formal"
    )

    # ── Cuándo fue usado ──────────────────────────────────────────────────────
    worn_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False,
        comment="Fecha y hora en que se llevó la prenda"
    )

    def __repr__(self) -> str:
        return f"<UsageLog garment={self.garment_id} @ {self.worn_at}>"
