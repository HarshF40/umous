import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert';

class ChatTutor extends StatefulWidget {
  const ChatTutor({super.key});

  @override
  State<ChatTutor> createState() => _ChatTutorState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class _ChatTutorState extends State<ChatTutor> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final String _apiKey = dotenv.env['GEMINI_KEY']!; // Replace with your key
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static const String _systemPrompt = '''
You are an AI tutor designed to help students learn and understand various subjects. Your role is to:

1. Provide clear, educational explanations on academic topics
2. Help with homework, assignments, and study questions
3. Break down complex concepts into understandable parts
4. Encourage learning through guided questions and examples
5. Provide study tips and learning strategies

Guidelines:
- Only respond to educational and study-related questions
- If asked about non-educational topics, politely redirect to studying
- Be patient, encouraging, and supportive
- Use examples and analogies to explain difficult concepts
- Ask follow-up questions to ensure understanding
- Provide step-by-step solutions when appropriate

If someone asks about topics unrelated to education (like entertainment, gossip, personal advice unrelated to studies), respond with: "I'm here to help you with your studies and learning. Could you please ask me something related to your education or any subject you'd like to learn about?"

Remember: You are a dedicated tutor focused on helping students succeed academically.
''';

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Hello! I'm your AI tutor. I'm here to help you with your studies, homework, and learning any subject. What would you like to learn about today?",
          isUser: false,
          time: DateTime.now(),
        ),
      );
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _addWelcomeMessage();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 150,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<String> _sendToGemini(String userInput) async {
    if (_apiKey.isEmpty) {
      // Show a dialog and return an error message
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('API Key Missing'),
            content: const Text(
              'Please set your Gemini API key in the code to use the AI Tutor.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return "API key is missing. Please set your Gemini API key.";
    }
    final url = Uri.parse("$_baseUrl?key=$_apiKey");

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": _systemPrompt},
            {"text": userInput},
          ],
        },
      ],
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      final content = candidates?.first['content'];
      final parts = content?['parts'] as List?;
      final text = parts?.map((p) => p['text']).join(" ").trim();
      return text ?? "I couldn't generate a response.";
    } else {
      throw Exception("Failed to connect to Gemini API");
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, time: DateTime.now()),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _sendToGemini(userMessage);

      setState(() {
        _messages.add(
          ChatMessage(text: response, isUser: false, time: DateTime.now()),
        );
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                "I apologize, but I'm having trouble connecting right now. Please try again in a moment.",
            isUser: false,
            time: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.85),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'AI Tutor',
            style: TextStyle(
              color: Color(0xFF6366F1),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
              onPressed: _clearChat,
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Start a conversation with your AI tutor',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Color(0xFF1E293B)),
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Ask me anything about your studies...',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onSubmitted: (_) =>
                              _isLoading ? null : _sendMessage(),
                          enabled: !_isLoading,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _isLoading ? null : _sendMessage,
                        tooltip: 'Send',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stack) {
      // Show a fallback error UI
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(e.toString(), style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12, top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.school,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF6366F1) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  codeblockDecoration: BoxDecoration(
                    color: isUser
                        ? Colors.white.withOpacity(0.15)
                        : const Color(0xFF6366F1).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  p: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 16,
                    height: 1.4,
                  ),
                  code: TextStyle(
                    fontFamily: 'monospace',
                    backgroundColor: isUser
                        ? Colors.white.withOpacity(0.15)
                        : const Color(0xFF6366F1).withOpacity(0.08),
                    color: isUser ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          ),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 12, top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
