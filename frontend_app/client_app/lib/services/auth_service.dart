import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final String baseUrl = ApiConfig.baseUrl;
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔐 Tentative de connexion pour: $email');
      print('📍 URL de connexion: $baseUrl/auth/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'motDePasse': password,
        }),
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
        onTimeout: () {
          print('⏱️ Délai d\'attente dépassé pour la connexion');
          throw Exception('Le serveur ne répond pas. Vérifiez votre connexion internet ou réessayez plus tard.');
        },
      );

      print('📊 Statut de la réponse: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Vérifier si l'utilisateur est un client
        if (data['user']['role'] != 'Client') {
          throw Exception('Accès non autorisé. Cette application est réservée aux clients.');
        }

        // Sauvegarder le token et les informations utilisateur
        await _storage.write(key: 'token', value: data['token']);
        await _storage.write(key: 'refreshToken', value: data['refreshToken']);
        await _storage.write(key: 'user', value: json.encode(data['user']));

        print('✅ Connexion réussie pour: ${data['user']['email']}');
        return data;
      } else {
        final error = json.decode(response.body);
        print('❌ Échec de connexion: ${error['message'] ?? 'Erreur inconnue'}');
        throw Exception(error['message'] ?? 'Erreur de connexion');
      }
    } on http.ClientException catch (e) {
      print('❌ Erreur client HTTP: ${e.toString()}');
      throw Exception('Impossible de se connecter au serveur. Vérifiez l\'URL de l\'API dans les paramètres de l\'application.');
    } catch (e) {
      print('❌ Erreur de connexion: ${e.toString()}');
      throw Exception('Erreur de connexion: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String name, String telephone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'motDePasse': password,
          'nom': name,
          'telephone': telephone,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        // Ne pas sauvegarder les tokens et infos utilisateur lors de l'inscription
        // L'utilisateur devra se connecter manuellement
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'user');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      // Tenter de récupérer les informations utilisateur depuis le stockage local
      final userStr = await _storage.read(key: 'user');
      
      if (userStr != null) {
        try {
          final userData = json.decode(userStr);
          if (userData['_id'] != null) {
            print('Informations utilisateur récupérées depuis le stockage local. ID: ${userData['_id']}');
            
            // Vérifier si l'ID semble valide (pour éviter les problèmes avec les IDs tronqués)
            if (userData['_id'].toString().length < 10) {
              print('ID utilisateur stocké semble invalide ou tronqué: ${userData['_id']}');
              // Ne pas supprimer les données, mais essayer de récupérer un ID valide depuis le token
            } else {
              return userData;
            }
          } else {
            print('ID utilisateur manquant dans les données stockées localement');
          }
        } catch (e) {
          print('Erreur lors du décodage des données utilisateur: $e');
          // Ne pas supprimer les données utilisateur invalides immédiatement
        }
      }
      
      // Si pas d'infos utilisateur stockées ou ID manquant, essayer de récupérer depuis le token
      print('Tentative de récupération via token JWT...');
      final token = await getToken();
      
      if (token != null) {
        try {
          // Récupérer les informations utilisateur à partir du token JWT
          final parts = token.split('.');
          if (parts.length != 3) {
            print('Format de token invalide, impossible de décoder');
            throw Exception('Format de token invalide');
          }
          
          String normalizedPart = parts[1];
          // Ajuster la longueur pour le décodage base64
          while (normalizedPart.length % 4 != 0) {
            normalizedPart += '=';
          }
          
          final decoded = base64Url.decode(normalizedPart);
          final payloadJson = utf8.decode(decoded);
          final payload = json.decode(payloadJson);
          
          print('Contenu du payload JWT: $payload');
          
          // Vérifier si le payload contient des informations utilisateur
          String? userId;
          if (payload.containsKey('userId')) {
            userId = payload['userId'];
          } else if (payload.containsKey('sub')) {
            userId = payload['sub'];
          } else if (payload.containsKey('id')) {
            userId = payload['id'];
          }
          
          if (userId != null) {
            print('UserID trouvé dans le token: $userId');
            
            // Récupérer les informations complètes de l'utilisateur
            final userInfo = await getUserInfoFromAPI(userId);
            
            if (userInfo != null && userInfo['_id'] != null) {
              print('Informations utilisateur récupérées depuis l\'API. ID: ${userInfo['_id']}');
              return userInfo;
            } else {
              print('Échec de récupération des informations complètes depuis l\'API');
              // Créer un utilisateur minimal avec l'ID du token pour éviter la déconnexion
              if (userStr == null) {
                final minimalUser = {'_id': userId, 'nom': 'Utilisateur', 'email': 'utilisateur@example.com'};
                await _storage.write(key: 'user', value: json.encode(minimalUser));
                print('Création d\'un utilisateur minimal pour éviter la déconnexion');
                return minimalUser;
              }
            }
          } else {
            print('Le token JWT ne contient pas d\'ID utilisateur');
          }
        } catch (e) {
          print('Erreur lors de la récupération des infos depuis le token: $e');
          // Ne pas déconnecter l'utilisateur en cas d'erreur de parsing du token
        }
      }
      
      // Dernière tentative: vérifier si nous avons encore des données utilisateur stockées
      if (userStr != null) {
        try {
          final userData = json.decode(userStr);
          print('Utilisation des données utilisateur stockées comme dernier recours');
          return userData;
        } catch (e) {
          print('Impossible de parser les données utilisateur stockées: $e');
        }
      }
      
      // Si tout échoue, créer un utilisateur anonyme
      final anonymousUser = {
        '_id': 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
        'nom': 'Utilisateur',
        'email': 'utilisateur@example.com',
        'mode': 'anonyme'
      };
      
      await _storage.write(key: 'user', value: json.encode(anonymousUser));
      print('Création d\'un utilisateur anonyme comme dernier recours');
      
      return anonymousUser;
    } catch (e) {
      print('Erreur getCurrentUser: $e');
      return null;
    }
  }
  
  // Récupérer les informations de l'utilisateur depuis l'API
  Future<Map<String, dynamic>?> getUserInfoFromAPI(String userId) async {
    try {
      print('Tentative de récupération des informations utilisateur depuis l\'API pour ID: $userId');
      
      // Vérifier si l'ID utilisateur est valide
      if (userId.isEmpty || userId.length < 10) {
        print('ID utilisateur invalide: $userId');
        return {'_id': userId, 'nom': 'Utilisateur', 'email': 'utilisateur@example.com'};
      }
      
      final token = await getToken();
      
      if (token == null) {
        print('Pas de token disponible pour l\'appel API');
        return null;
      }
      
      // Afficher l'URL complète pour le débogage
      final url = '$baseUrl/users/$userId';
      print('URL de la requête: $url');
      
      // Vérifier d'abord si l'utilisateur existe avec une requête HEAD
      try {
        final checkResponse = await http.head(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
          },
        ).timeout(Duration(milliseconds: 5000));
        
        if (checkResponse.statusCode == 404) {
          print('Utilisateur non trouvé (vérification préliminaire). Utilisation des données locales.');
          final userStr = await _storage.read(key: 'user');
          if (userStr != null) {
            try {
              return json.decode(userStr);
            } catch (e) {
              print('Erreur lors du décodage des données utilisateur locales: $e');
            }
          }
          return {'_id': userId, 'nom': 'Utilisateur', 'email': 'utilisateur@example.com'};
        }
      } catch (e) {
        print('Erreur lors de la vérification préliminaire: $e');
        // Continuer avec la requête GET même si la vérification HEAD échoue
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        Duration(milliseconds: ApiConfig.connectionTimeout),
        onTimeout: () {
          print('⏱️ Délai d\'attente dépassé pour la récupération des informations utilisateur');
          throw Exception('Le serveur ne répond pas. Vérifiez votre connexion internet ou réessayez plus tard.');
        },
      );
      
      print('Statut de la réponse API: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Données brutes reçues: $data');
        
        Map<String, dynamic> user;
        // Gérer les différentes structures de réponse possibles
        if (data is Map<String, dynamic>) {
          if (data.containsKey('user')) {
            user = data['user'];
          } else {
            user = data;
          }
        } else {
          print('Format de réponse inattendu: ${data.runtimeType}');
          return null;
        }
        
        // Vérifier que l'ID est présent
        if (user['_id'] == null) {
          print('Avertissement: ID utilisateur manquant dans la réponse API');
          // Ajouter l'ID manuellement si nécessaire
          user['_id'] = userId;
        }
        
        // Stocker les informations récupérées
        await _storage.write(key: 'user', value: json.encode(user));
        print('Informations utilisateur mises à jour depuis l\'API: ID=${user['_id']}');
        
        return user;
      } else if (response.statusCode == 404) {
        // Si l'utilisateur n'est pas trouvé, on utilise les informations stockées localement
        print('Utilisateur non trouvé sur le serveur (404). Tentative d\'utilisation des données locales.');
        final userStr = await _storage.read(key: 'user');
        if (userStr != null) {
          try {
            final userData = json.decode(userStr);
            if (userData['_id'] != null) {
              print('Utilisation des données utilisateur stockées localement comme fallback');
              return userData;
            }
          } catch (e) {
            print('Erreur lors du décodage des données utilisateur locales: $e');
          }
        }
        // Ne pas déconnecter l'utilisateur en cas d'erreur 404
        return {'_id': userId, 'email': 'utilisateur@example.com', 'nom': 'Utilisateur'};
      } else if (response.statusCode == 401) {
        print('Erreur d\'authentification (401) - token invalide ou expiré');
        // Supprimer le token et forcer la reconnexion
        await logout();
        return null;
      } else {
        print('Erreur HTTP ${response.statusCode}: ${response.body}');
        // Tenter de décoder le message d'erreur
        try {
          final error = json.decode(response.body);
          print('Message d\'erreur: ${error['message'] ?? error.toString()}');
        } catch (e) {
          print('Corps de la réponse d\'erreur: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      print('Exception lors de la récupération des infos utilisateur: $e');
      // En cas d'erreur, utiliser les données stockées localement si disponibles
      final userStr = await _storage.read(key: 'user');
      if (userStr != null) {
        try {
          final userData = json.decode(userStr);
          print('Utilisation des données utilisateur stockées localement suite à une erreur');
          return userData;
        } catch (e) {
          print('Erreur lors du décodage des données utilisateur locales: $e');
        }
      }
      return null;
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: 'token');
      print('Token récupéré: ${token != null ? (token.length > 10 ? token.substring(0, 10) + "..." : token) : "null"}');
      
      if (token == null) {
        print('Aucun token trouvé dans le stockage');
        return null;
      }
      
      // Vérifier si le token a un format valide (structure JWT basique)
      if (!token.contains('.') || token.split('.').length != 3) {
        print('Format de token invalide: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
        // Supprimer le token invalide
        await _storage.delete(key: 'token');
        return null;
      }
      
      // Vérifier si le token est expiré
      try {
        final parts = token.split('.');
        
        String normalizedPart = parts[1];
        // Ajuster la longueur pour le décodage base64
        while (normalizedPart.length % 4 != 0) {
          normalizedPart += '=';
        }
        
        try {
          final decoded = base64Url.decode(normalizedPart);
          final payloadJson = utf8.decode(decoded);
          final payload = json.decode(payloadJson);
          
          if (payload.containsKey('exp')) {
            final exp = payload['exp'];
            final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
            final now = DateTime.now();
            
            if (now.isAfter(expDate)) {
              print('Token expiré à ${expDate.toIso8601String()}');
              
              // Essayer de rafraîchir le token
              final refreshTokenValue = await getRefreshToken();
              if (refreshTokenValue != null) {
                try {
                  final newTokenData = await this.refreshToken(refreshTokenValue);
                  final newToken = newTokenData['token'];
                  await _storage.write(key: 'token', value: newToken);
                  print('Token rafraîchi avec succès');
                  return newToken;
                } catch (e) {
                  print('Échec du rafraîchissement du token: $e');
                  await logout();
                  return null;
                }
              } else {
                await logout();
                return null;
              }
            }
          }
        } catch (e) {
          print('Erreur lors du décodage du payload: $e');
          // Continuer avec le token tel quel, même s'il ne peut pas être décodé
        }
      } catch (e) {
        print('Erreur lors de la validation du token: $e');
        // En cas d'erreur de parsing, on conserve le token tel quel
        // pour que le backend puisse le rejeter si nécessaire
      }
      
      return token;
    } catch (e) {
      print('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refreshToken');
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'refreshToken': refreshToken,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to refresh token: ${response.body}');
    }
  }

  Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/validate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Mise à jour du profil utilisateur (nom, téléphone, etc.)
  Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> userData) async {
    try {
      print('Tentative de mise à jour du profil pour l\'utilisateur ID: $userId');
      print('Données à mettre à jour: $userData');
      
      final token = await getToken();
      
      if (token == null) {
        throw Exception('Utilisateur non authentifié - token manquant');
      }
      
      // Afficher l'URL complète pour le débogage
      final url = '$baseUrl/users/$userId';
      print('URL de la requête: $url');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(userData),
      );
      
      print('Statut de la réponse API (mise à jour profil): ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Données reçues après mise à jour: $data');
        
        Map<String, dynamic> updatedUser;
        // Gérer les différentes structures de réponse possibles
        if (data is Map<String, dynamic>) {
          if (data.containsKey('user')) {
            updatedUser = data['user'];
          } else {
            updatedUser = data;
          }
        } else {
          throw Exception('Format de réponse inattendu lors de la mise à jour du profil');
        }
        
        // Vérifier que l'ID est présent
        if (updatedUser['_id'] == null) {
          print('Avertissement: ID utilisateur manquant dans la réponse API de mise à jour');
          // Ajouter l'ID manuellement pour assurer la cohérence
          updatedUser['_id'] = userId;
        }
        
        // Mettre à jour les informations stockées localement
        await _storage.write(key: 'user', value: json.encode(updatedUser));
        print('Informations utilisateur mises à jour localement après modification du profil');
        
        return updatedUser;
      } else if (response.statusCode == 401) {
        print('Erreur d\'authentification (401) lors de la mise à jour du profil');
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        String errorMessage = 'Erreur lors de la mise à jour du profil';
        try {
          final error = json.decode(response.body);
          errorMessage = error['message'] ?? errorMessage;
          print('Message d\'erreur de l\'API: $errorMessage');
        } catch (e) {
          print('Corps de la réponse d\'erreur: ${response.body}');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Exception lors de la mise à jour du profil: $e');
      throw Exception('Erreur lors de la mise à jour du profil: ${e.toString()}');
    }
  }
  
  // Changer le mot de passe
  Future<bool> changePassword(String userId, String currentPassword, String newPassword) async {
    try {
      print('Tentative de changement de mot de passe pour l\'utilisateur ID: $userId');
      
      final token = await getToken();
      
      if (token == null) {
        throw Exception('Utilisateur non authentifié - token manquant');
      }
      
      // Afficher l'URL complète pour le débogage
      final url = '$baseUrl/auth/change-password';
      print('URL de la requête: $url');
      
      final payload = {
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );
      
      print('Statut de la réponse API (changement mot de passe): ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('Mot de passe modifié avec succès');
        return true;
      } else if (response.statusCode == 401) {
        print('Erreur d\'authentification (401) - Mot de passe actuel incorrect ou session expirée');
        String errorMessage = 'Session expirée ou mot de passe actuel incorrect';
        try {
          final error = json.decode(response.body);
          errorMessage = error['message'] ?? errorMessage;
        } catch (e) {
          // Ignorer les erreurs de parsing
        }
        throw Exception(errorMessage);
      } else {
        String errorMessage = 'Erreur lors du changement de mot de passe';
        try {
          final error = json.decode(response.body);
          errorMessage = error['message'] ?? errorMessage;
          print('Message d\'erreur de l\'API: $errorMessage');
        } catch (e) {
          print('Corps de la réponse d\'erreur: ${response.body}');
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Exception lors du changement de mot de passe: $e');
      throw Exception('Erreur lors du changement de mot de passe: ${e.toString()}');
    }
  }

  // Vérifier si le serveur API est accessible
  Future<bool> checkServerConnectivity() async {
    try {
      print('Vérification de la connectivité au serveur: $baseUrl');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        Duration(milliseconds: 5000), // Timeout court pour la vérification
        onTimeout: () {
          print('⏱️ Délai d\'attente dépassé pour la vérification de connectivité');
          throw Exception('Timeout');
        },
      );
      
      print('Statut de la réponse de santé: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Erreur lors de la vérification de la connectivité: $e');
      
      // Essayer une URL alternative en cas d'échec
      try {
        print('Tentative avec URL alternative: http://10.0.2.2:5000/api/health');
        final response = await http.get(
          Uri.parse('http://10.0.2.2:5000/api/health'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(milliseconds: 5000));
        
        if (response.statusCode >= 200 && response.statusCode < 300) {
          print('URL alternative fonctionne! Considérer la mise à jour de la configuration.');
        }
      } catch (_) {
        // Ignorer l'erreur de l'URL alternative
      }
      
      return false;
    }
  }

  // Nettoyer et réparer les données utilisateur stockées
  Future<bool> cleanupUserData() async {
    try {
      print('Nettoyage des données utilisateur...');
      
      // Vérifier si nous avons des données utilisateur
      final userStr = await _storage.read(key: 'user');
      if (userStr == null) {
        print('Aucune donnée utilisateur à nettoyer');
        return false;
      }
      
      // Essayer de parser les données
      Map<String, dynamic> userData;
      try {
        userData = json.decode(userStr);
      } catch (e) {
        print('Données utilisateur corrompues, suppression: $e');
        await _storage.delete(key: 'user');
        return true;
      }
      
      // Vérifier si l'ID est présent et valide
      final userId = userData['_id'];
      if (userId == null || userId.toString().length < 10) {
        print('ID utilisateur manquant ou invalide: $userId');
        
        // Essayer de récupérer l'ID depuis le token
        final token = await _storage.read(key: 'token');
        if (token != null && token.contains('.') && token.split('.').length == 3) {
          try {
            final parts = token.split('.');
            String normalizedPart = parts[1];
            while (normalizedPart.length % 4 != 0) {
              normalizedPart += '=';
            }
            
            final decoded = base64Url.decode(normalizedPart);
            final payloadJson = utf8.decode(decoded);
            final payload = json.decode(payloadJson);
            
            String? newUserId;
            if (payload.containsKey('userId')) {
              newUserId = payload['userId'];
            } else if (payload.containsKey('sub')) {
              newUserId = payload['sub'];
            } else if (payload.containsKey('id')) {
              newUserId = payload['id'];
            }
            
            if (newUserId != null && newUserId.length >= 10) {
              print('ID utilisateur récupéré depuis le token: $newUserId');
              userData['_id'] = newUserId;
              await _storage.write(key: 'user', value: json.encode(userData));
              return true;
            }
          } catch (e) {
            print('Erreur lors de la récupération de l\'ID depuis le token: $e');
          }
        }
        
        // Si nous ne pouvons pas récupérer un ID valide, supprimer les données
        print('Impossible de récupérer un ID valide, suppression des données utilisateur');
        await _storage.delete(key: 'user');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erreur lors du nettoyage des données utilisateur: $e');
      return false;
    }
  }

  // Mettre à jour les données utilisateur localement
  Future<Map<String, dynamic>> updateUserDataLocally(Map<String, dynamic> userData) async {
    try {
      // Récupérer les données utilisateur actuelles
      final userStr = await _storage.read(key: 'user');
      Map<String, dynamic> currentUserData;
      
      if (userStr != null) {
        try {
          currentUserData = json.decode(userStr);
        } catch (e) {
          print('Erreur lors du décodage des données utilisateur: $e');
          currentUserData = {'_id': 'local_user'};
        }
      } else {
        currentUserData = {'_id': 'local_user'};
      }
      
      // Mettre à jour avec les nouvelles données
      currentUserData.addAll(userData);
      
      // Sauvegarder les données mises à jour
      await _storage.write(key: 'user', value: json.encode(currentUserData));
      
      print('Données utilisateur mises à jour localement: $currentUserData');
      
      return currentUserData;
    } catch (e) {
      print('Erreur lors de la mise à jour locale des données utilisateur: $e');
      throw Exception('Erreur lors de la mise à jour locale: $e');
    }
  }

  // Vérifier si l'utilisateur est en mode hors ligne
  Future<bool> isOfflineMode() async {
    try {
      // Vérifier d'abord la connectivité au serveur
      final isServerReachable = await checkServerConnectivity();
      if (!isServerReachable) {
        print('Serveur inaccessible, mode hors ligne activé');
        return true;
      }
      
      // Vérifier si nous avons un token valide
      final token = await getToken();
      if (token == null) {
        print('Pas de token valide, mode hors ligne activé');
        return true;
      }
      
      // Vérifier les données utilisateur
      final userStr = await _storage.read(key: 'user');
      if (userStr == null) {
        print('Pas de données utilisateur, mode hors ligne activé');
        return true;
      }
      
      try {
        final userData = json.decode(userStr);
        if (userData['mode'] == 'hors_ligne' || userData['mode'] == 'anonyme' || userData['mode'] == 'erreur') {
          print('Mode hors ligne explicitement défini dans les données utilisateur');
          return true;
        }
        
        // Vérifier si l'ID utilisateur est valide
        final userId = userData['_id'];
        if (userId == null || userId.toString().length < 10 || userId.startsWith('offline_') || userId.startsWith('anonymous_')) {
          print('ID utilisateur invalide ou hors ligne: $userId');
          return true;
        }
      } catch (e) {
        print('Erreur lors du décodage des données utilisateur: $e');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erreur lors de la vérification du mode hors ligne: $e');
      return true; // Par défaut, considérer comme hors ligne en cas d'erreur
    }
  }
  
  // Mettre à jour le mode de l'utilisateur
  Future<void> updateUserMode(String mode) async {
    try {
      final userStr = await _storage.read(key: 'user');
      if (userStr != null) {
        try {
          final userData = json.decode(userStr);
          userData['mode'] = mode;
          await _storage.write(key: 'user', value: json.encode(userData));
          print('Mode utilisateur mis à jour: $mode');
        } catch (e) {
          print('Erreur lors de la mise à jour du mode utilisateur: $e');
        }
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du mode utilisateur: $e');
    }
  }
} 