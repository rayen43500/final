class ApiConfig {
  // Configuration de l'URL de l'API
  
  // ATTENTION: localhost ne fonctionne pas sur les appareils physiques!
  // Pour les appareils physiques ou émulateurs, utilisez l'adresse IP de votre ordinateur
  // 10.0.2.2 est l'adresse spéciale pour accéder à localhost depuis l'émulateur Android
  // 127.0.0.1 fonctionne sur le simulateur iOS

  // Pour les tests sur appareil physique, utilisez votre IP locale:
  static const String baseUrl = 'http://localhost:5000/api';
  
  // URL pour émulateur Android (commentée)
  // static const String baseUrl = 'http://10.0.2.2:5000/api';
  
  // Timeouts (en millisecondes)
  static const int connectionTimeout = 30000; // 30 secondes
  static const int receiveTimeout = 30000;    // 30 secondes
  
  // Pour le débogage - activer les logs détaillés
  static const bool enableDetailedLogs = true;
  
  // Si true, utilise des données de test en cas d'échec de l'API
  static const bool useTestDataOnFailure = true;
} 