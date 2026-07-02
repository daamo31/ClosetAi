// src/screens/DashboardScreen.tsx
import { useEffect, useState } from 'react';
import { supabase, API_URL } from '../config/api';
import { listGarments } from '../services/garments';
import { getAuthHeader } from '../config/api';
import type { GarmentListResponse, Screen } from '../types';
import styles from './DashboardScreen.module.css';

interface Props {
  onNavigate: (s: Screen) => void;
}

interface Weather {
  city: string; temp: number; feels_like: number;
  description: string; humidity: number; icon: string;
}

export default function DashboardScreen({ onNavigate }: Props) {
  const [userData, setUserData]   = useState<{ email: string } | null>(null);
  const [wardrobe, setWardrobe]   = useState<GarmentListResponse | null>(null);
  const [weather, setWeather]     = useState<Weather | null>(null);
  const [loading, setLoading]     = useState(true);

  useEffect(() => {
    (async () => {
      const { data } = await supabase.auth.getUser();
      if (data.user) setUserData({ email: data.user.email ?? '' });
      try {
        const wd = await listGarments();
        setWardrobe(wd);
      } catch { /* armario vacío */ }
      // Clima — usamos geolocalización si está disponible, si no Madrid
      try {
        const headers = await getAuthHeader();
        const pos = await new Promise<GeolocationPosition | null>(res =>
          navigator.geolocation
            ? navigator.geolocation.getCurrentPosition(p => res(p), () => res(null), { timeout: 4000 })
            : res(null)
        );
        const query = pos
          ? `lat=${pos.coords.latitude}&lon=${pos.coords.longitude}`
          : 'city=Madrid';
        const w = await fetch(`${API_URL}/api/weather?${query}`, { headers });
        if (w.ok) setWeather(await w.json());
      } catch { /* sin clima */ }
      setLoading(false);
    })();
  }, []);

  async function handleSignOut() {
    await supabase.auth.signOut();
  }

  const total     = wardrobe?.total ?? 0;
  const limit     = wardrobe?.free_limit ?? 30;
  const canAdd    = wardrobe?.can_add_more ?? true;
  const pct       = Math.round((total / limit) * 100);

  return (
    <div className="screen">
      {/* Header */}
      <div className={styles.header}>
        <div>
          <h1 className="screen-title">Hola 👋</h1>
          <p className={styles.email}>{userData?.email ?? ''}</p>
        </div>
        <button className="btn btn-ghost btn-sm" onClick={handleSignOut} title="Cerrar sesión">
          Salir
        </button>
      </div>

      {loading ? (
        <div className="loading-center"><div className="spinner" /><span>Cargando...</span></div>
      ) : (
        <>
          {/* Clima */}
          {weather && (
            <div className={`card ${styles.weatherCard}`} onClick={() => onNavigate('outfit')} style={{ cursor: 'pointer' }}>
              <div className={styles.weatherRow}>
                <span className={styles.weatherIcon}>
                  {weather.icon ? <img src={`https://openweathermap.org/img/wn/${weather.icon}@2x.png`} alt="" style={{ width: 48, height: 48 }} /> : '🌤️'}
                </span>
                <div className={styles.weatherInfo}>
                  <p className={styles.weatherCity}>{weather.city}</p>
                  <p className={styles.weatherDesc}>{weather.description}</p>
                </div>
                <span className={styles.weatherTemp}>{Math.round(weather.temp)}°C</span>
              </div>
              <div className={styles.weatherMeta}>
                <span>💧 {weather.humidity}%</span>
                <span>Sensación {Math.round(weather.feels_like)}°C</span>
                <span className={styles.weatherHint}>Toca para generar outfit →</span>
              </div>
            </div>
          )}

          {/* Stats */}
          <div className={`card ${styles.statsCard}`}>
            <div className={styles.stat}>
              <span className={styles.statNum}>{total}</span>
              <span className={styles.statLabel}>Prendas</span>
            </div>
            <div className={styles.dividerV} />
            <div className={styles.stat}>
              <span className={styles.statNum}>{limit}</span>
              <span className={styles.statLabel}>Límite plan</span>
            </div>
            <div className={styles.dividerV} />
            <div className={styles.stat}>
              <span className={`${styles.statNum} ${!canAdd ? styles.danger : ''}`}>{pct}%</span>
              <span className={styles.statLabel}>Capacidad</span>
            </div>
          </div>

          {/* Progress bar */}
          <div className={styles.progress}>
            <div className={styles.progressBar} style={{ width: `${Math.min(pct, 100)}%`, background: pct >= 90 ? 'var(--danger)' : 'var(--primary)' }} />
          </div>
          <p className={styles.progressLabel}>
            {canAdd ? `Puedes añadir ${limit - total} prendas más` : '⚠️ Has alcanzado el límite del plan gratuito'}
          </p>

          {/* Acciones rápidas */}
          <h2 className={styles.sectionTitle}>Acciones rápidas</h2>
          <div className="grid-2" style={{ marginBottom: 16 }}>
            <ActionCard icon="👗" title="Ver armario"   sub={`${total} prendas`}         onClick={() => onNavigate('wardrobe')} />
            <ActionCard icon="✨" title="Generar outfit" sub="Con IA + clima"              onClick={() => onNavigate('outfit')} />
          </div>
          <div className="grid-2">
            <ActionCard icon="📷" title="Añadir prenda" sub="Foto o archivo"              onClick={() => onNavigate('upload')} disabled={!canAdd} />
            <ActionCard icon="🌤️" title="Clima"         sub="En el outfit del día"        onClick={() => onNavigate('outfit')} />
          </div>

          {/* Tip */}
          <div className={`card ${styles.tip}`} style={{ marginTop: 20 }}>
            <span className={styles.tipIcon}>💡</span>
            <p>Añade el precio de compra a tus prendas para calcular el <strong>coste por uso</strong> y ver qué ropa aprovechas más.</p>
          </div>
        </>
      )}
    </div>
  );
}

function ActionCard({ icon, title, sub, onClick, disabled }: {
  icon: string; title: string; sub: string; onClick: () => void; disabled?: boolean;
}) {
  return (
    <button
      className={`card ${styles.actionCard}`}
      onClick={onClick}
      disabled={disabled}
      style={{ textAlign: 'left', width: '100%', cursor: disabled ? 'not-allowed' : 'pointer', opacity: disabled ? .5 : 1 }}
    >
      <span className={styles.actionIcon}>{icon}</span>
      <span className={styles.actionTitle}>{title}</span>
      <span className={styles.actionSub}>{sub}</span>
    </button>
  );
}
