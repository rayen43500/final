import 'package:flutter/material.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  bool _isInitialized = false;
  final List<Map<String, String>> _messageHistory = [];

  factory ChatService() {
    return _instance;
  }

  ChatService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔄 Initialisation du service de chat...');
      _isInitialized = true;
      debugPrint('✅ Service de chat initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du service de chat: $e');
    }
  }

  Future<String> sendMessage(String message) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) {
        return 'Impossible de se connecter au service de chat. Veuillez vérifier votre connexion et réessayer.';
      }
    }

    try {
      debugPrint('📤 Message reçu: $message');
      
      // Store user message in history
      _messageHistory.add({'role': 'user', 'content': message});
      
      // Create a simple response
      final String response = _generateSimpleResponse(message);
      
      // Store response in history
      _messageHistory.add({'role': 'assistant', 'content': response});
      
      debugPrint('📥 Réponse envoyée');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur générale lors de la communication: $e');
      return 'Désolé, une erreur est survenue. Veuillez réessayer plus tard.';
    }
  }

  String _generateSimpleResponse(String message) {
    message = message.toLowerCase();
    
    if (message.contains('bonjour') || message.contains('salut')) {
      return 'Bonjour ! Comment puis-je vous aider avec l\'artisanat éco-responsable aujourd\'hui ?';
    } else if (message.contains('merci')) {
      return 'Je vous en prie ! N\'hésitez pas si vous avez d\'autres questions.';
    } else if (message.contains('matériau') || message.contains('matériaux')) {
      return 'Les matériaux durables recommandés pour l\'artisanat éco-responsable comprennent le bois certifié FSC, le coton biologique, la laine recyclée, et les teintures naturelles. Quel type de projet souhaitez-vous réaliser ?';
    } else if (message.contains('technique') || message.contains('comment')) {
      return 'Pour les techniques d\'artisanat éco-responsable, je vous recommande de commencer par la récupération et la transformation de matériaux existants. Cela permet de réduire l\'impact environnemental de vos créations.';
    } else {
      return 'Merci pour votre message. En tant qu\'assistant spécialisé en artisanat éco-responsable, je peux vous aider avec des conseils sur les matériaux durables, les techniques de fabrication et diverses créations artisanales. Pourriez-vous préciser votre question ?';
    }
  }

  void resetChat() {
    _messageHistory.clear();
    debugPrint('🔄 Historique de chat réinitialisé');
  }
  
  List<Map<String, String>> get messageHistory => _messageHistory;
} 