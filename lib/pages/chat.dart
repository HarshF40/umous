import 'package:flutter/material.dart';

class ChatTutor extends StatefulWidget {
  const ChatTutor({super.key});

  @override
  State<ChatTutor> createState() => _ChatTutorState();
}

class _ChatTutorState extends State<ChatTutor> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor'),
      ),
    );
  }
}
