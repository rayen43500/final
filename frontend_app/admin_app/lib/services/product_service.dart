import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ProductService {
  final AuthService _authService = AuthService();
  final String baseUrl = ApiConfig.baseUrl;
  final _logger = Logger();

  // Récupérer tous les produits
  Future<Map<String, dynamic>> getProducts({
    String? search,
    String? category,
    int page = 1,
    int limit = 10,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // Construire l'URL avec les paramètres de requête
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (page > 0) queryParams['page'] = page.toString();
      if (limit > 0) queryParams['limit'] = limit.toString();
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      if (sortOrder != null && sortOrder.isNotEmpty) queryParams['sortOrder'] = sortOrder;

      final uri = Uri.parse('$baseUrl/api/produits').replace(queryParameters: queryParams);
      _logger.i('Récupération des produits: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Produits récupérés avec succès. Total: ${data['total']}');
        return data;
      } else {
        final error = json.decode(response.body)['message'] ?? 'Une erreur est survenue';
        _logger.e('Erreur lors de la récupération des produits: ${response.statusCode} - $error');
        throw Exception(error);
      }
    } catch (e) {
      _logger.e('Exception dans getProducts: $e');
      rethrow;
    }
  }

  // Récupérer un produit par son ID
  Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/produits/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec de récupération du produit: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans getProductById: $e');
      rethrow;
    }
  }

  // Créer un nouveau produit
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      // Log des données envoyées
      _logger.i('Envoi de données produit brutes: ${json.encode(productData)}');
      _logger.i('URL: $baseUrl/api/produits');

      // Créer un nouvel objet pour les données formatées (éviter les références)
      var formattedData = {};
      
      // Ajouter uniquement les champs nécessaires avec les types corrects
      formattedData['nom'] = productData['nom'] ?? 'Produit sans nom';
      formattedData['description'] = productData['description'] ?? 'Aucune description';
      
      // Convertir les valeurs numériques
      try {
        formattedData['prix'] = double.parse((productData['prix'] ?? '0').toString());
      } catch (e) {
        formattedData['prix'] = 0.0;
      }
      
      try {
        formattedData['stock'] = int.parse((productData['stock'] ?? '0').toString());
      } catch (e) {
        formattedData['stock'] = 0;
      }
      
      if (productData.containsKey('prixPromo') && productData['prixPromo'] != null && productData['prixPromo'].toString().isNotEmpty) {
        try {
          formattedData['prixPromo'] = double.parse(productData['prixPromo'].toString());
        } catch (e) {
          // Si la conversion échoue, ne pas inclure le champ
        }
      }
      
      if (productData.containsKey('discount') && productData['discount'] != null && productData['discount'].toString().isNotEmpty) {
        try {
          formattedData['discount'] = double.parse(productData['discount'].toString());
        } catch (e) {
          // Si la conversion échoue, ne pas inclure le champ
        }
      }
      
      // Traitement spécial pour isActive (booléen)
      if (productData.containsKey('isActive')) {
        formattedData['isActive'] = productData['isActive'] == true || productData['isActive'] == 'true';
      } else {
        formattedData['isActive'] = true;
      }
      
      // Gestion de categoryId
      String categoryId = "6507c23ec02f8aedec3a45cc"; // ID par défaut
      
      if (productData.containsKey('categoryId') && productData['categoryId'] != null && productData['categoryId'].toString().isNotEmpty) {
        categoryId = productData['categoryId'].toString();
      } else if (productData.containsKey('categorie') && productData['categorie'] != null) {
        if (productData['categorie'] is Map) {
          categoryId = productData['categorie']['_id']?.toString() ?? categoryId;
        } else {
          // Pour l'instant, utiliser l'ID par défaut
          _logger.w('Catégorie sous forme de chaîne, utilisation ID par défaut: $categoryId');
        }
      }
      
      formattedData['categoryId'] = categoryId;
      
      // Gestion des images
      List<String> images = [];
      if (productData.containsKey('images')) {
        if (productData['images'] is List) {
          images = (productData['images'] as List)
              .map((img) => img is String ? img : img.toString())
              .toList();
        } else if (productData['images'] is String && productData['images'].toString().isNotEmpty) {
          images = [productData['images'].toString()];
        }
      }
      
      // S'assurer qu'il y a au moins une image
      if (images.isEmpty) {
        images = ['https://via.placeholder.com/400x300?text=Produit'];
      }
      
      formattedData['images'] = images;

      _logger.i('Données formatées finales: ${json.encode(formattedData)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/produits'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(formattedData),
      );

      _logger.i('Réponse du serveur: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        _logger.e('Échec de création du produit: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de création du produit: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans createProduct: $e');
      rethrow;
    }
  }

  // Mettre à jour un produit
  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      // Log des données envoyées
      _logger.i('Mise à jour produit brutes: ${json.encode(productData)}');
      _logger.i('URL: $baseUrl/api/produits/$id');

      // Créer un nouvel objet pour les données formatées (éviter les références)
      var formattedData = {};
      
      // Ajouter uniquement les champs qui ont été fournis
      if (productData.containsKey('nom')) {
        formattedData['nom'] = productData['nom'];
      }
      
      if (productData.containsKey('description')) {
        formattedData['description'] = productData['description'];
      }
      
      // Convertir les valeurs numériques
      if (productData.containsKey('prix')) {
        try {
          formattedData['prix'] = double.parse(productData['prix'].toString());
        } catch (e) {
          _logger.w('Erreur de conversion du prix: $e');
        }
      }
      
      if (productData.containsKey('stock')) {
        try {
          formattedData['stock'] = int.parse(productData['stock'].toString());
        } catch (e) {
          _logger.w('Erreur de conversion du stock: $e');
        }
      }
      
      if (productData.containsKey('prixPromo')) {
        try {
          formattedData['prixPromo'] = double.parse(productData['prixPromo'].toString());
        } catch (e) {
          _logger.w('Erreur de conversion du prixPromo: $e');
        }
      }
      
      if (productData.containsKey('discount')) {
        try {
          formattedData['discount'] = double.parse(productData['discount'].toString());
        } catch (e) {
          _logger.w('Erreur de conversion du discount: $e');
        }
      }
      
      // Traitement spécial pour isActive (booléen)
      if (productData.containsKey('isActive')) {
        formattedData['isActive'] = productData['isActive'] == true || productData['isActive'] == 'true';
      }
      
      // Gestion de categoryId
      if (productData.containsKey('categoryId') && productData['categoryId'] != null && productData['categoryId'].toString().isNotEmpty) {
        formattedData['categoryId'] = productData['categoryId'].toString();
      } else if (productData.containsKey('categorie') && productData['categorie'] != null) {
        if (productData['categorie'] is Map) {
          formattedData['categoryId'] = productData['categorie']['_id']?.toString();
        }
      }
      
      // Gestion des images
      if (productData.containsKey('images')) {
        List<String> images = [];
        if (productData['images'] is List) {
          images = (productData['images'] as List)
              .map((img) => img is String ? img : img.toString())
              .toList();
        } else if (productData['images'] is String && productData['images'].toString().isNotEmpty) {
          images = [productData['images'].toString()];
        }
        
        if (images.isNotEmpty) {
          formattedData['images'] = images;
        }
      }

      _logger.i('Données formatées pour mise à jour: ${json.encode(formattedData)}');

      final response = await http.put(
        Uri.parse('$baseUrl/api/produits/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(formattedData),
      );

      _logger.i('Réponse du serveur: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        _logger.e('Échec de mise à jour du produit: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de mise à jour du produit: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans updateProduct: $e');
      rethrow;
    }
  }

  // Rechercher des produits
  Future<List<dynamic>> searchProducts(String query, {int limit = 10}) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/produits/search?q=$query&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec de recherche des produits: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans searchProducts: $e');
      rethrow;
    }
  }

  // Réapprovisionner le stock d'un produit
  Future<Map<String, dynamic>> restockProduct(String id, int quantity, {String? reference, String? commentaire}) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/produits/$id/restock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'quantity': quantity,
          'référence': reference,
          'commentaire': commentaire,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec de réapprovisionnement du produit: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans restockProduct: $e');
      rethrow;
    }
  }

  // Obtenir les produits en rupture de stock ou en stock faible
  Future<Map<String, dynamic>> getLowStockProducts({int threshold = 5}) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/produits/inventory/low-stock?threshold=$threshold'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec de récupération des produits en stock faible: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans getLowStockProducts: $e');
      rethrow;
    }
  }

  // Ajuster le stock d'un produit
  Future<Map<String, dynamic>> adjustStock(String id, int nouveauStock, {String? commentaire}) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/produits/$id/adjust-stock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nouveauStock': nouveauStock,
          'commentaire': commentaire,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec d\'ajustement du stock: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans adjustStock: $e');
      rethrow;
    }
  }

  // Obtenir toutes les catégories
  Future<List<dynamic>> getCategories() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Catégories récupérées: ${data.length}');
        return data;
      } else {
        throw Exception('Échec de récupération des catégories: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans getCategories: $e');
      // Retourner une liste vide en cas d'erreur pour éviter les crashs
      return [];
    }
  }
  
  // Créer une nouvelle catégorie
  Future<Map<String, dynamic>> createCategory(String nom, String description) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      // Générer un slug à partir du nom
      final slug = nom.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nom': nom,
          'description': description,
          'slug': slug
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        _logger.i('Catégorie créée: ${data['_id']}');
        return data;
      } else {
        throw Exception('Échec de création de la catégorie: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans createCategory: $e');
      rethrow;
    }
  }

  // Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      _logger.i('Suppression du produit: $productId');

      final response = await http.delete(
        Uri.parse('$baseUrl/api/produits/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _logger.i('Produit supprimé avec succès');
      } else {
        final error = json.decode(response.body)['message'] ?? 'Une erreur est survenue';
        _logger.e('Erreur lors de la suppression du produit: ${response.statusCode} - $error');
        throw Exception(error);
      }
    } catch (e) {
      _logger.e('Exception dans deleteProduct: $e');
      rethrow;
    }
  }
} 