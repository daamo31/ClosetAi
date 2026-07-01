// src/components/NavBar.tsx
import type { Screen } from '../types';
import styles from './NavBar.module.css';

interface Props {
  current: Screen;
  onChange: (s: Screen) => void;
}

const ITEMS: { id: Screen; icon: string; label: string }[] = [
  { id: 'dashboard', icon: '🏠', label: 'Inicio' },
  { id: 'wardrobe',  icon: '👕', label: 'Armario' },
  { id: 'upload',    icon: '➕', label: 'Añadir' },
  { id: 'outfit',    icon: '✨', label: 'Outfit' },
];

export default function NavBar({ current, onChange }: Props) {
  return (
    <nav className={styles.nav}>
      {ITEMS.map(({ id, icon, label }) => (
        <button
          key={id}
          className={`${styles.item} ${current === id ? styles.active : ''}`}
          onClick={() => onChange(id)}
          aria-label={label}
        >
          <span className={styles.icon}>{icon}</span>
          {label}
        </button>
      ))}
    </nav>
  );
}
