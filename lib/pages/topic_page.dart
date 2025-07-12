import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umous/pages/quiz_page.dart';
import 'package:umous/pages/timer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utilities/progress_utils.dart';
import '../utilities/topfivevid.dart';
import 'package:url_launcher/url_launcher.dart';

class TopicPage extends StatefulWidget {
  final String topicName;
  const TopicPage({super.key, required this.topicName});

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  List<String> subtopics = [];
  Set<String> completed = {};
  bool isLoading = true;
  String? errorMsg;

  // YouTube video state
  List<Map<String, String>> ytVideos = [];
  bool ytLoading = false;
  String? ytError;

  int totalQuestionsAnswered = 0;
  int totalCorrectAnswers = 0;
  String todayTimeSpent = '0h 0m 0s';

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _loadAllAndFetchYouTube();
    _fetchStats();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // --- Fix setState() after dispose ---
  void safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) setState(fn);
  }

  Future<void> _loadAllAndFetchYouTube() async {
    await fetchSubtopics();
    await fetchCompletedSubtopics();
    final nextSubtopic = getNextSubtopicForTopic(
      widget.topicName,
      subtopics,
      completed,
    );
    if (nextSubtopic != null && nextSubtopic.isNotEmpty) {
      await fetchYouTubeForNextSubtopic(nextSubtopic);
    } else {
      safeSetState(() {
        ytError = 'All subtopics completed!';
        ytLoading = false;
      });
    }
  }

  Future<void> fetchSubtopics() async {
    safeSetState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('roadmaps')
          .doc('topics')
          .get();
      if (!doc.exists || doc.data() == null) {
        safeSetState(() {
          subtopics = [];
          errorMsg = 'No roadmap found.';
          isLoading = false;
        });
        return;
      }
      final data = doc.data()!;
      String? roadmapString;
      for (final value in data.values) {
        if (value is Map) {
          if (value.containsKey(widget.topicName)) {
            roadmapString = value[widget.topicName];
            break;
          }
        }
      }
      if (roadmapString == null || roadmapString.trim().isEmpty) {
        safeSetState(() {
          subtopics = [];
          errorMsg = 'No subtopics found for this topic.';
          isLoading = false;
        });
        return;
      }
      subtopics = roadmapString
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      safeSetState(() {
        isLoading = false;
        errorMsg = null;
      });
    } catch (e) {
      safeSetState(() {
        subtopics = [];
        errorMsg = 'Error loading roadmap.';
        isLoading = false;
      });
    }
  }

  Future<void> fetchCompletedSubtopics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('topics')
        .doc('selected')
        .collection(widget.topicName)
        .doc('progress')
        .get();
    final data = doc.data();
    if (data != null && data['completedSubtopics'] is List) {
      safeSetState(() {
        completed = Set<String>.from(data['completedSubtopics']);
      });
    }
  }

  Future<void> saveCompletedSubtopics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('topics')
        .doc('selected')
        .collection(widget.topicName)
        .doc('progress');

    String? nextSubtopic = getNextSubtopicForTopic(
      widget.topicName,
      subtopics,
      completed,
    );

    await docRef.set({
      'completedSubtopics': completed.toList(),
      'nextSubtopic': nextSubtopic,
    }, SetOptions(merge: true));
  }

  Future<void> fetchYouTubeForNextSubtopic(String nextSubtopic) async {
    safeSetState(() {
      ytLoading = true;
      ytError = null;
      ytVideos = [];
    });
    try {
      final videos = await fetchYouTubeVideos(nextSubtopic);
      safeSetState(() {
        ytVideos = videos;
        ytLoading = false;
      });
    } catch (e) {
      safeSetState(() {
        ytLoading = false;
        ytError = 'Failed to fetch YouTube videos.';
      });
    }
  }

  Future<void> _fetchStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final quizzesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('topics')
        .doc('selected')
        .collection(widget.topicName)
        .doc('quizzes');
    final timesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('topics')
        .doc('selected')
        .collection(widget.topicName)
        .doc('times');
    int quizCount = 0;
    int correct = 0;
    int questionsPerQuiz = 10; // Change if dynamic
    try {
      final quizDoc = await quizzesRef.get();
      if (quizDoc.exists && quizDoc.data() != null) {
        final data = quizDoc.data()!;
        quizCount = data.length;
        correct = data.values.fold(0, (sum, v) => sum + (v is int ? v : 0));
      }
      final timeDoc = await timesRef.get();
      if (timeDoc.exists && timeDoc.data() != null) {
        final today = DateTime.now();
        final dateStr =
            '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        todayTimeSpent = timeDoc.data()![dateStr] ?? '0h 0m 0s';
      }
    } catch (e) {
      // ignore errors for now
    }
    if (mounted && !_disposed) {
      setState(() {
        totalQuestionsAnswered = quizCount * questionsPerQuiz;
        totalCorrectAnswers = correct;
      });
    }
  }

  // Add this helper function to handle launching URLs
  Future<void> _launchYouTubeUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        title: Text(
          widget.topicName,
          style: const TextStyle(
            color: Color(0xFF6366F1),
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuizPage(domainName: widget.topicName),
                ),
              );
            },
            child: const Text(
              "Quiz",
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.timer, color: Color(0xFF6366F1)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      TimerScreen(topicName: widget.topicName),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const Text(
              'Roadmap',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  errorMsg!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (subtopics.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No subtopics found.'),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  itemCount: subtopics.length,
                  itemBuilder: (context, i) {
                    final topic = subtopics[i];
                    final isDone = completed.contains(topic);
                    return GestureDetector(
                      onTap: () async {
                        safeSetState(() {
                          if (isDone) {
                            completed.remove(topic);
                          } else {
                            completed.add(topic);
                          }
                        });
                        await saveCompletedSubtopics();
                        final nextSubtopic = getNextSubtopicForTopic(
                          widget.topicName,
                          subtopics,
                          completed,
                        );
                        if (nextSubtopic != null && nextSubtopic.isNotEmpty) {
                          final ytQuery = '${widget.topicName} $nextSubtopic';
                          await fetchYouTubeForNextSubtopic(ytQuery);
                        } else {
                          safeSetState(() {
                            ytError = 'All subtopics completed!';
                            ytLoading = false;
                            ytVideos = [];
                          });
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? Colors.green
                                      : const Color(
                                          0xFF6366F1,
                                        ).withOpacity(0.18),
                                  shape: BoxShape.circle,
                                  border: isDone
                                      ? Border.all(
                                          color: Colors.green,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: isDone
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                              if (i != subtopics.length - 1)
                                Container(
                                  width: 4,
                                  height: 32,
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withOpacity(0.10),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            topic,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDone
                                  ? Colors.green
                                  : const Color(0xFF1E293B),
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 32),
            // Your Story/Stats Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Stats',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue),
                  onPressed: _fetchStats,
                  tooltip: 'Refresh Stats',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                label: 'Correct Answers',
                child: Text(
                  '$totalCorrectAnswers',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                label: 'Total Questions Answered',
                child: Text(
                  '$totalQuestionsAnswered',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Average Quiz Score Card
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                label: 'Average Quiz Score',
                child: Text(
                  totalQuestionsAnswered > 0
                      ? '${((totalCorrectAnswers / totalQuestionsAnswered) * 100).round()}%'
                      : '0%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                label: 'Total Time Spent Today',
                child: Text(
                  todayTimeSpent,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // YouTube Videos Section
            const Text(
              'Suggestions for your next topic',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            if (ytLoading)
              const Center(child: CircularProgressIndicator())
            else if (ytError != null)
              Text(ytError!, style: const TextStyle(color: Colors.red))
            else if (ytVideos.isEmpty)
              const Text('No videos found.')
            else
              SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ytVideos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final vid = ytVideos[i];
                    return SizedBox(
                      width: 200,
                      child: Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final url = vid['link'] ?? '';
                            if (url.isNotEmpty) {
                              await _launchYouTubeUrl(url);
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Image.network(
                                  vid['thumbnail'] ?? '',
                                  width: 200,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 200,
                                    height: 120,
                                    color: const Color(0xFFE0E7FF),
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  vid['title'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 0,
                              ), // replaces Spacer to avoid overflow
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 12.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextButton(
                                    onPressed: () async {
                                      final url = vid['link'] ?? '';
                                      if (url.isNotEmpty) {
                                        await _launchYouTubeUrl(url);
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Watch'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Stat card widget
class _StatCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _StatCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            child,
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 17,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Update stat widgets to accept a size parameter and use it
class _QuizzesSolvedCounter extends StatelessWidget {
  final int solved;
  final int total;
  final double size;
  const _QuizzesSolvedCounter({
    required this.solved,
    required this.total,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    double percent = total == 0 ? 0 : solved / total;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: percent,
                strokeWidth: 9,
                backgroundColor: Colors.blue.shade50,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
              ),
            ),
            Text(
              '$solved/$total',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _QuizPerformanceStat extends StatelessWidget {
  final int average;
  final double size;
  const _QuizPerformanceStat({required this.average, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$average%',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Avg. Score',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
      ],
    );
  }
}

class _TimeSpentStat extends StatelessWidget {
  final int minutes;
  final double size;
  const _TimeSpentStat({required this.minutes, this.size = 60});

  String get timeString {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    } else {
      return '${m}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Text(
            timeString,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Time Spent',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15),
        ),
      ],
    );
  }
}
