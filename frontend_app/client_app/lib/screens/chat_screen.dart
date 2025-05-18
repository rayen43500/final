import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.spa, size: 20),
              SizedBox(width: 8),
              Text('Assistant Artisanal'),
            ],
          ),
          backgroundColor: const Color(0xFF5C6BC0),
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Réinitialiser la conversation',
                  onPressed: () {
                    chatProvider.resetChat();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Conversation réinitialisée')),
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages area
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  
                  if (chatProvider.messages.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.spa,
                            size: 60,
                            color: Colors.green[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Assistant Artisanal',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5C6BC0),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Des conseils personnalisés sur les créations artisanales et les matériaux éco-responsables',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Quelques exemples de questions:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                              children: [
                                _buildSuggestionChip(
                                  chatProvider, 
                                  'Quels matériaux écologiques pour débuter?'
                                ),
                                _buildSuggestionChip(
                                  chatProvider, 
                                  'Conseils pour teindre naturellement?'
                                ),
                                _buildSuggestionChip(
                                  chatProvider, 
                                  'Idées pour récupérer du bois?'
                                ),
                                _buildSuggestionChip(
                                  chatProvider, 
                                  'Meilleures techniques de vannerie?'
                                ),
                                _buildSuggestionChip(
                                  chatProvider, 
                                  'Outils pour débuter en artisanat?'
                                ),
                                _buildSuggestionChip(
                                  chatProvider, 
                                  'Comment créer des bijoux écologiques?'
                                ),
                                _buildSuggestionChip(
                                  chatProvider, 
                                  'Comment réduire les déchets dans mon atelier?'
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatProvider.messages.length) {
                        // Show typing indicator
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C6BC0)),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'En train de répondre...',
                                  style: TextStyle(color: Color(0xFF5C6BC0)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final message = chatProvider.messages[index];
                      final isUser = message.type == MessageType.user;
                      final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
                      final color = isUser ? const Color(0xFF5C6BC0) : const Color(0xFFF5F7FF);
                      final textColor = isUser ? Colors.white : Colors.black87;
                      
                      return Align(
                        alignment: alignment,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.message,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('HH:mm').format(message.timestamp),
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrivez votre message...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, _) {
                      return FloatingActionButton(
                        onPressed: chatProvider.isLoading
                            ? null
                            : () {
                                if (_messageController.text.trim().isNotEmpty) {
                                  chatProvider.sendMessage(_messageController.text);
                                  _messageController.clear();
                                }
                              },
                        backgroundColor: const Color(0xFF5C6BC0),
                        elevation: 2,
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(ChatProvider chatProvider, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          chatProvider.sendMessage(label);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
} 