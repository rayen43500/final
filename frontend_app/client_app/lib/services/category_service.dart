import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class CategoryService {
  final String baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getCategories() async {
    try {
      // URL de l'API
      print('📍 Requête catégories: $baseUrl/categories');
      
      // Récupérer le token si disponible
      final token = await _authService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      // Effectuer la requête
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
      );

      // Analyser la réponse
      print('📊 Statut réponse catégories: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Identifier le format de la réponse pour extraction correcte
        List<dynamic> categoriesList = [];
        
        if (responseData is List) {
          // Format 1: La réponse est directement une liste de catégories
          categoriesList = responseData;
          print('📂 Réponse directement au format liste: ${categoriesList.length} catégories');
        } else if (responseData is Map) {
          // Format 2: La réponse est un objet avec une clé spécifique
          print('📂 Réponse au format Map avec clés: ${responseData.keys.toList()}');
          
          if (responseData.containsKey('categories')) {
            categoriesList = responseData['categories'] as List;
          } else if (responseData.containsKey('data')) {
            categoriesList = responseData['data'] as List;
          } else {
            // Format 3: Structure inconnue, chercher des listes
            for (var key in responseData.keys) {
              if (responseData[key] is List) {
                categoriesList = responseData[key] as List;
                print('🔍 Liste trouvée dans la clé: $key');
                break;
              }
            }
          }
        }
        
        // Vérifier si on a trouvé des catégories
        print('📂 ${categoriesList.length} catégories trouvées dans la réponse');
        
        if (categoriesList.isNotEmpty) {
          return categoriesList;
        }
      }
      
      // Si on arrive ici, c'est qu'on n'a pas pu extraire de catégories
      print('⚠️ Aucune catégorie trouvée ou erreur ${response.statusCode}');
      return _getTestCategories();
      
    } catch (e) {
      print('❌ Erreur dans getCategories: $e');
      return _getTestCategories();
    }
  }
  
  // Fonction utilitaire pour trouver la première liste dans un Map
  List<dynamic>? _findFirstListInMap(Map<dynamic, dynamic> map) {
    for (var entry in map.entries) {
      if (entry.value is List) {
        print('Found list in key: ${entry.key}');
        return entry.value as List<dynamic>;
      } else if (entry.value is Map) {
        try {
          final result = _findFirstListInMap(entry.value as Map<dynamic, dynamic>);
          if (result != null) {
            return result;
          }
        } catch (e) {
          print('Error processing nested map: $e');
        }
      }
    }
    return null;
  }
  
  // Catégories de test pour le débogage
  List<dynamic> _getTestCategories() {
    return [
      {
        '_id': 'cat1',
        'nom': 'Soins du visage',
        'iconName': 'face',
        'colorName': 'blue',
        'productCount': 12
      },
      {
        '_id': 'cat2',
        'nom': 'Décorations naturelles',
        'iconName': 'spa',
        'colorName': 'green',
        'productCount': 8
      },
      {
        '_id': 'cat3',
        'nom': 'Hygiène',
        'iconName': 'hygiene',
        'colorName': 'teal',
        'productCount': 15
      },
      {
        '_id': 'cat4',
        'nom': 'Bien-être',
        'iconName': 'spa',
        'colorName': 'purple',
        'productCount': 7
      },
      {
        '_id': 'cat5',
        'nom': 'Compléments',
        'iconName': 'fitness',
        'colorName': 'orange',
        'productCount': 9
      },
      {
        '_id': 'cat6',
        'nom': 'Bébé',
        'iconName': 'baby',
        'colorName': 'red',
        'productCount': 6
      },
    ];
  }

  Future<Map<String, dynamic>> getCategoryById(String id) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load category');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<dynamic>> getCategoryProducts(String categoryId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/produits?category=$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['products'];
      } else {
        throw Exception('Failed to load category products');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
} 