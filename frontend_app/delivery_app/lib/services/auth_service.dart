import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;
  final storage = const FlutterSecureStorage();
  
  // Méthode pour authentifier un livreur
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.loginEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'email': email,
          'motDePasse': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Vérifier si l'utilisateur est un livreur
        if (data['user']['role'] != 'Livreur') {
          throw Exception('Accès non autorisé. Cette application est réservée aux livreurs.');
        }
        
        // Stocker les informations utilisateur et les tokens
        await storage.write(key: 'auth_token', value: data['token']);
        if (data.containsKey('refreshToken')) {
          await storage.write(key: 'refreshToken', value: data['refreshToken']);
        }
        await storage.write(key: 'user', value: json.encode(data['user']));
        
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur de connexion (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
    } on TimeoutException {
      throw Exception('Le serveur met trop de temps à répondre. Réessayez plus tard.');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }
  
  // Déconnexion et suppression des données stockées
  Future<void> logout() async {
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'refreshToken');
    await storage.delete(key: 'user');
  }
  
  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'auth_token');
    return token != null;
  }
  
  // Vérifier si l'utilisateur est authentifié et est un livreur
  Future<bool> isAuthenticatedLivreur() async {
    try {
      // Obtenir et vérifier le token
      final token = await getToken();
      if (token == null) {
        return false;
      }
      
      // Vérifier si l'utilisateur est un livreur
      final userStr = await storage.read(key: 'user');
      if (userStr == null) {
        return false;
      }
      
      final userData = json.decode(userStr);
      final user = User.fromJson(userData);
      
      return user.isLivreur() && user.isActive;
    } catch (e) {
      if (ApiConfig.enableDetailedLogs) {
        print('Erreur lors de la vérification du livreur: $e');
      }
      return false;
    }
  }
  
  // Obtenir les informations de l'utilisateur actuel
  Future<User?> getCurrentUser() async {
    try {
      // Tenter de récupérer les informations utilisateur depuis le stockage local
      final userStr = await storage.read(key: 'user');
      
      if (userStr != null) {
        final userData = json.decode(userStr);
        if (ApiConfig.enableDetailedLogs) {
          print('Informations utilisateur récupérées depuis le stockage local');
        }
        return User.fromJson(userData);
      }
      
      // Si pas d'infos utilisateur stockées, essayer de récupérer depuis le token
      if (ApiConfig.enableDetailedLogs) {
        print('Infos utilisateur non trouvées dans le stockage, tentative via token...');
      }
      
      final token = await getToken();
      
      if (token != null) {
        try {
          // Récupérer les informations utilisateur à partir du token JWT
          final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          
          // Vérifier si le payload contient des informations utilisateur
          if (decodedToken.containsKey('userId')) {
            // Récupérer les informations complètes de l'utilisateur
            return await getUserInfoFromAPI(decodedToken['userId']);
          }
        } catch (e) {
          if (ApiConfig.enableDetailedLogs) {
            print('Erreur lors de la récupération des infos depuis le token: $e');
          }
        }
      }
      
      return null;
    } catch (e) {
      if (ApiConfig.enableDetailedLogs) {
        print('Erreur getCurrentUser: $e');
      }
      return null;
    }
  }
  
  // Récupérer les informations de l'utilisateur depuis l'API
  Future<User?> getUserInfoFromAPI(String userId) async {
    try {
      if (ApiConfig.enableDetailedLogs) {
        print('Tentative de récupération des informations utilisateur depuis l\'API...');
      }
      
      final token = await getToken();
      
      if (token == null) {
        return null;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userMap = data['user'] ?? data;
        
        // Stocker les informations récupérées
        await storage.write(key: 'user', value: json.encode(userMap));
        
        if (ApiConfig.enableDetailedLogs) {
          print('Informations utilisateur mises à jour depuis l\'API');
        }
        
        return User.fromJson(userMap);
      } else {
        if (ApiConfig.enableDetailedLogs) {
          print('Erreur lors de la récupération des infos utilisateur: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (ApiConfig.enableDetailedLogs) {
        print('Exception lors de la récupération des infos utilisateur: $e');
      }
      return null;
    }
  }
  
  // Récupérer le token d'authentification avec vérification de validité
  Future<String?> getToken() async {
    try {
      final token = await storage.read(key: 'auth_token');
      
      if (token == null) {
        if (ApiConfig.enableDetailedLogs) {
          print('Aucun token trouvé dans le stockage');
        }
        return null;
      }
      
      // Vérifier si le token est expiré
      if (JwtDecoder.isExpired(token)) {
        if (ApiConfig.enableDetailedLogs) {
          print('Token expiré');
        }
        
        // Essayer de rafraîchir le token
        final refreshTokenValue = await getRefreshToken();
        if (refreshTokenValue != null) {
          try {
            final newTokenData = await refreshToken(refreshTokenValue);
            final newToken = newTokenData['token'];
            await storage.write(key: 'auth_token', value: newToken);
            
            if (ApiConfig.enableDetailedLogs) {
              print('Token rafraîchi avec succès');
            }
            
            return newToken;
          } catch (e) {
            if (ApiConfig.enableDetailedLogs) {
              print('Échec du rafraîchissement du token: $e');
            }
            
            await logout();
            return null;
          }
        } else {
          await logout();
          return null;
        }
      }
      
      return token;
    } catch (e) {
      if (ApiConfig.enableDetailedLogs) {
        print('Erreur lors de la récupération du token: $e');
      }
      return null;
    }
  }
  
  // Récupérer le refreshToken
  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refreshToken');
  }
  
  // Rafraîchir le token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.refreshTokenEndpoint}'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'refreshToken': refreshToken,
        }),
      );
  
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Échec du rafraîchissement du token');
      }
    } catch (e) {
      throw Exception('Erreur lors du rafraîchissement du token: ${e.toString()}');
    }
  }
  
  // Tester la connexion au backend
  Future<Map<String, dynamic>> testBackendConnection() async {
    try {
      // Au lieu d'utiliser /api/status qui n'existe pas, on essaie un autre endpoint
      // qui existe probablement sur le backend, comme l'URL de base
      final response = await http.get(
        Uri.parse('$baseUrl'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200 || response.statusCode == 404) {
        // On considère que le serveur est en ligne même s'il renvoie 404
        // car c'est juste l'endpoint qui n'existe pas, mais le serveur répond
        return {
          'success': true,
          'message': 'Connecté au serveur',
        };
      } else {
        return {
          'success': false,
          'message': 'Le serveur est en ligne mais a retourné une erreur (${response.statusCode})',
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Impossible de se connecter au serveur. Vérifiez l\'URL ou votre connexion internet.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Le serveur met trop de temps à répondre.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors du test de connexion: ${e.toString()}',
      };
    }
  }
} 