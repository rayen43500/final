import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;
  final _storage = const FlutterSecureStorage();
  final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, lineLength: 80),
  );

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _logger.i('Tentative de connexion avec: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.authPath}/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'motDePasse': password,
        }),
      );

      _logger.i('Statut de la réponse: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        _logger.d('Réponse du serveur: ${response.body}');
        
        // Vérifier si l'utilisateur est un admin
        if (data['user']['role'] != 'Admin') {
          _logger.w('Rôle non autorisé: ${data['user']['role']}');
          throw Exception('Accès non autorisé. Seuls les administrateurs peuvent se connecter.');
        }

        _logger.i('Connexion réussie pour: ${data['user']['nom']} (${data['user']['role']})');
        
        // Stocker les tokens et les informations utilisateur
        await _storage.write(key: 'token', value: data['token']);
        await _storage.write(key: 'refreshToken', value: data['refreshToken']);
        await _storage.write(key: 'user', value: jsonEncode(data['user']));

        return {
          'token': data['token'],
          'refreshToken': data['refreshToken'],
          'user': data['user'],
        };
      } else {
        _logger.e('Erreur de connexion: ${response.body}');
        final error = jsonDecode(response.body);
        if (error['errors'] != null && error['errors']['motDePasse'] != null) {
          throw Exception(error['errors']['motDePasse']);
        }
        throw Exception(error['message'] ?? 'Erreur de connexion');
      }
    } catch (e) {
      _logger.e('Exception lors de la connexion: $e');
      if (e is http.ClientException) {
        throw Exception('Erreur de connexion au serveur. Veuillez vérifier votre connexion internet et l\'URL du serveur.');
      }
      if (e is FormatException) {
        throw Exception('Erreur de format de réponse du serveur. Vérifiez que le serveur fonctionne correctement.');
      }
      // Renvoi de l'exception originale si elle est déjà bien formatée
      if (e.toString().startsWith('Exception: ')) {
        throw e;
      }
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      _logger.i('Déconnexion de l\'utilisateur');
      await _storage.deleteAll();
      _logger.i('Stockage effacé avec succès');
    } catch (e) {
      _logger.e('Erreur lors de la déconnexion: $e');
      throw Exception('Erreur lors de la déconnexion');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: 'token');
      final userStr = await _storage.read(key: 'user');
      
      if (token == null || userStr == null) {
        _logger.i('Aucun token ou utilisateur trouvé dans le stockage');
        return false;
      }
      
      final user = jsonDecode(userStr);
      final isAdmin = user['role'] == 'Admin';
      
      _logger.i('Vérification de connexion: ${isAdmin ? 'Administrateur connecté' : 'Utilisateur non-admin'}');
      
      return isAdmin;
    } catch (e) {
      _logger.e('Erreur lors de la vérification de connexion: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userStr = await _storage.read(key: 'user');
      if (userStr != null) {
        final user = jsonDecode(userStr);
        _logger.i('Utilisateur actuel récupéré: ${user['nom']} (${user['role']})');
        _logger.i('Données utilisateur complètes: $user');
        return user;
      }
      _logger.i('Aucun utilisateur trouvé dans le stockage');
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: 'token');
      return token;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      return refreshToken;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du refresh token: $e');
      return null;
    }
  }
  
  // Méthode pour vérifier si le token est valide
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;
      
      // Vous pouvez ajouter une requête au backend pour valider le token si nécessaire
      // Par exemple:
      /*
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify-token'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
      */
      
      // Pour l'instant, nous considérons un token comme valide s'il existe
      return true;
    } catch (e) {
      _logger.e('Erreur lors de la validation du token: $e');
      return false;
    }
  }

  // Méthode pour tester la connexion avec un appel API authentifié
  Future<bool> testAuthenticatedRequest() async {
    try {
      final token = await getToken();
      if (token == null) {
        _logger.w('Pas de token disponible pour la requête authentifiée');
        return false;
      }
      
      _logger.i('Test de requête authentifiée avec token');
      
      // Faire une requête authentifiée à une API qui nécessite des droits admin
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/dashboard'), // Exemple d'API réservée aux admins
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      _logger.i('Réponse du test d\'authentification: ${response.statusCode}');
      
      // Si la réponse est 200, l'authentification fonctionne correctement
      // Si la réponse est 401 ou 403, il y a un problème d'authentification
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Erreur lors du test d\'authentification: $e');
      return false;
    }
  }
} 