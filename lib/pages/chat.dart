import 'package:flutter/material.dart';
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

  static const String _apiKey = 'AIzaSyDZUh4vSt9NpDA-LZTiJI7M1O85fbfKufA'; // Replace with your key
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
      _messages.add(ChatMessage(
        text:
            "Hello! I'm your AI tutor. I'm here to help you with your studies, homework, and learning any subject. What would you like to learn about today?",
        isUser: false,
        time: DateTime.now(),
      ));
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
    final url = Uri.parse("$_baseUrl?key=$_apiKey");

    final body = jsonEncode({
  "contents": [
    {
      "parts": [
        {"text": _systemPrompt},
        {"text": userInput}
      ]
    }
  ]
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
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        time: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _sendToGemini(userMessage);

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text:
              "I apologize, but I'm having trouble connecting right now. Please try again in a moment.",
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
  }

Widget _buildMessageBubble(ChatMessage message) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      mainAxisAlignment:
          message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!message.isUser)
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 12, top: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: message.isUser
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: message.isUser
                    ? const Radius.circular(20)
                    : const Radius.circular(4),
                bottomRight: message.isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(20),
              ),
              border: message.isUser
                  ? null
                  : Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
            ),
            child: MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet(
                codeblockDecoration: BoxDecoration( 
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(18)
                  ),
                p: TextStyle(
                  color: message.isUser
                      ? const Color(0xFF389bdc)
                      : Color(0xFF000000),
                  fontSize: 16,
                  height: 1.4,
                ),
                code: const TextStyle(
                  fontFamily: 'monospace',
                  backgroundColor: Color(0xFF000000),
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
        if (message.isUser)
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 12, top: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF389bdc),
      appBar: AppBar(
        backgroundColor: const Color(0xFF389bdc),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Tutor',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tutor is thinking...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything about your studies...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: _isLoading
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white.withOpacity(0.7),
                          ),
                          onPressed: _isLoading ? null : _sendMessage,
                        ),
                      ),
                      onSubmitted: (_) => _isLoading ? null : _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

