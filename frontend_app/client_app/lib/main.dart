import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'theme/simplified_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'services/local_review_service.dart';
// No direct import of flutter_local_notifications to avoid Linux platform issues

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les données d'avis de test
  final reviewService = LocalReviewService();
  await reviewService.initializeWithMockData();
  
  // Définir l'orientation de l'application en mode portrait uniquement
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Personnaliser la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'BIN FLOW',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            initialRoute: auth.isAuthenticated ? '/' : '/login',
            routes: {
              '/': (context) {
                // Récupérer les arguments de navigation
                final args = ModalRoute.of(context)?.settings.arguments;
                final goToCommandes = args is Map<String, dynamic> && args['goToCommandes'] == true;
                
                // Si on vient de se connecter depuis l'écran des commandes, 
                // afficher directement l'onglet des commandes
                return HomeScreen(initialIndex: goToCommandes ? 3 : 0);
              },
              '/login': (context) => const LoginScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/chat': (context) => const ChatScreen(),
            },
          );
        },
      ),
    );
  }
}
