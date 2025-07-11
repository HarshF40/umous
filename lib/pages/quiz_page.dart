import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utilities/quiz.dart';

class QuizPage extends StatefulWidget {
  final String domainName;

  const QuizPage({super.key, required this.domainName});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  int _score = 0;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _loadCompletedTopicsAndGenerateQuiz();
  }

  Future<void> _loadCompletedTopicsAndGenerateQuiz() async {
  try {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('topics')
        .doc('selected')
        .collection(widget.domainName) // <-- Access subcollection for domainName
        .doc('progress');              // <-- Target progress document

    final doc = await docRef.get();

    if (!doc.exists || doc.data() == null || !doc.data()!.containsKey('completedSubtopics')) {
      print("⚠️ No completedSubtopics found for '${widget.domainName}'");
      return;
    }

    final completedTopics = List<String>.from(doc['completedSubtopics'] ?? []);

    final quiz = await generateQuizFromTopics(completedTopics);

    setState(() {
      _quizQuestions = quiz;
    });
  } catch (e) {
    print('❌ Failed to load topics or generate quiz: $e');
  }
}

  void _checkAnswer(String selected) {
    if (_answered) return;
    final correct = _quizQuestions[_currentQuestionIndex]['co'];
    setState(() {
      _selectedOption = selected;
      _answered = true;
      if (selected == correct) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      _showScoreDialog();
    }
  }

  void _showScoreDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Quiz Completed!"),
        content: Text("Your score: $_score / ${_quizQuestions.length}"),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildOption(String label, String text) {
    final isSelected = _selectedOption == label;
    final isCorrect = _quizQuestions[_currentQuestionIndex]['co'] == label;
    final showColor = _answered;

    Color? color;
    if (showColor) {
      if (isSelected && isCorrect) {
        color = Colors.green;
      } else if (isSelected && !isCorrect) {
        color = Colors.red;
      } else if (isCorrect) {
        color = Colors.green;
      }
    }

    return GestureDetector(
      onTap: () => _checkAnswer(label),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color ?? Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Text("$label. ", style: const TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_quizQuestions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQ = _quizQuestions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.domainName}'),
        backgroundColor: const Color(0xFF389bdc),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Q${_currentQuestionIndex + 1}. ${currentQ['q']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildOption("a", currentQ['a']),
            _buildOption("b", currentQ['b']),
            _buildOption("c", currentQ['c']),
            _buildOption("d", currentQ['d']),
            const Spacer(),
            if (_answered)
              ElevatedButton(
                onPressed: _nextQuestion,
                child: Text(_currentQuestionIndex == _quizQuestions.length - 1
                    ? "Finish"
                    : "Next"),
              ),
          ],
        ),
      ),
    );
  }
}
