import 'package:flutter/material.dart';

class TopicPage extends StatelessWidget {
  final String topicName;
  const TopicPage({super.key, required this.topicName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          topicName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
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
            _RoadmapWidget(),
            const SizedBox(height: 32),
            // Progress/Stats Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Your Stats',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    _QuizzesSolvedCounter(solved: 12, total: 20, size: 120),
                    SizedBox(height: 32),
                    _QuizPerformanceStat(average: 82, size: 120),
                    SizedBox(height: 32),
                    _TimeSpentStat(minutes: 135, size: 120),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // AI Generated Quiz Button at bottom
            Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 18),
                      leading: Icon(Icons.quiz,
                          color: Colors.blue.shade400, size: 32),
                      title: const Text('Generate Quiz',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.black54),
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadmapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder roadmap with nodes and lines
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RoadmapNode('Arrops'),
            _RoadmapNode('Lintog Lids'),
            _RoadmapNode('Stands', italic: true),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _RoadmapNode('Guiecs'),
            _RoadmapNode('Trees'),
            _RoadmapNode('Goophs'),
          ],
        ),
      ],
    );
  }
}

class _RoadmapNode extends StatelessWidget {
  final String label;
  final bool italic;
  const _RoadmapNode(this.label, {this.italic = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          color: Colors.black87,
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
        const Text('Quizzes\nSolved',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
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
