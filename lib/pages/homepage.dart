import 'package:flutter/material.dart';
import 'package:umous/pages/chat.dart';
import 'dart:math';
import './choose_topics_page.dart';

// Add the generic TopicPage
class TopicPage extends StatelessWidget {
  final String topicName;
  const TopicPage({super.key, required this.topicName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topicName),
      ),
      body: Center(
        child: Text('Content for $topicName will appear here.'),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // User's selected topics (default to 4)
  List<String> selectedTopics = [
    'Python Programming',
    'Data Structures',
    'Operating Systems',
    'Algorithms',
  ];

  void _chooseTopics() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ChooseTopicsPage(
          selectedTopics: selectedTopics,
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        selectedTopics = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This list will later come from user selection/database
    // final List<String> topics = [
    //   'Python Programming',
    //   'Data Structures',
    //   'Operating Systems',
    //   'Algorithms',
    // ];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.account_circle_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Choose Topics'),
              onTap: () {
                Navigator.pop(context);
                _chooseTopics();
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatTutor()),
          );
        },
        child: const Icon(Icons.chat),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Plan Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Today's Plan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Review firees today',
                        style: TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 20, color: Colors.black54),
                ],
              ),
            ),
            // Continue Learning
            const Text(
              'Continue Learning',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: selectedTopics
                  .map((topic) => _LearningCard(topicName: topic))
                  .toList(),
            ),
            const SizedBox(height: 28),
            // Productivity Chart
            const Text(
              'Productivity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            // Chart + Stats Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Blue GitHub-style chart fills width
                  const BlueContributionChart(),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 32,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: const [
                      _ProductivityStat(
                          label: 'Longest Streak', value: '12 days'),
                      _ProductivityStat(
                          label: 'Current Streak', value: '5 days'),
                      _ProductivityStat(
                          label: 'Highest Productivity', value: '7h'),
                      _ProductivityStat(label: "Yesterday's", value: '4h'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }
}

// Refactor _LearningCard to accept topicName and navigate to TopicPage
class _LearningCard extends StatelessWidget {
  final String topicName;
  const _LearningCard({required this.topicName});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TopicPage(topicName: topicName)),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                topicName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

class BlueContributionChart extends StatelessWidget {
  const BlueContributionChart({super.key});

  // Simulated productivity data for a 7-row, N-column grid
  List<List<int>> _generateFakeData(int rows, int cols) {
    final random = Random();
    return List.generate(
        rows, (_) => List.generate(cols, (_) => random.nextInt(5)));
  }

  Color _getBlueShade(int value) {
    // 0 = lightest, 4 = darkest
    switch (value) {
      case 0:
        return Colors.blue.shade50;
      case 1:
        return Colors.blue.shade100;
      case 2:
        return Colors.blue.shade300;
      case 3:
        return Colors.blue.shade500;
      case 4:
      default:
        return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const int rows = 7;
        const double minCellSize = 12.0;
        const double maxCellSize = 20.0;
        const double cellSpacing = 4.0;
        // Calculate max columns that fit in the available width
        int cols =
            ((constraints.maxWidth + cellSpacing) / (minCellSize + cellSpacing))
                .floor();
        double cellSize =
            (constraints.maxWidth - (cols - 1) * cellSpacing) / cols;
        cellSize = cellSize.clamp(minCellSize, maxCellSize);
        // Recalculate cols in case cellSize was clamped
        cols = ((constraints.maxWidth + cellSpacing) / (cellSize + cellSpacing))
            .floor();
        final data = _generateFakeData(rows, cols);
        return SizedBox(
          height: rows * cellSize + (rows - 1) * cellSpacing,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(cols, (col) {
              return Padding(
                padding:
                    EdgeInsets.only(right: col == cols - 1 ? 0 : cellSpacing),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(rows, (row) {
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: row == rows - 1 ? 0 : cellSpacing),
                      child: Container(
                        width: cellSize,
                        height: cellSize,
                        decoration: BoxDecoration(
                          color: _getBlueShade(data[row][col]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _ProductivityStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProductivityStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
