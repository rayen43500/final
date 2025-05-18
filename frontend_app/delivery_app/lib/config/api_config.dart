class ApiConfig {
  // Configuration de l'API
  // URL de base de l'API
  static const String baseUrl = 'http://localhost:5000';
  
  // Méthode pour obtenir l'URL de base adaptée à l'environnement
  static String getBaseUrl() {
    return baseUrl;
  }
  
  // Timeouts pour les requêtes HTTP (en secondes)
  static const int connectTimeout = 15;
  static const int receiveTimeout = 15;
  
  // Pour le débogage - activer les logs détaillés
  static const bool enableDetailedLogs = true;
  
  // Désactiver la vérification de connexion au démarrage
  static const bool skipConnectionCheck = false;
  
  // Headers par défaut pour les requêtes API
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Endpoints API
  static const String loginEndpoint = '/api/auth/login';
  static const String loginAlternativeEndpoint = '/api/users/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String refreshTokenEndpoint = '/api/auth/refresh-token';
  static const String profileEndpoint = '/api/users/me';
  static const String statusEndpoint = '/api/status';
  static const String deliveryOrdersEndpoint = '/api/orders/delivery/mes-livraisons';
  static const String updateOrderStatusEndpoint = '/api/orders/delivery/{id}/status';
  
  // Si true, utilise des données de test en cas d'échec de l'API
  static const bool useTestDataOnFailure = false;
} 