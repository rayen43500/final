import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/produits.dart';
import 'pages/commandes.dart';
import 'pages/utilisateurs.dart';
import 'pages/statistique.dart';
import 'pages/livreurs.dart';
import 'pages/promotions.dart';
import 'pages/categorie.dart';
import 'config/app_style.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIN FLOW Admin',
      debugShowCheckedModeBanner: false,
      theme: AppStyle.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginPage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/dashboard': (context) => const AdminDashboardPage(),
        '/products': (context) => const ProduitsPage(),
        '/orders': (context) => const CommandesPage(),
        '/users': (context) => const UtilisateursPage(),
        '/stats': (context) => const StatistiquePage(),
        '/delivery': (context) => const LivreursPage(),
        '/promotions': (context) => const PromotionsPage(),
        '/categories': (context) => const CategoriePage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (!isLoggedIn) {
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
      return;
    }

    // Verifier que le token est toujours valide
    final isTokenValid = await _authService.validateToken();
    
    if (!isTokenValid) {
      await _authService.logout();
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
      return;
    }

    final user = await _authService.getCurrentUser();
    final isAdmin = user?['role'] == 'Admin';

    setState(() {
      _isLoading = false;
      _isLoggedIn = true;
      _isAdmin = isAdmin;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppStyle.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppStyle.buildLogo(height: 80),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: AppStyle.primaryColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Chargement...',
                style: AppStyle.bodyStyle,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return const LoginPage();
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppStyle.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppStyle.buildLogo(height: 60),
              const SizedBox(height: 40),
              const Icon(
                Icons.lock_outlined,
                size: 64,
                color: AppStyle.errorColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Accès non autorisé',
                style: AppStyle.subheadingStyle,
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Vous n\'avez pas les droits d\'administration nécessaires',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppStyle.textSecondaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _authService.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Déconnexion',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  style: AppStyle.primaryButtonStyle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const AdminDashboardPage();
  }
}