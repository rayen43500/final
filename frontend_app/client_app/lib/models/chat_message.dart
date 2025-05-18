enum MessageType {
  user,
  bot
}

class ChatMessage {
  final String message;
  final MessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
} 