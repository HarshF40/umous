import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utilities/quiz.dart';

class GroupQuizPage extends StatefulWidget {
  final String groupId;
  const GroupQuizPage({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupQuizPage> createState() => _GroupQuizPageState();
}

class _GroupQuizPageState extends State<GroupQuizPage> {
  List<Map<String, dynamic>> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  String? _selectedOption;
  int _score = 0;
  bool _answered = false;
  bool _loading = true;
  bool _saving = false;
  int _attemptsToday = 0;
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _checkAttemptsAndLoadQuiz();
  }

  Future<void> _checkAttemptsAndLoadQuiz() async {
    setState(() {
      _loading = true;
      _limitReached = false;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _limitReached = true;
      });
      return;
    }
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final attemptsSnap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('scores')
        .doc(user.uid)
        .collection('attempts')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
        )
        .get();
    _attemptsToday = attemptsSnap.docs.length;
    if (_attemptsToday >= 3) {
      setState(() {
        _loading = false;
        _limitReached = true;
      });
      return;
    }
    await _loadGroupTopicAndGenerateQuiz();
  }

  Future<void> _loadGroupTopicAndGenerateQuiz() async {
    setState(() => _loading = true);
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
    final data = doc.data();
    final topic = data != null && data['topic'] != null
        ? data['topic'] as String
        : 'General Knowledge';
    final quiz = await generateQuizFromTopics([topic]);
    setState(() {
      _quizQuestions = quiz;
      _loading = false;
    });
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

  Future<void> _showScoreDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    // Save attempt as a new document
    final attemptId = DateTime.now().millisecondsSinceEpoch.toString();
    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('scores')
        .doc(user.uid)
        .collection('attempts')
        .doc(attemptId)
        .set({
          'points': _score,
          'userEmail': user.email,
          'timestamp': FieldValue.serverTimestamp(),
        });
    setState(() => _saving = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Quiz Completed!"),
        content: Text("Your score: $_score / ${_quizQuestions.length}"),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
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
            Text(
              "$label. ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_limitReached) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Group Quiz'),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'You have reached the maximum of 3 quizzes for today.',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                'Try again tomorrow!',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }
    if (_quizQuestions.isEmpty) {
      return const Scaffold(body: Center(child: Text('No quiz available.')));
    }
    final currentQ = _quizQuestions[_currentQuestionIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Quiz'),
        backgroundColor: Colors.green,
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
                onPressed: _saving ? null : _nextQuestion,
                child: Text(
                  _currentQuestionIndex == _quizQuestions.length - 1
                      ? "Finish"
                      : "Next",
                ),
              ),
          ],
        ),
      ),
    );
  }
}
