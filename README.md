<div align="center">

# 🧥 ClosetAI

**Your AI-powered personal fashion assistant**

[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?style=flat-square&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/React-19-61DAFB?style=flat-square&logo=react&logoColor=black)](https://react.dev)
[![Flutter](https://img.shields.io/badge/Flutter-3-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?style=flat-square&logo=supabase&logoColor=white)](https://supabase.com)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue?style=flat-square)](LICENSE)

[🌐 Live Demo](https://closet-ai-omega.vercel.app) · [📖 API Docs](https://closetai-revc.onrender.com/docs) · [🐛 Issues](https://github.com/daamo31/ClosetAi/issues)

</div>

---

## What is ClosetAI?

ClosetAI is a full-stack wardrobe management application that combines **artificial intelligence**, **real-time weather data**, and **virtual try-on** to help you dress better every day.

### ✨ Key Features

| Feature | Description |
|---|---|
| 👗 **Digital wardrobe** | Upload garments with photo, category, color, season, occasion and price |
| 🤖 **Background removal** | `rembg` automatically removes photo backgrounds |
| ✨ **AI-powered outfits** | Groq LLM (`llama-3.3-70b-versatile`) generates combinations based on your wardrobe + weather + occasion |
| 🌤️ **Real-time weather** | OpenWeatherMap — by city name or GPS coordinates |
| 💰 **Cost Per Wear (CPW)** | `purchase_price / times_used` — discover which clothes you get the most out of |
| 👗 **Virtual try-on** | Replicate IDM-VTON — try on the full outfit on your own photo |
| 📊 **Freemium plan** | Up to 30 garments on the free tier |
| 🔐 **Secure auth** | Supabase Auth (email/password) with JWT Bearer tokens |

---

## 🏗️ Architecture

```
                         ┌─────────────────────────────────┐
                         │            Clients               │
                         │                                  │
                         │  🌐 Web (React + Vite)           │
                         │  https://closet-ai-omega.vercel.app │
                         │                                  │
                         │  📱 Mobile (Flutter)             │
                         │  iOS + Android                   │
                         └────────────┬────────────────────┘
                                      │ HTTPS + JWT Bearer
                                      ▼
                         ┌─────────────────────────────────┐
                         │      Backend API (FastAPI)       │
                         │  Python 3.11 · Gunicorn+Uvicorn  │
                         │  https://closetai-revc.onrender.com │
                         └────────────┬────────────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
              ▼                       ▼                       ▼
   ┌─────────────────┐    ┌─────────────────────┐  ┌──────────────────┐
   │ Supabase        │    │    External APIs     │  │   Supabase       │
   │ PostgreSQL      │    │                      │  │   Storage        │
   │ (database)      │    │ • Groq (LLM)         │  │ (garment images) │
   │                 │    │ • OpenWeatherMap      │  └──────────────────┘
   │ Supabase Auth   │    │ • Replicate IDM-VTON  │
   │ (JWT tokens)    │    └─────────────────────┘
   └─────────────────┘
```

---

## 📁 Project Structure

```
ClosetAi/
├── 📂 backend/                     FastAPI backend (Python 3.11)
│   ├── Dockerfile                  Docker image for Render.com
│   ├── render.yaml                 Render deploy configuration
│   ├── requirements.txt
│   └── app/
│       ├── main.py                 Entry point — CORS, lifespan, routers
│       ├── config.py               Environment variables (pydantic-settings)
│       ├── auth.py                 Supabase JWT verification
│       ├── database.py             SQLAlchemy async + asyncpg engine
│       ├── models/
│       │   ├── garment.py          `garments` table (PostgreSQL ENUMs)
│       │   ├── outfit.py           `outfits` table
│       │   └── usage_log.py        `usage_logs` table
│       ├── routers/
│       │   ├── garments.py         Garment CRUD + Supabase Storage upload
│       │   ├── outfits.py          AI outfit generation (Groq LLM)
│       │   ├── usage.py            Usage tracking / CPW calculation
│       │   └── tryon.py            Virtual try-on (Replicate IDM-VTON)
│       ├── schemas/                Pydantic v2 request/response schemas
│       ├── services/
│       │   ├── ai_service.py       Prompt engineering → Groq LLM
│       │   ├── image_service.py    rembg background removal
│       │   ├── storage_service.py  Supabase Storage upload/delete/URL
│       │   └── weather_service.py  OpenWeatherMap client
│       └── utils/
│
├── 📂 web/                         React 19 + Vite + TypeScript
│   ├── vercel.json                 SPA routing configuration for Vercel
│   ├── index.html
│   ├── src/
│   │   ├── config/api.ts           Supabase client + JWT helper
│   │   ├── types/index.ts          Global TypeScript types
│   │   ├── services/
│   │   │   ├── garments.ts         Garment API calls
│   │   │   ├── outfits.ts          Outfit API calls
│   │   │   └── tryon.ts            Virtual try-on API call
│   │   ├── screens/
│   │   │   ├── LoginScreen/        Login and registration
│   │   │   ├── DashboardScreen/    Stats + weather + outfit of the day
│   │   │   ├── WardrobeScreen/     Wardrobe with filters
│   │   │   ├── UploadScreen/       Upload garment (camera / file)
│   │   │   ├── OutfitScreen/       Generate outfit + inline try-on
│   │   │   └── TryOnScreen/        Standalone virtual try-on
│   │   └── components/
│   │       └── NavBar.tsx          Bottom navigation bar
│   └── .env.example
│
└── 📂 mobile/                      Flutter 3 (iOS + Android)
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── screens/
        │   ├── login_screen.dart
        │   ├── dashboard_screen.dart
        │   ├── wardrobe_screen.dart
        │   ├── capture_screen.dart
        │   └── weather_forecast_screen.dart
        └── services/
```

---

## 🚀 Local Setup

### Prerequisites

- Python 3.11+
- Node.js 18+
- Flutter 3.x (mobile only)
- Accounts on [Supabase](https://supabase.com), [Groq](https://console.groq.com), [OpenWeatherMap](https://openweathermap.org/api) and [Replicate](https://replicate.com)

### 1. Backend (FastAPI)

```bash
cd backend

# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# → Fill in .env with your credentials (see variable table below)

# Start development server
uvicorn app.main:app --reload --port 8000
```

> **Swagger UI available at:** http://127.0.0.1:8000/docs

### 2. Web (React + Vite)

```bash
cd web

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# → Fill in VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY and VITE_API_URL

# Start development server
npm run dev
# → http://localhost:5173
```

### 3. Mobile (Flutter)

```bash
cd mobile

# Install dependencies
flutter pub get

# Set Supabase credentials in lib/main.dart
# (SUPABASE_URL and SUPABASE_ANON_KEY)

# Run on emulator or connected device
flutter run
```

---

## ⚙️ Environment Variables

### Backend — `backend/.env`

| Variable | Description | Example |
|---|---|---|
| `DATABASE_URL` | Supabase PostgreSQL connection string | `postgresql+asyncpg://...` |
| `SUPABASE_URL` | Supabase project URL | `https://xxxx.supabase.co` |
| `SUPABASE_KEY` | Anon/public key | `eyJh...` |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (for Storage) | `eyJh...` |
| `SUPABASE_JWT_SECRET` | JWT secret for token verification | `your-jwt-secret` |
| `SUPABASE_STORAGE_BUCKET` | Image bucket name | `garment-images` |
| `GROQ_API_KEY` | API key from [console.groq.com](https://console.groq.com) | `gsk_...` |
| `GROQ_MODEL` | LLM model to use | `llama-3.3-70b-versatile` |
| `OPENWEATHER_API_KEY` | API key from [openweathermap.org](https://openweathermap.org) | `abc123...` |
| `REPLICATE_API_TOKEN` | API token from [replicate.com](https://replicate.com) | `r8_...` |
| `ENABLE_BG_REMOVAL` | Enable background removal (`rembg` ~170 MB download) | `False` |
| `APP_ENV` | Runtime environment | `development` / `production` |

### Web — `web/.env`

| Variable | Description |
|---|---|
| `VITE_SUPABASE_URL` | Same value as backend's `SUPABASE_URL` |
| `VITE_SUPABASE_ANON_KEY` | Same value as backend's `SUPABASE_KEY` |
| `VITE_API_URL` | Backend URL on Render (no trailing `/`) |

---

## 📡 API Reference

Base URL: `https://closetai-revc.onrender.com`

> All endpoints (except `/health` and `/`) require the header `Authorization: Bearer <token>`.

### General

| Method | Route | Description |
|---|---|---|
| `GET` | `/` | Service info |
| `GET` | `/health` | Health check for Render |

### Garments

| Method | Route | Description |
|---|---|---|
| `GET` | `/api/garments/` | List all garments for the authenticated user |
| `POST` | `/api/garments/upload` | Upload a new garment with image (multipart/form-data) |
| `GET` | `/api/garments/{id}` | Get a single garment by ID |
| `PUT` | `/api/garments/{id}` | Update garment data |
| `DELETE` | `/api/garments/{id}` | Delete garment and its Storage image |

### Outfits

| Method | Route | Description |
|---|---|---|
| `GET` | `/api/outfits/generate` | Generate an AI outfit based on weather and occasion |

### Usage / CPW

| Method | Route | Description |
|---|---|---|
| `POST` | `/api/usage/log` | Log a garment use (increments `times_used`) |
| `GET` | `/api/usage/stats` | Usage statistics per garment (CPW) |

### Virtual Try-On

| Method | Route | Description |
|---|---|---|
| `POST` | `/api/tryon` | Generate a virtual try-on via Replicate IDM-VTON |

### Weather

| Method | Route | Description |
|---|---|---|
| `GET` | `/api/weather?city={city}` | Current weather by city name |
| `GET` | `/api/weather?lat={lat}&lon={lon}` | Current weather by GPS coordinates |

📖 **Full interactive documentation:** [https://closetai-revc.onrender.com/docs](https://closetai-revc.onrender.com/docs)

---

## 🚢 Deployment

### Backend → Render.com (Docker)

1. Connect the repository to Render as a **Web Service** (Docker)
2. Set **Root Directory:** `backend/`
3. Add all backend environment variables
4. Create the `garment-images` bucket in **Supabase → Storage** (visibility: Public)
5. The `Procfile` and `Dockerfile` are already configured

```yaml
# render.yaml (summary)
services:
  - type: web
    name: closetai-api
    env: docker
    rootDir: backend
    healthCheckPath: /health
```

### Web → Vercel

1. Connect the repository to Vercel
2. Set **Root Directory:** `web/`
3. Framework preset: **Vite**
4. Add the 3 `VITE_*` environment variables
5. In **Supabase → Auth → URL Configuration**, add your Vercel URL to *Redirect URLs*

```json
// vercel.json (SPA routing)
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

### Mobile → APK / iOS

```bash
# Android
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Backend** | Python 3.11, FastAPI 0.115, SQLAlchemy 2 (async), Pydantic v2, Gunicorn + Uvicorn |
| **Database** | PostgreSQL (Supabase), asyncpg |
| **Storage** | Supabase Storage |
| **Authentication** | Supabase Auth (JWT HS256/RS256) |
| **AI — Outfits** | Groq API · `llama-3.3-70b-versatile` |
| **AI — Try-On** | Replicate · `yisol/idm-vton` |
| **Weather** | OpenWeatherMap API v2.5 |
| **Background removal** | `rembg` (optional, ~170 MB) |
| **Web Frontend** | React 19, Vite 8, TypeScript 6, Supabase JS |
| **Mobile** | Flutter 3, Dart, Supabase Flutter |
| **Backend Deploy** | Render.com (Docker, free tier) |
| **Web Deploy** | Vercel (free tier) |

---

## 🤝 Contributing

1. Fork the repository
2. Create your branch: `git checkout -b feature/new-feature`
3. Commit your changes: `git commit -m 'feat: add new feature'`
4. Push to the branch: `git push origin feature/new-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **GNU General Public License v3.0** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ by [daamo31](https://github.com/daamo31)

</div>
