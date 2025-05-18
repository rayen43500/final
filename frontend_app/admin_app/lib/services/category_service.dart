import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class CategoryService {
  final AuthService _authService = AuthService();
  final String baseUrl = ApiConfig.baseUrl;
  final _logger = Logger();

  // Récupérer toutes les catégories
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
        _logger.i('Catégories récupérées: ${data.length} catégories');
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

  // Récupérer une catégorie par son ID
  Future<Map<String, dynamic>> getCategoryById(String id) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.categoriesPath}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec de récupération de la catégorie: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans getCategoryById: $e');
      rethrow;
    }
  }

  // Créer une nouvelle catégorie
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      _logger.i('Création de catégorie: ${json.encode(categoryData)}');

      // Préparer les données à envoyer
      final formattedData = {
        'nom': categoryData['nom'],
        'description': categoryData['description'],
        'slug': categoryData['nom'].toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
        'isActive': categoryData['actif'] ?? true
      };

      // Ajouter les champs personnalisés pour la sauvegarde côté backend
      if (categoryData.containsKey('colorName')) {
        formattedData['colorName'] = categoryData['colorName'];
      }
      
      if (categoryData.containsKey('iconName')) {
        formattedData['iconName'] = categoryData['iconName'];
      }

      // Ajouter la catégorie parente si elle existe
      if (categoryData.containsKey('parentCategory') && categoryData['parentCategory'] != null) {
        formattedData['parentCategory'] = categoryData['parentCategory'];
      }

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.categoriesPath}'),
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
        _logger.e('Erreur serveur: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de création de la catégorie: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans createCategory: $e');
      rethrow;
    }
  }

  // Mettre à jour une catégorie
  Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> categoryData) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      _logger.i('Mise à jour de catégorie: ${json.encode(categoryData)}');

      // Préparer les données à envoyer
      final formattedData = {};
      
      if (categoryData.containsKey('nom')) {
        formattedData['nom'] = categoryData['nom'];
      }
      
      if (categoryData.containsKey('description')) {
        formattedData['description'] = categoryData['description'];
      }
      
      // Gérer les données spécifiques à l'UI
      if (categoryData.containsKey('colorName')) {
        formattedData['colorName'] = categoryData['colorName'];
      }
      
      if (categoryData.containsKey('iconName')) {
        formattedData['iconName'] = categoryData['iconName'];
      }
      
      // Conversion du champ 'actif' vers le nom du champ backend 'isActive'
      if (categoryData.containsKey('actif')) {
        formattedData['isActive'] = categoryData['actif'];
      }
      
      if (categoryData.containsKey('parentCategory')) {
        formattedData['parentCategory'] = categoryData['parentCategory'];
      }

      final response = await http.put(
        Uri.parse('$baseUrl${ApiConfig.categoriesPath}/$id'),
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
        _logger.e('Erreur serveur: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de mise à jour de la catégorie: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans updateCategory: $e');
      rethrow;
    }
  }

  // Supprimer une catégorie
  Future<bool> deleteCategory(String id) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl${ApiConfig.categoriesPath}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      _logger.i('Réponse du serveur: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final responseData = json.decode(response.body);
        _logger.e('Erreur serveur: ${response.statusCode} - ${response.body}');
        throw Exception(responseData['message'] ?? 'Échec de suppression de la catégorie');
      }
    } catch (e) {
      _logger.e('Erreur dans deleteCategory: $e');
      rethrow;
    }
  }

  // Obtenir les statistiques des produits par catégorie
  Future<List<Map<String, dynamic>>> getCategoriesWithStats() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.categoriesPath}/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        _logger.e('Erreur serveur: ${response.statusCode} - ${response.body}');
        throw Exception('Échec de récupération des statistiques: ${response.body}');
      }
    } catch (e) {
      _logger.e('Erreur dans getCategoriesWithStats: $e');
      // Retourner une liste vide en cas d'erreur
      return [];
    }
  }
} 