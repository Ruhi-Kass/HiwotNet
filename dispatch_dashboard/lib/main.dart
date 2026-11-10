import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/landing_page.dart';
import 'screens/registration_page.dart';
import 'screens/login_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/admin/admin_login_page.dart';
import 'screens/admin/admin_dashboard_page.dart';
import 'screens/admin/admin_analytics_page.dart';
import 'screens/admin/user_management_page.dart';
import 'screens/admin/hospital_registry_page.dart';
import 'screens/admin/audit_logs_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart' as db;
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await db.FirebaseService.seedIfEmpty();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  _safeRunApp(const DispatchApp());
}

void _safeRunApp(Widget app) {
  final view = ui.PlatformDispatcher.instance.implicitView ??
      (ui.PlatformDispatcher.instance.views.isNotEmpty
          ? ui.PlatformDispatcher.instance.views.first
          : null);
  if (view != null) {
    runWidget(View(view: view, child: app));
  } else {
    runApp(app);
  }
}

/// Route map for the whole app:
///
/// Dispatcher-facing (4 screens):
///   /            Landing Page      (public)
///   /register    Registration      (public form, result is pending-approval)
///   /login       Dispatcher Login  (public form, only path into /dashboard)
///   /dashboard   Live Map & Routing (the operational console)
///
/// Admin Panel — the "reasoned addition" for platform-level account/role
/// management (the dispatcher spec defines four operating roles but never
/// says who provisions them):
///   /admin/login   Admin Login    (separate credential pool + 2FA)
///   /admin         Admin Dashboard
///   /admin/users   User Management
///   /admin/registry  Hospital & Ambulance Registry
///   /admin/logs    System / Audit Logs
///
/// The two consoles are deliberately kept on separate route trees and
/// separate login screens rather than one shared login — a dispatcher
/// account must never be able to reach `/admin/*`, and vice versa, so
/// there is no single auth gate the two could accidentally share.
///
/// Per the Portability NFR this is a plain routed Flutter *web* app — it
/// runs inside a normal browser window and uses the address bar, rather
/// than assuming a fixed app-shell size or requiring installation.
final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final auth = AuthService.instance;
    final isAuth = auth.isAuthenticated;
    final role = auth.currentRole;
    final loc = state.matchedLocation;

    // Dispatcher workstation gate: requires authentication
    if (loc == '/dashboard') {
      if (!isAuth || (role != 'dispatcher' && role != 'admin')) {
        return '/login';
      }
    }

    // Admin console gate: requires admin privileges
    if (loc.startsWith('/admin') && loc != '/admin/login') {
      if (!isAuth || role != 'admin') {
        return '/admin/login';
      }
    }

    // If already authenticated as dispatcher and user hits login page, keep them in their account
    if (loc == '/login' && isAuth && role == 'dispatcher') {
      return '/dashboard';
    }

    // If already authenticated as admin and user hits admin login page, keep them in their account
    if (loc == '/admin/login' && isAuth && role == 'admin') {
      return '/admin';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LandingPage()),
    GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
        path: '/dashboard', builder: (context, state) => const DashboardPage()),
    GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginPage()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardPage()),
    GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminAnalyticsPage()),
    GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementPage()),
    GoRoute(
        path: '/admin/registry',
        builder: (context, state) => const HospitalRegistryPage()),
    GoRoute(path: '/admin/logs', builder: (context, state) => const AuditLogsPage()),
  ],
);

class DispatchApp extends StatelessWidget {
  const DispatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp.router(
          title: 'HIWONET-RESPONSE Dispatch Console',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(isDark: false),
          darkTheme: buildAppTheme(isDark: true),
          themeMode: currentMode,
          routerConfig: _router,
        );
      },
    );
  }
}
