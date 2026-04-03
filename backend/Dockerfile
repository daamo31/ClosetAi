# ═══════════════════════════════════════════════════════════════
#   ClosetAI — Dockerfile para Render.com
#
#   Usa python:3.11-slim como base y pre-descarga el modelo
#   de rembg (U2Net) durante el BUILD para que el primer
#   request no tenga que esperar ~170MB de descarga.
# ═══════════════════════════════════════════════════════════════

FROM python:3.11-slim

# Evitar preguntas interactivas durante instalación
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# ── Dependencias del sistema (necesarias para rembg / OpenCV) ──
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Dependencias Python ────────────────────────────────────────
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ── Pre-descargar modelo U2Net de rembg ───────────────────────
# (se descarga durante el build → no hay espera en el primer request)
RUN python -c "from rembg import new_session; new_session('u2net'); print('✅ Modelo U2Net descargado')"

# ── Copiar código fuente ───────────────────────────────────────
COPY . .

# ── Puerto ────────────────────────────────────────────────────
EXPOSE 8000

# ── Comando de inicio ─────────────────────────────────────────
# Render.com inyecta $PORT automáticamente
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
