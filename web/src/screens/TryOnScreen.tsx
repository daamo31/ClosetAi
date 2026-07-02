// src/screens/TryOnScreen.tsx
import { useRef, useState } from 'react';
import { listGarments } from '../services/garments';
import { virtualTryOn } from '../services/tryon';
import type { Garment } from '../types';
import styles from './TryOnScreen.module.css';

const CATEGORY_ICON: Record<string, string> = {
  top: '👕', bottom: '👖', shoes: '👟', outerwear: '🧥', accessory: '💍',
};

export default function TryOnScreen() {
  const fileRef                     = useRef<HTMLInputElement>(null);
  const [personFile, setPersonFile] = useState<File | null>(null);
  const [personPreview, setPersonPreview] = useState<string | null>(null);
  const [garments, setGarments]     = useState<Garment[] | null>(null);
  const [selected, setSelected]     = useState<Garment | null>(null);
  const [loading, setLoading]       = useState(false);
  const [loadingGarments, setLoadingGarments] = useState(false);
  const [resultUrl, setResultUrl]   = useState<string | null>(null);
  const [error, setError]           = useState('');

  function handlePersonFile(file: File | undefined) {
    if (!file) return;
    setPersonFile(file);
    setPersonPreview(URL.createObjectURL(file));
    setResultUrl(null);
    setError('');
    if (!garments) loadGarments();
  }

  async function loadGarments() {
    setLoadingGarments(true);
    try {
      const data = await listGarments();
      // Solo prendas con imagen y categorías que IDM-VTON soporta bien
      setGarments(data.garments.filter(g => g.image_url));
    } catch {
      setError('No se pudo cargar el armario.');
    } finally {
      setLoadingGarments(false);
    }
  }

  async function handleTryOn() {
    if (!personFile || !selected) return;
    setLoading(true);
    setError('');
    setResultUrl(null);
    try {
      const res = await virtualTryOn(personFile, [selected.id]);
      setResultUrl(res.result_url);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Error en el probador');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="screen">
      <h1 className="screen-title">Probador virtual 👗</h1>
      <p className="screen-sub">Pruébate las prendas de tu armario con IA · ~30-60 segundos</p>

      {error && <p className="error-msg">{error}</p>}

      {/* Paso 1: Foto de la persona */}
      <div className={styles.step}>
        <p className={styles.stepLabel}>1 · Tu foto</p>
        <div
          className={`${styles.dropZone} ${personPreview ? styles.hasImage : ''}`}
          onClick={() => fileRef.current?.click()}
        >
          {personPreview
            ? <img src={personPreview} alt="Tu foto" className={styles.preview} />
            : <div className={styles.placeholder}><span>🤳</span><p>Toca para subir o hacer foto</p><p className={styles.hint}>Ponte de pie, fondo liso — mejor resultado</p></div>
          }
        </div>
        <input
          ref={fileRef}
          type="file"
          accept="image/*"
          capture="user"
          style={{ display: 'none' }}
          onChange={e => handlePersonFile(e.target.files?.[0])}
        />
        {personPreview && (
          <button className="btn btn-ghost btn-sm" style={{ marginTop: 8 }}
            onClick={() => { setPersonFile(null); setPersonPreview(null); setResultUrl(null); if (fileRef.current) fileRef.current.value = ''; }}>
            ✕ Cambiar foto
          </button>
        )}
      </div>

      {/* Paso 2: Elegir prenda */}
      {personPreview && (
        <div className={styles.step}>
          <p className={styles.stepLabel}>2 · Elige una prenda</p>
          {loadingGarments
            ? <div className="loading-center"><div className="spinner" /></div>
            : garments?.length === 0
              ? <p style={{ color: 'var(--text-3)', fontSize: '.9rem' }}>No tienes prendas con imagen en tu armario.</p>
              : (
                <div className={styles.garmentGrid}>
                  {garments?.map(g => (
                    <button
                      key={g.id}
                      className={`${styles.garmentBtn} ${selected?.id === g.id ? styles.garmentSelected : ''}`}
                      onClick={() => { setSelected(g); setResultUrl(null); }}
                    >
                      <div className={styles.garmentImg}>
                        {g.image_url
                          ? <img src={g.image_url} alt={g.name} />
                          : <span>{CATEGORY_ICON[g.category] ?? '👕'}</span>}
                      </div>
                      <p className={styles.garmentName}>{g.name}</p>
                    </button>
                  ))}
                </div>
              )
          }
        </div>
      )}

      {/* Botón generar */}
      {personPreview && selected && !resultUrl && (
        <button
          className="btn btn-primary"
          style={{ marginTop: 4 }}
          onClick={handleTryOn}
          disabled={loading}
        >
          {loading
            ? <><span className="spinner" style={{ width: 20, height: 20, borderWidth: 2 }} /> Generando con IA (~30-60s)...</>
            : '👗 Probarme esta prenda'}
        </button>
      )}

      {/* Resultado */}
      {resultUrl && (
        <div className={styles.result}>
          <p className={styles.resultTitle}>✨ Resultado — {selected?.name}</p>          <img src={resultUrl} alt="Try-on result" className={styles.resultImg} />
          <div style={{ display: 'flex', gap: 10, marginTop: 12 }}>
            <a href={resultUrl} download="tryon.png" className="btn btn-secondary btn-sm">
              ⬇️ Descargar
            </a>
            <button className="btn btn-ghost btn-sm" onClick={() => { setResultUrl(null); setSelected(null); }}>
              🔄 Probar otra
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
