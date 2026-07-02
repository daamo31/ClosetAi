// src/App.tsx — Enrutador principal de ClosetAI Web
import { useEffect, useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from './config/api';
import type { Screen } from './types';

import NavBar            from './components/NavBar';
import LoginScreen       from './screens/LoginScreen';
import DashboardScreen   from './screens/DashboardScreen';
import WardrobeScreen    from './screens/WardrobeScreen';
import UploadScreen      from './screens/UploadScreen';
import OutfitScreen      from './screens/OutfitScreen';
import TryOnScreen       from './screens/TryOnScreen';

export default function App() {
  const [session, setSession] = useState<Session | null | undefined>(undefined);
  const [screen, setScreen]   = useState<Screen>('dashboard');

  // Escucha cambios de sesión (login / logout / token refresh)
  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setSession(data.session));
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s);
      if (!s) setScreen('dashboard'); // reset al salir
    });
    return () => subscription.unsubscribe();
  }, []);

  // Cargando sesión inicial
  if (session === undefined) {
    return (
      <div className="loading-center" style={{ minHeight: '100dvh' }}>
        <div className="spinner" />
        <span>Cargando ClosetAI...</span>
      </div>
    );
  }

  // No autenticado → Login
  if (!session) return <LoginScreen />;

  // Autenticado → App completa
  return (
    <>
      {screen === 'dashboard' && <DashboardScreen onNavigate={setScreen} />}
      {screen === 'wardrobe'  && <WardrobeScreen />}
      {screen === 'upload'    && <UploadScreen onSuccess={() => setScreen('wardrobe')} />}
      {screen === 'outfit'    && <OutfitScreen />}
      {screen === 'tryon'     && <TryOnScreen />}
      <NavBar current={screen} onChange={setScreen} />
    </>
  );
}
