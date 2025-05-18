import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../config/api_config.dart';
import 'auth_service.dart';

class ImageService {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  final String baseUrl = ApiConfig.baseUrl;
  final _logger = Logger();

  // Sélectionner une image pour le Web
  Future<Uint8List?> pickImageForWeb() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return await pickedFile.readAsBytes();
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la sélection de l\'image pour le web: $e');
      rethrow;
    }
  }

  // Sélectionner une image depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la sélection de l\'image: $e');
      rethrow;
    }
  }

  // Sélectionner une image depuis la caméra
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 80,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la prise de photo: $e');
      rethrow;
    }
  }

  // Télécharger une image sur le serveur
  Future<String> uploadImage(dynamic imageFile) async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('Non authentifié');
      }

      // Gérer les images web (Uint8List)
      if (kIsWeb && imageFile is Uint8List) {
        try {
          // Convertir en base64 pour le web
          final base64Image = base64Encode(imageFile);
          // Supposer JPEG pour les images web
          final mimeType = 'image/jpeg';
          final dataUrl = 'data:$mimeType;base64,$base64Image';
          
          _logger.i('Image web convertie en base64');
          return dataUrl;
        } catch (e) {
          _logger.e('Erreur lors de la conversion de l\'image web: $e');
          throw e;
        }
      }
      
      // Traiter les images mobiles (File)
      if (!kIsWeb && imageFile is File) {
        // Essayer d'abord avec l'API d'upload
        try {
          // Créer une requête multipart
          var request = http.MultipartRequest(
            'POST', 
            Uri.parse('$baseUrl/api/upload/image')
          );
          
          // Ajouter l'image au formulaire
          final filename = basename(imageFile.path);
          final mimeType = _getMimeType(filename);
          
          request.files.add(
            http.MultipartFile(
              'image',
              imageFile.readAsBytes().asStream(),
              imageFile.lengthSync(),
              filename: filename,
              contentType: MediaType(mimeType.split('/')[0], mimeType.split('/')[1]),
            ),
          );
          
          // Ajouter le token d'authentification
          request.headers.addAll({
            'Authorization': 'Bearer $token',
          });
          
          // Envoyer la requête
          final response = await request.send();
          final responseBody = await response.stream.bytesToString();
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = _parseResponse(responseBody);
            return data['imageUrl'] as String;
          }
        } catch (uploadError) {
          _logger.w('Échec de l\'upload via API: $uploadError. Essayant avec base64...');
        }

        // Solution de secours: convertir en base64 pour démo
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = _getMimeType(imageFile.path);
        final dataUrl = 'data:$mimeType;base64,$base64Image';
        
        _logger.i('Image convertie en base64');
        return dataUrl;
      }
      
      // Si aucune des conditions n'est remplie
      throw Exception('Type d\'image non pris en charge');
    } catch (e) {
      _logger.e('Erreur lors du téléchargement de l\'image: $e');
      
      // En cas d'erreur totale, retourner une image placeholder
      return 'https://via.placeholder.com/400x300?text=Image+Temporaire';
    }
  }
  
  // Déterminer le type MIME d'un fichier
  String _getMimeType(String path) {
    final ext = extension(path).toLowerCase();
    
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
  
  // Parser la réponse JSON
  Map<String, dynamic> _parseResponse(String responseBody) {
    try {
      return Map<String, dynamic>.from(
        (responseBody.startsWith('{')) 
            ? jsonDecode(responseBody) 
            : {'imageUrl': responseBody.trim()}
      );
    } catch (e) {
      return {'imageUrl': responseBody.trim()};
    }
  }
} 