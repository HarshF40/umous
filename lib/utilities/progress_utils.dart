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
