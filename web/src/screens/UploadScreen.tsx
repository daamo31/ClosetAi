// src/screens/UploadScreen.tsx
import { useRef, useState } from 'react';
import { uploadGarment } from '../services/garments';
import styles from './UploadScreen.module.css';

const INITIAL = {
  name: '', category: 'top', color: '',
  season: 'all', occasion: 'casual', purchase_price: 0,
};

export default function UploadScreen({ onSuccess }: { onSuccess?: () => void }) {
  const fileRef                   = useRef<HTMLInputElement>(null);
  const [image, setImage]         = useState<File | null>(null);
  const [preview, setPreview]     = useState<string | null>(null);
  const [form, setForm]           = useState(INITIAL);
  const [loading, setLoading]     = useState(false);
  const [error, setError]         = useState('');
  const [success, setSuccess]     = useState('');

  function handleFile(file: File | undefined) {
    if (!file) return;
    if (!file.type.startsWith('image/')) { setError('Solo se permiten imágenes.'); return; }
    if (file.size > 10 * 1024 * 1024) { setError('La imagen no puede superar 10 MB.'); return; }
    setError('');
    setImage(file);
    setPreview(URL.createObjectURL(file));
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    handleFile(e.dataTransfer.files[0]);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!image) { setError('Selecciona una imagen primero.'); return; }
    if (!form.name.trim()) { setError('El nombre es obligatorio.'); return; }
    if (!form.color.trim()) { setError('El color es obligatorio.'); return; }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      await uploadGarment(image, form);
      setSuccess('✅ ¡Prenda añadida al armario!');
      setImage(null);
      setPreview(null);
      setForm(INITIAL);
      if (fileRef.current) fileRef.current.value = '';
      onSuccess?.();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Error al subir');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="screen">
      <h1 className="screen-title">Añadir prenda 📷</h1>
      <p className="screen-sub">Haz una foto con la cámara o sube una imagen desde tu dispositivo</p>

      <form onSubmit={handleSubmit}>
        {error   && <p className="error-msg">{error}</p>}
        {success && <p className="success-msg">{success}</p>}

        {/* Zona de imagen */}
        <div
          className={`${styles.dropZone} ${preview ? styles.hasImage : ''}`}
          onClick={() => fileRef.current?.click()}
          onDragOver={e => e.preventDefault()}
          onDrop={handleDrop}
        >
          {preview ? (
            <img src={preview} alt="Preview" className={styles.preview} />
          ) : (
            <div className={styles.placeholder}>
              <span>📷</span>
              <p>Toca para hacer foto o subir imagen</p>
              <p className={styles.hint}>JPG, PNG, WEBP · Máx 10 MB</p>
            </div>
          )}
        </div>

        {/* Input oculto — accept="image/*" habilita cámara en móvil */}
        <input
          ref={fileRef}
          type="file"
          accept="image/*"
          capture="environment"
          style={{ display: 'none' }}
          onChange={e => handleFile(e.target.files?.[0])}
        />

        {/* Botones imagen */}
        <div className={styles.imgBtns}>
          <button type="button" className="btn btn-secondary btn-sm" onClick={() => fileRef.current?.click()}>
            📷 Cámara / Archivo
          </button>
          {preview && (
            <button
              type="button"
              className="btn btn-ghost btn-sm"
              onClick={() => { setImage(null); setPreview(null); if (fileRef.current) fileRef.current.value = ''; }}
            >
              ✕ Quitar foto
            </button>
          )}
        </div>

        <div className="divider">Datos de la prenda</div>

        {/* Nombre */}
        <div className="input-group">
          <label>Nombre *</label>
          <input
            type="text"
            className="input-field"
            placeholder="Ej: Camisa azul Oxford"
            value={form.name}
            onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
            maxLength={200}
          />
        </div>

        {/* Color */}
        <div className="input-group">
          <label>Color *</label>
          <input
            type="text"
            className="input-field"
            placeholder="Ej: Azul marino"
            value={form.color}
            onChange={e => setForm(f => ({ ...f, color: e.target.value }))}
            maxLength={100}
          />
        </div>

        {/* Categoría + Temporada */}
        <div className="grid-2">
          <div className="input-group">
            <label>Categoría *</label>
            <select className="input-field" value={form.category} onChange={e => setForm(f => ({ ...f, category: e.target.value }))}>
              <option value="top">👕 Top</option>
              <option value="bottom">👖 Pantalón</option>
              <option value="shoes">👟 Calzado</option>
              <option value="outerwear">🧥 Abrigo</option>
              <option value="accessory">💍 Accesorio</option>
            </select>
          </div>
          <div className="input-group">
            <label>Temporada</label>
            <select className="input-field" value={form.season} onChange={e => setForm(f => ({ ...f, season: e.target.value }))}>
              <option value="all">Todo el año</option>
              <option value="spring">🌸 Primavera</option>
              <option value="summer">☀️ Verano</option>
              <option value="autumn">🍂 Otoño</option>
              <option value="winter">❄️ Invierno</option>
            </select>
          </div>
        </div>

        {/* Ocasión + Precio */}
        <div className="grid-2">
          <div className="input-group">
            <label>Ocasión</label>
            <select className="input-field" value={form.occasion} onChange={e => setForm(f => ({ ...f, occasion: e.target.value }))}>
              <option value="casual">😎 Casual</option>
              <option value="work">💼 Trabajo</option>
              <option value="sport">🏃 Deporte</option>
              <option value="formal">🎩 Formal</option>
            </select>
          </div>
          <div className="input-group">
            <label>Precio de compra (€)</label>
            <input
              type="number"
              className="input-field"
              placeholder="0.00"
              min="0"
              step="0.01"
              value={form.purchase_price || ''}
              onChange={e => setForm(f => ({ ...f, purchase_price: parseFloat(e.target.value) || 0 }))}
            />
          </div>
        </div>

        <button type="submit" className="btn btn-primary" style={{ marginTop: 8 }} disabled={loading}>
          {loading ? <><span className="spinner" style={{ width: 20, height: 20, borderWidth: 2 }} /> Subiendo...</> : '➕ Añadir al armario'}
        </button>
      </form>
    </div>
  );
}
