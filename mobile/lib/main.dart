/// main.dart — Punto de entrada de la app ClosetAI
/// Inicializa Supabase y gestiona el routing autenticado
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'screens/capture_screen.dart';

// ── Credenciales Supabase ─────────────────────────────────────────────────────
// ⚠️ Reemplaza estos valores con los de tu proyecto Supabase
// (Settings → API → Project URL y anon/public key)
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://TU_PROJECT_ID.supabase.co',   // ← cambia esto
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',  // ← cambia esto
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación solo vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Estilo de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:           Colors.transparent,
    statusBarIconBrightness:  Brightness.light,
    systemNavigationBarColor: AppTheme.bgDark,
  ));

  // Inicializar Supabase
  await Supabase.initialize(
    url:    _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(const ClosetAiApp());
}

class ClosetAiApp extends StatelessWidget {
  const ClosetAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:        'ClosetAI',
      debugShowCheckedModeBanner: false,
      theme:        AppTheme.darkTheme,
      home:         const AuthGate(),
    );
  }
}

// ── Auth Gate — decide si mostrar Login o la app principal ────────────────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session
            ?? Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}

// ── Main Shell — Bottom Navigation Bar con las 3 pantallas ───────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _goToAdd() => setState(() => _selectedIndex = 2);
  void _goToWardrobe() => setState(() => _selectedIndex = 1);

  late final List<Widget> _pages = [
    const DashboardScreen(),
    WardrobeScreen(onAddGarment: _goToAdd),
    CaptureScreen(onGarmentAdded: _goToWardrobe),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
        height: 65,
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primary),
            label:        'Inicio',
          ),
          NavigationDestination(
            icon:         Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom_rounded, color: AppTheme.primary),
            label:        'Armario',
          ),
          NavigationDestination(
            icon:         Icon(Icons.add_a_photo_outlined),
            selectedIcon: Icon(Icons.add_a_photo_rounded, color: AppTheme.primary),
            label:        'Añadir',
          ),
        ],
      ),
    );
  }
}
