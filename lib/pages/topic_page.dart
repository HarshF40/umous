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

  @override
  void initState() {
    super.initState();
    _loadAllAndFetchYouTube();
  }

  Future<void> _loadAllAndFetchYouTube() async {
    await fetchSubtopics();
    await fetchCompletedSubtopics();
    final nextSubtopic =
        getNextSubtopicForTopic(widget.topicName, subtopics, completed);
    print('Next subtopic for YouTube: $nextSubtopic');
    if (nextSubtopic != null && nextSubtopic.isNotEmpty) {
      await fetchYouTubeForNextSubtopic(nextSubtopic);
    } else {
      setState(() {
        ytError = 'All subtopics completed!';
        ytLoading = false;
      });
    }
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
      setState(() {
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

    String? nextSubtopic =
        getNextSubtopicForTopic(widget.topicName, subtopics, completed);

    await docRef.set({
      'completedSubtopics': completed.toList(),
      'nextSubtopic': nextSubtopic,
    }, SetOptions(merge: true));
  }

  Future<void> fetchYouTubeForNextSubtopic(String nextSubtopic) async {
    setState(() {
      ytLoading = true;
      ytError = null;
      ytVideos = [];
    });
    try {
      print('Fetching YouTube videos for: $nextSubtopic');
      final videos = await fetchYouTubeVideos(nextSubtopic);
      setState(() {
        ytVideos = videos;
        ytLoading = false;
      });
    } catch (e) {
      setState(() {
        ytLoading = false;
        ytError = 'Failed to fetch YouTube videos.';
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
              onPressed: () {Navigator.of(context).push(MaterialPageRoute(builder: (context) => QuizPage(domainName: widget.topicName)));},
              child: Text(
                "Quiz",
                style: TextStyle(
                  color: Color(0xFF389bdc),
                ),
              )),
          IconButton(
              icon: const Icon(Icons.timer, color: Color(0xFF389bdc)),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const TimerScreen()));
              }),
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
                      onTap: () async {
                        setState(() {
                          if (isDone) {
                            completed.remove(topic);
                          } else {
                            completed.add(topic);
                          }
                        });
                        await saveCompletedSubtopics();
                        // Immediately fetch videos for the new next subtopic
                        final nextSubtopic = getNextSubtopicForTopic(
                            widget.topicName, subtopics, completed);
                        if (nextSubtopic != null && nextSubtopic.isNotEmpty) {
                          final ytQuery = '${widget.topicName} $nextSubtopic';
                          await fetchYouTubeForNextSubtopic(ytQuery);
                        } else {
                          setState(() {
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
            // YouTube Videos Section
            const Text('Suggestions for your next topic',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            if (ytLoading)
              const Center(child: CircularProgressIndicator())
            else if (ytError != null)
              Text(ytError!, style: const TextStyle(color: Colors.red))
            else if (ytVideos.isEmpty)
              const Text('No videos found.')
            else
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ytVideos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final vid = ytVideos[i];
                    return SizedBox(
                      width: 200,
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                                    top: Radius.circular(12)),
                                child: Image.network(
                                  vid['thumbnail'] ?? '',
                                  width: 200,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 200,
                                    height: 120,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  vid['title'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 8.0),
                                child: TextButton(
                                  onPressed: () async {
                                    final url = vid['link'] ?? '';
                                    if (url.isNotEmpty) {
                                      await _launchYouTubeUrl(url);
                                    }
                                  },
                                  child: const Text('Watch'),
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
