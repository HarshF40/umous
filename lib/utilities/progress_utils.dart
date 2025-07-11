import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String? getNextSubtopicForTopic(
  String topicName,
  List<String> allSubtopics,
  Set<String> completed,
) {
  for (final sub in allSubtopics) {
    if (!completed.contains(sub)) {
      print('Next subtopic for $topicName: $sub');
      return sub;
    }
  }
  print('All subtopics completed for $topicName!');
  return null;
}

Future<void> saveQuizScoreToProgress(
    String topicName, String quizNumber, int score) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('topics')
      .doc('selected')
      .collection(topicName)
      .doc('progress');
  await docRef.set({
    'quizzes': {quizNumber: score}
  }, SetOptions(merge: true));
  print('Saved $quizNumber: $score for $topicName in progress doc');
}
