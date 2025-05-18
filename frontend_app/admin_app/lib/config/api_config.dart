class ApiConfig {
  // URL de base de l'API
  static const String baseUrl = 'http://localhost:5000';
  
  // Timeouts pour les requêtes HTTP (en secondes)
  static const int connectTimeout = 15;
  static const int receiveTimeout = 15;
  
  // Chemins d'API
  static const String authPath = '/api/auth';
  static const String productsPath = '/api/produits';
  static const String categoriesPath = '/api/categories';
  static const String ordersPath = '/api/commandes';
  static const String usersPath = '/api/utilisateurs';
  static const String statsPath = '/api/statistiques';
  static const String promoPath = '/api/promotions';
  static const String deliveryPath = '/api/livreurs';
} 