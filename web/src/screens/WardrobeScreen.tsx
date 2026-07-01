// src/screens/WardrobeScreen.tsx
import { useEffect, useState } from 'react';
import { listGarments, deleteGarment } from '../services/garments';
import type { Garment } from '../types';
import styles from './WardrobeScreen.module.css';

const CATEGORIES = ['all', 'top', 'bottom', 'shoes', 'outerwear', 'accessory'] as const;
const LABELS: Record<string, string> = {
  all: 'Todo', top: 'Tops', bottom: 'Pantalones',
  shoes: 'Calzado', outerwear: 'Abrigos', accessory: 'Accesorios',
};

const CATEGORY_BADGE: Record<string, string> = {
  top: 'badge-blue', bottom: 'badge-green', shoes: 'badge-yellow',
  outerwear: 'badge-purple', accessory: 'badge-red',
};

export default function WardrobeScreen() {
  const [garments, setGarments]     = useState<Garment[]>([]);
  const [loading, setLoading]       = useState(true);
  const [filter, setFilter]         = useState<string>('all');
  const [deleting, setDeleting]     = useState<string | null>(null);
  const [error, setError]           = useState('');
  const [total, setTotal]           = useState(0);
  const [canAdd, setCanAdd]         = useState(true);

  async function load() {
    setLoading(true);
    try {
      const data = await listGarments();
      setGarments(data.garments);
      setTotal(data.total);
      setCanAdd(data.can_add_more);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Error al cargar');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { load(); }, []);

  async function handleDelete(id: string) {
    if (!confirm('¿Eliminar esta prenda?')) return;
    setDeleting(id);
    try {
      await deleteGarment(id);
      setGarments(g => g.filter(x => x.id !== id));
      setTotal(t => t - 1);
      setCanAdd(true);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Error al eliminar');
    } finally {
      setDeleting(null);
    }
  }

  const filtered = filter === 'all' ? garments : garments.filter(g => g.category === filter);

  return (
    <div className="screen">
      <h1 className="screen-title">Mi armario 👗</h1>
      <p className="screen-sub">{total} prenda{total !== 1 ? 's' : ''} · Plan gratuito: {total}/30</p>

      {error && <p className="error-msg">{error}</p>}

      {/* Filtros */}
      <div className={styles.filters}>
        {CATEGORIES.map(cat => (
          <button
            key={cat}
            className={`${styles.filter} ${filter === cat ? styles.active : ''}`}
            onClick={() => setFilter(cat)}
          >
            {LABELS[cat]}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="loading-center"><div className="spinner" /><span>Cargando armario...</span></div>
      ) : filtered.length === 0 ? (
        <div className={styles.empty}>
          <span>👕</span>
          <p>{filter === 'all' ? 'Tu armario está vacío' : `No tienes ${LABELS[filter].toLowerCase()}`}</p>
          <p style={{ fontSize: '.85rem', color: 'var(--text-3)' }}>Añade prendas con el botón ➕</p>
        </div>
      ) : (
        <div className={styles.grid}>
          {filtered.map(g => (
            <GarmentCard
              key={g.id}
              garment={g}
              isDeleting={deleting === g.id}
              onDelete={() => handleDelete(g.id)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function GarmentCard({ garment: g, isDeleting, onDelete }: {
  garment: Garment; isDeleting: boolean; onDelete: () => void;
}) {
  return (
    <div className={`card ${styles.card}`}>
      {/* Imagen */}
      <div className={styles.imgWrap}>
        {g.image_url ? (
          <img src={g.image_url} alt={g.name} className={styles.img} loading="lazy" />
        ) : (
          <div className={styles.imgPlaceholder}>👕</div>
        )}
      </div>

      {/* Info */}
      <div className={styles.info}>
        <p className={styles.name} title={g.name}>{g.name}</p>
        <div className={styles.badges}>
          <span className={`badge ${CATEGORY_BADGE[g.category] ?? 'badge-purple'}`}>{g.category}</span>
          <span className="badge badge-yellow">{g.color}</span>
        </div>
        <div className={styles.meta}>
          <span title="Veces usado">🔁 {g.times_used}x</span>
          {g.cost_per_wear > 0 && (
            <span title="Coste por uso">💰 {Number(g.cost_per_wear).toFixed(2)}€/uso</span>
          )}
        </div>
      </div>

      {/* Eliminar */}
      <button
        className={`btn btn-danger btn-sm ${styles.deleteBtn}`}
        onClick={onDelete}
        disabled={isDeleting}
        title="Eliminar prenda"
      >
        {isDeleting ? '...' : '🗑️'}
      </button>
    </div>
  );
}
