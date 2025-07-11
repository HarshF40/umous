import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    fetchSubtopics();
  }

  Future<void> fetchSubtopics() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('roadmaps')
          .doc('topics')
          .get();
      if (!doc.exists || doc.data() == null) {
        setState(() {
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
        setState(() {
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
      setState(() {
        isLoading = false;
        errorMsg = null;
      });
    } catch (e) {
      setState(() {
        subtopics = [];
        errorMsg = 'Error loading roadmap.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.topicName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {},
              child: Text(
                "Quiz",
                style: TextStyle(
                  color: Color(0xFF389bdc),
                ),
              )),
          IconButton(
              icon: const Icon(Icons.timer, color: Color(0xFF389bdc)),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Roadmap
            const Text('Roadmap',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ))
            else if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child:
                    Text(errorMsg!, style: const TextStyle(color: Colors.red)),
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
                      onTap: () {
                        setState(() {
                          if (isDone) {
                            completed.remove(topic);
                          } else {
                            completed.add(topic);
                          }
                        });
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
                                      : Colors.blue.shade200,
                                  shape: BoxShape.circle,
                                  border: isDone
                                      ? Border.all(
                                          color: Colors.green, width: 2)
                                      : null,
                                ),
                                child: isDone
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 16)
                                    : null,
                              ),
                              if (i != subtopics.length - 1)
                                Container(
                                  width: 4,
                                  height: 32,
                                  color: Colors.blue.shade100,
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            topic,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDone ? Colors.green : Colors.black87,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
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
            const Text('Your Stats',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                label: 'Quizzes Solved',
                child: _QuizzesSolvedCounter(solved: 12, total: 20, size: 56),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                label: 'Avg. Score',
                child: const Text('82%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _StatCard(
                label: 'Total Time Spent',
                child: const Text('2h 15m',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Colors.blue)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// Add a vertical roadmap widget
class _VerticalRoadmapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock roadmap data
    final List<String> subtopics = [
      'topic1',
      'topic2',
      'topic3',
      'topic4',
      'topic5',
      'topic6',
      'topic7',
      'topic8',
      'topic9',
      'topic10'
    ];
    return ListView.builder(
      itemCount: subtopics.length,
      itemBuilder: (context, i) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
                if (i != subtopics.length - 1)
                  Container(
                    width: 4,
                    height: 32,
                    color: Colors.blue.shade100,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              subtopics[i],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2),
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
  const _QuizzesSolvedCounter(
      {required this.solved, required this.total, this.size = 60});

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
            Text('$solved/$total',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
          child: Text('$average%',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        ),
        const SizedBox(height: 10),
        const Text('Avg. Score',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
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
          child: Text(timeString,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        const SizedBox(height: 10),
        const Text('Time Spent',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
      ],
    );
  }
}
