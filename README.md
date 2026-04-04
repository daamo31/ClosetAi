# ClosetAi

ClosetAi es una plataforma inteligente que te ayuda a gestionar tu armario, crear outfits personalizados y recibir recomendaciones de moda basadas en IA y el clima. Incluye una app móvil (Flutter) y un backend robusto (FastAPI) con integración de IA, procesamiento de imágenes y conexión a servicios externos como Supabase y OpenWeather.

---

## Tecnologías principales

### Backend (Python)
- **FastAPI** — API REST asíncrona y eficiente
- **SQLAlchemy** — ORM para bases de datos relacionales (PostgreSQL)
- **Supabase** — Almacenamiento de imágenes y autenticación
- **Groq API** — Recomendaciones de moda con LLM (Llama 3)
- **Rembg & Pillow** — Procesamiento y recorte de imágenes
- **OpenWeatherMap** — Datos meteorológicos para sugerencias contextuales

### Mobile (Flutter)
- **Flutter** — Framework multiplataforma para iOS y Android
- **Supabase Flutter** — Autenticación y almacenamiento
- **Cámara, galería e imágenes en red**
- **Animaciones y UI modernas**

---

## Instalación rápida

### Backend
1. Clona el repositorio y entra en la carpeta `backend`.
2. Crea un entorno virtual y activa:
	```bash
	python3 -m venv venv
	source venv/bin/activate
	```
3. Instala dependencias:
	```bash
	pip install -r requirements.txt
	```
4. Configura las variables de entorno necesarias (ver `render.yaml`).
5. Ejecuta el servidor:
	```bash
	uvicorn app.main:app --reload
	```

### Mobile
1. Entra en la carpeta `mobile`.
2. Instala dependencias:
	```bash
	flutter pub get
	```
3. Ejecuta en emulador o dispositivo:
	```bash
	flutter run
	```

---

## Estructura del proyecto

```
ClosetAi/
├── backend/    # API, lógica de negocio, IA y procesamiento de imágenes
├── mobile/     # App Flutter (iOS/Android)
└── assets/     # Imágenes, fuentes y animaciones
```

---

## Despliegue

El backend está preparado para desplegarse fácilmente en [Render.com](https://render.com/) usando Docker. Consulta el archivo `backend/render.yaml` para detalles de configuración y variables de entorno necesarias.

---

## Licencia

Este proyecto está bajo la licencia MIT.