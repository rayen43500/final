import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ProductService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? onSale,
    String? sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Préparer la requête
      final queryParams = {
        if (category != null) 'category': category,
        if (minPrice != null) 'minPrice': minPrice.toString(),
        if (maxPrice != null) 'maxPrice': maxPrice.toString(),
        if (inStock != null) 'inStock': inStock.toString(),
        if (onSale != null) 'onSale': onSale.toString(),
        if (sortBy != null) 'sortBy': sortBy,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/produits').replace(queryParameters: queryParams);
      
      print('📍 Requête produits: $uri');
      
      // Récupérer le token si disponible
      final token = await _authService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      // Effectuer la requête
      final response = await http.get(uri, headers: headers);
      
      // Analyser la réponse
      print('📊 Statut réponse: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Identifier le format de la réponse pour extraction correcte
        List<dynamic> productsList = [];
        
        if (responseData is List) {
          // Format 1: La réponse est directement une liste de produits
          productsList = responseData;
        } else if (responseData is Map) {
          // Format 2: La réponse est un objet avec une clé spécifique contenant les produits
          if (responseData.containsKey('products')) {
            productsList = responseData['products'] as List;
          } else if (responseData.containsKey('data')) {
            productsList = responseData['data'] as List;
          } else if (responseData.containsKey('produits')) {
            productsList = responseData['produits'] as List;
          } else {
            // Format 3: Structure inconnue, essayer de trouver des listes dans l'objet
            print('⚠️ Structure de réponse non reconnue: ${responseData.keys}');
            for (var key in responseData.keys) {
              if (responseData[key] is List) {
                productsList = responseData[key] as List;
                print('🔍 Liste trouvée dans la clé: $key');
                break;
              }
            }
          }
        }
        
        // Vérifier si on a trouvé des produits
        print('📦 ${productsList.length} produits trouvés dans la réponse');
        
        if (productsList.isNotEmpty) {
          return productsList;
        }
      }
      
      // Si on arrive ici, c'est qu'on n'a pas pu extraire de produits
      print('⚠️ Aucun produit trouvé ou erreur ${response.statusCode}, utilisation des données de test');
      return _getTestProducts();
      
    } catch (e) {
      print('❌ Erreur dans getProducts: $e');
      return _getTestProducts();
    }
  }
  
  // Fonction utilitaire pour trouver la première liste dans un Map
  List<dynamic>? _findFirstListInMap(Map<String, dynamic> map) {
    for (var entry in map.entries) {
      if (entry.value is List) {
        print('Found list in key: ${entry.key}');
        return entry.value;
      } else if (entry.value is Map) {
        final nestedResult = _findFirstListInMap(Map<String, dynamic>.from(entry.value));
        if (nestedResult != null) {
          return nestedResult;
        }
      }
    }
    return null;
  }
  
  // Produits de test pour le débogage
  List<dynamic> _getTestProducts() {
    return [
      {
        '_id': 'test1',
        'nom': 'Produit Test 1',
        'description': 'Description du produit test 1',
        'prix': 100.0,
        'stock': 10,
        'images': ['https://via.placeholder.com/150'],
      },
      {
        '_id': 'test2',
        'nom': 'Produit Test 2',
        'description': 'Description du produit test 2',
        'prix': 200.0,
        'prixFinal': 160.0,
        'stock': 5,
        'images': ['https://via.placeholder.com/150'],
      },
      {
        '_id': 'test3',
        'nom': 'Produit Test 3',
        'description': 'Description du produit test 3',
        'prix': 300.0,
        'stock': 0,
        'images': ['https://via.placeholder.com/150'],
      },
    ];
  }

  Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/produits/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<dynamic>> searchProducts(String query, {int limit = 10}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/produits/search?q=$query&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['products'] ?? [];
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 