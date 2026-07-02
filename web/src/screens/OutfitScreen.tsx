// src/screens/OutfitScreen.tsx
import { useRef, useState } from 'react';
import { generateOutfit } from '../services/outfits';
import { logUsage } from '../services/garments';
import { virtualTryOn } from '../services/tryon';
import type { Garment, Outfit } from '../types';
import styles from './OutfitScreen.module.css';

const OCCASIONS = [
  { value: 'casual', label: '😎 Casual' },
  { value: 'work',   label: '💼 Trabajo' },
  { value: 'sport',  label: '🏃 Deporte' },
  { value: 'formal', label: '🎩 Formal' },
  { value: 'dinner', label: '🍽️ Cena' },
];

export default function OutfitScreen() {
  const [city, setCity]           = useState('Madrid');
  const [useGps, setUseGps]       = useState(false);
  const [occasion, setOccasion]   = useState('casual');
  const [loading, setLoading]     = useState(false);
  const [outfit, setOutfit]       = useState<Outfit | null>(null);
  const [error, setError]         = useState('');
  const [confirmed, setConfirmed] = useState(false);
  const [confirming, setConfirming] = useState(false);

  // ── Try-on inline ──────────────────────────────────────────────
  const tryonRef                          = useRef<HTMLInputElement>(null);
  const [tryonFile, setTryonFile]         = useState<File | null>(null);
  const [tryonResult, setTryonResult]     = useState<string | null>(null);
  const [tryonLoading, setTryonLoading]   = useState(false);
  const [tryonError, setTryonError]       = useState('');

  function getBestGarment(garments: Garment[]): Garment | null {
    return garments.find(g => g.category === 'top')
      || garments.find(g => g.category === 'outerwear')
      || garments.find(g => g.category === 'bottom')
      || garments[0] || null;
  }

  async function handleTryOn(file: File) {
    if (!outfit) return;
    const withImage = outfit.garments.filter(g => g.image_url);
    if (!withImage.length) { setTryonError('Ninguna prenda tiene imagen para el probador.'); return; }
    setTryonLoading(true);
    setTryonError('');
    try {
      const res = await virtualTryOn(file, withImage.map(g => g.id));
      setTryonResult(res.result_url);
    } catch (e: unknown) {
      setTryonError(e instanceof Error ? e.message : 'Error en el probador');
    } finally {
      setTryonLoading(false);
    }
  }

  async function handleGenerate(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    setOutfit(null);
    setConfirmed(false);

    try {
      let params: Parameters<typeof generateOutfit>[0] = { occasion };

      if (useGps) {
        const pos = await new Promise<GeolocationPosition>((res, rej) =>
          navigator.geolocation.getCurrentPosition(res, rej, { timeout: 8000 })
        );
        params = { ...params, lat: pos.coords.latitude, lon: pos.coords.longitude };
      } else {
        params = { ...params, city };
      }

      const result = await generateOutfit(params);
      setOutfit(result);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Error al generar outfit';
      if (msg.includes('User denied') || msg.includes('PERMISSION_DENIED')) {
        setError('Permiso de ubicación denegado. Usa el nombre de ciudad.');
        setUseGps(false);
      } else {
        setError(msg);
      }
    } finally {
      setLoading(false);
    }
  }

  async function handleConfirm() {
    if (!outfit) return;
    setConfirming(true);
    try {
      await Promise.all(outfit.garments.map(g => logUsage(g.id)));
      // Guardar outfit del día en localStorage
      const today = new Date().toISOString().split('T')[0];
      localStorage.setItem(`closetai_outfit_${today}`, JSON.stringify({
        garments: outfit.garments,
        occasion: outfit.occasion,
        reasoning: outfit.ai_reasoning,
      }));
      setConfirmed(true);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error al confirmar');
    } finally {
      setConfirming(false);
    }
  }

  const w = outfit?.weather;

  return (
    <div className="screen">
      <h1 className="screen-title">Outfit del día ✨</h1>
      <p className="screen-sub">La IA combina tu armario con el clima y la ocasión</p>

      <form onSubmit={handleGenerate} className={`card ${styles.form}`}>
        {/* Ocasión */}
        <div className="input-group" style={{ marginBottom: 12 }}>
          <label>Ocasión</label>
          <select className="input-field" value={occasion} onChange={e => setOccasion(e.target.value)}>
            {OCCASIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
          </select>
        </div>

        {/* Ubicación */}
        <div className="input-group" style={{ marginBottom: 12 }}>
          <label>Ubicación</label>
          <div className={styles.locationRow}>
            <button
              type="button"
              className={`btn btn-sm ${useGps ? 'btn-primary' : 'btn-secondary'}`}
              style={{ width: 'auto', flexShrink: 0 }}
              onClick={() => setUseGps(g => !g)}
            >
              📍 GPS
            </button>
            {!useGps && (
              <input
                type="text"
                className="input-field"
                placeholder="Ciudad, ej: Madrid"
                value={city}
                onChange={e => setCity(e.target.value)}
              />
            )}
            {useGps && <span className={styles.gpsLabel}>Usando tu ubicación actual</span>}
          </div>
        </div>

        {error && <p className="error-msg">{error}</p>}

        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading
            ? <><span className="spinner" style={{ width: 20, height: 20, borderWidth: 2 }} /> Generando con IA...</>
            : '✨ Generar outfit'}
        </button>
      </form>

      {/* Resultado */}
      {outfit && (
        <div className={styles.result}>
          {/* Clima */}
          {w && (
            <div className={`card ${styles.weather}`}>
              <div className={styles.weatherMain}>
                <span className={styles.weatherIcon}>🌤️</span>
                <div>
                  <p className={styles.weatherCity}>{w.city}</p>
                  <p className={styles.weatherDesc}>{w.description}</p>
                </div>
                <span className={styles.weatherTemp}>{Math.round(w.temperature)}°C</span>
              </div>
              <div className={styles.weatherMeta}>
                <span>💧 {w.humidity}%</span>
                <span>💨 {w.wind_speed} m/s</span>
                <span>Sensación: {Math.round(w.feels_like)}°C</span>
              </div>
            </div>
          )}

          {/* Prendas */}
          <h2 className={styles.sectionTitle}>Tu combinación</h2>
          <div className={styles.garmentGrid}>
            {outfit.garments.map(g => (
              <div key={g.id} className={`card ${styles.garmentCard}`}>
                <div className={styles.garmentImg}>
                  {g.image_url
                    ? <img src={g.image_url} alt={g.name} />
                    : <span>👕</span>}
                </div>
                <p className={styles.garmentName}>{g.name}</p>
                <span className="badge badge-purple" style={{ fontSize: '.7rem' }}>{g.category}</span>
              </div>
            ))}
          </div>

          {/* Razonamiento IA */}
          {outfit.ai_reasoning && (
            <div className={`card ${styles.reasoning}`}>
              <p className={styles.reasoningTitle}>💬 Por qué esta combinación</p>
              <p className={styles.reasoningText}>{outfit.ai_reasoning}</p>
            </div>
          )}

          {/* ── Try-on inline ─────────────────────────────────── */}
          <div className={`card ${styles.tryonCard}`}>
            <p className={styles.tryonTitle}>👗 Probarme este outfit</p>
            <p className={styles.tryonSub}>Sube tu foto y la IA te viste con la prenda principal (~45s)</p>
            <input
              ref={tryonRef}
              type="file" accept="image/*" capture="user"
              style={{ display: 'none' }}
              onChange={e => {
                const f = e.target.files?.[0];
                if (f) { setTryonFile(f); setTryonResult(null); handleTryOn(f); }
              }}
            />
            {tryonError && <p className="error-msg">{tryonError}</p>}
            {tryonLoading && (
              <div className="loading-center" style={{ padding: 20 }}>
                <div className="spinner" />
                <span>Generando prueba virtual...</span>
              </div>
            )}
            {tryonResult && (
              <div className={styles.tryonResult}>
                <img src={tryonResult} alt="Try-on" />
                <div style={{ display: 'flex', gap: 8, marginTop: 10 }}>
                  <a href={tryonResult} download="tryon.png" className="btn btn-secondary btn-sm">⬇️ Descargar</a>
                  <button className="btn btn-ghost btn-sm" onClick={() => { setTryonResult(null); setTryonFile(null); if (tryonRef.current) tryonRef.current.value = ''; }}>🔄 Repetir</button>
                </div>
              </div>
            )}
            {!tryonLoading && !tryonResult && (
              <button
                className="btn btn-secondary btn-sm"
                style={{ marginTop: 4 }}
                onClick={() => tryonRef.current?.click()}
              >
                📷 {tryonFile ? 'Cambiar foto' : 'Subir mi foto'}
              </button>
            )}
          </div>

          {/* Confirmar uso */}
          {!confirmed ? (
            <button
              className="btn btn-primary"
              style={{ marginTop: 8 }}
              onClick={handleConfirm}
              disabled={confirming}
            >
              {confirming ? 'Registrando...' : '✅ ¡Lo llevo hoy!'}
            </button>
          ) : (
            <p className="success-msg" style={{ marginTop: 8, textAlign: 'center' }}>
              ¡Perfecto! Se ha registrado el uso en tu armario 🎉
            </p>
          )}
        </div>
      )}
    </div>
  );
}
