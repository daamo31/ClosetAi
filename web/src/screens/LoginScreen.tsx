// src/screens/LoginScreen.tsx
import { useState } from 'react';
import { supabase } from '../config/api';
import styles from './LoginScreen.module.css';

export default function LoginScreen() {
  const [isRegister, setIsRegister] = useState(false);
  const [email, setEmail]           = useState('');
  const [password, setPassword]     = useState('');
  const [loading, setLoading]       = useState(false);
  const [error, setError]           = useState('');
  const [success, setSuccess]       = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setSuccess('');
    setLoading(true);

    try {
      if (isRegister) {
        const { error: err } = await supabase.auth.signUp({ email, password });
        if (err) throw err;
        setSuccess('✅ Cuenta creada. Revisa tu email para confirmarla y luego inicia sesión.');
      } else {
        const { error: err } = await supabase.auth.signInWithPassword({ email, password });
        if (err) throw err;
        // El cambio de sesión lo captura App.tsx con onAuthStateChange
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Error desconocido';
      setError(translateError(msg));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className={styles.wrap}>
      <span className={styles.logo}>🧥</span>
      <h1 className={styles.title}>ClosetAI</h1>
      <p className={styles.sub}>Tu asesor de moda personal con IA</p>

      <form className={styles.form} onSubmit={handleSubmit}>
        {error   && <p className="error-msg">{error}</p>}
        {success && <p className="success-msg">{success}</p>}

        <div className="input-group">
          <label htmlFor="email">Email</label>
          <input
            id="email"
            type="email"
            className="input-field"
            placeholder="tu@email.com"
            value={email}
            onChange={e => setEmail(e.target.value)}
            required
            autoComplete="email"
          />
        </div>

        <div className="input-group">
          <label htmlFor="password">Contraseña</label>
          <input
            id="password"
            type="password"
            className="input-field"
            placeholder={isRegister ? 'Mínimo 6 caracteres' : '••••••••'}
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
            minLength={6}
            autoComplete={isRegister ? 'new-password' : 'current-password'}
          />
        </div>

        <button type="submit" className="btn btn-primary" disabled={loading}>
          {loading ? <span className="spinner" style={{ width: 20, height: 20, borderWidth: 2 }} /> : null}
          {isRegister ? 'Crear cuenta' : 'Iniciar sesión'}
        </button>

        <button
          type="button"
          className={styles.toggle}
          onClick={() => { setIsRegister(r => !r); setError(''); setSuccess(''); }}
        >
          {isRegister ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate'}
        </button>
      </form>
    </div>
  );
}

function translateError(msg: string): string {
  if (msg.includes('Invalid login credentials')) return 'Email o contraseña incorrectos.';
  if (msg.includes('Email not confirmed'))       return 'Confirma tu email antes de entrar.';
  if (msg.includes('already registered'))        return 'Este email ya está registrado.';
  if (msg.includes('Password should be'))        return 'La contraseña debe tener al menos 6 caracteres.';
  return msg;
}
