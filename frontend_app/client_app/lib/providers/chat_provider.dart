import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final ChatService _chatService = ChatService();
  bool _isLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  ChatProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _chatService.initialize();
    } catch (e) {
      debugPrint('Error initializing ChatService: $e');
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to the list
    _messages.add(ChatMessage(
      message: message,
      type: MessageType.user,
    ));
    notifyListeners();

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Send message to Gemini API
      final response = await _chatService.sendMessage(message);
      
      // Add bot response to the list
      _messages.add(ChatMessage(
        message: response,
        type: MessageType.bot,
      ));
    } catch (e) {
      _messages.add(ChatMessage(
        message: 'Erreur: $e',
        type: MessageType.bot,
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetChat() {
    _messages.clear();
    _chatService.resetChat();
    notifyListeners();
  }
} 