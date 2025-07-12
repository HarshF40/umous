import 'package:flutter/material.dart';
import 'package:umous/pages/chat.dart';
import 'dart:math';
import './choose_topics_page.dart';
import './topic_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umous/pages/profile.dart';
import 'package:umous/pages/groups_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // User's selected topics (start empty)
  List<String> selectedTopics = [];
  bool _loadingTopics = true;
  int _selectedIndex = 0;

  String? _todaysPlan;
  bool _loadingPlan = false;

  @override
  void initState() {
    super.initState();
    _fetchUserTopics();
    _fetchTodaysPlan();
  }

  Future<void> _fetchUserTopics() async {
    setState(() {
      _loadingTopics = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('topics')
            .doc('selected')
            .get();
        final data = doc.data();
        if (data != null && data['selectedTopics'] is List) {
          selectedTopics = List<String>.from(data['selectedTopics']);
        }
      }
    } catch (e) {
      // Optionally handle error
    }
    setState(() {
      _loadingTopics = false;
    });
  }

  Future<void> _fetchTodaysPlan() async {
    setState(() {
      _loadingPlan = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final dateStr =
            "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('todays_plan')
            .doc(dateStr)
            .get();
        final data = doc.data();
        if (data != null && data['plan'] is String) {
          _todaysPlan = data['plan'];
        } else {
          _todaysPlan = null;
        }
      }
    } catch (e) {
      // Optionally handle error
    }
    setState(() {
      _loadingPlan = false;
    });
  }

  Future<void> _saveTodaysPlan(String plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final today = DateTime.now();
    final dateStr =
        "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('todays_plan')
        .doc(dateStr)
        .set({'plan': plan});
    setState(() {
      _todaysPlan = plan;
    });
  }

  void _showTodaysPlanEditor() async {
    final controller = TextEditingController(text: _todaysPlan ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What's your plan for today?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 6,
                minLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Type your plan for today... (e.g. Study OS, finish assignment, etc.)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, controller.text.trim());
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      await _saveTodaysPlan(result);
    }
  }

  void _chooseTopics() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ChooseTopicsPage(selectedTopics: selectedTopics),
      ),
    );
    setState(() {
      if (result != null) {
        selectedTopics = result;
      }
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Close the drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _selectedIndex == 0
              ? 'Home'
              : _selectedIndex == 1
              ? 'Groups'
              : 'Your Profile',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
        ),
      ),
      drawer: _selectedIndex == 0
          ? Drawer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Study Hub',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Your learning journey',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.list_alt, color: Colors.white),
                      ),
                      title: const Text(
                        'Choose Topics',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _chooseTopics();
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.logout, color: Colors.white),
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButton: _selectedIndex == 0
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatTutor()),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.chat, color: Colors.white),
              ),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Home tab
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's Plan Card
                GestureDetector(
                  onTap: _showTodaysPlanEditor,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.edit_note,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Today's Plan",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _loadingPlan
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      _todaysPlan?.isNotEmpty == true
                                          ? _todaysPlan!
                                          : 'Tap to add your plan for today',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        height: 1.4,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Continue Learning
                const Text(
                  'Continue Learning',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.9,
                  children: selectedTopics
                      .map((topic) => _LearningCard(topicName: topic))
                      .toList(),
                ),
                const SizedBox(height: 32),
                // Productivity Chart
                const Text(
                  'Productivity',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 20),
                // Chart + Stats Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Blue GitHub-style chart fills width
                      BlueContributionChart(selectedTopics: selectedTopics),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Groups tab
          const GroupsTab(),
          // Profile tab
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: const Color(0xFF94A3B8),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicPage(topicName: topicName),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withOpacity(0.1),
              const Color(0xFF8B5CF6).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Color(0xFF6366F1),
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    topicName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlueContributionChart extends StatelessWidget {
  final List<String> selectedTopics;
  const BlueContributionChart({super.key, required this.selectedTopics});

  Future<Map<String, double>> _fetchStudyHoursPerDay() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final now = DateTime.now();
    final days = List.generate(60, (i) => now.subtract(Duration(days: 59 - i)));
    final dateStrs = days
        .map(
          (d) =>
              "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}",
        )
        .toList();
    Map<String, double> hoursPerDay = {for (var d in dateStrs) d: 0.0};
    for (final topic in selectedTopics) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('topics')
          .doc('selected')
          .collection(topic)
          .doc('times')
          .get();
      final data = doc.data();
      if (data != null) {
        for (final d in dateStrs) {
          if (data[d] != null) {
            final t = data[d] as String;
            final parts = t
                .split(':')
                .map((e) => int.tryParse(e) ?? 0)
                .toList();
            final h = parts.isNotEmpty ? parts[0] : 0;
            final m = parts.length > 1 ? parts[1] : 0;
            final s = parts.length > 2 ? parts[2] : 0;
            hoursPerDay[d] = (hoursPerDay[d] ?? 0) + h + m / 60 + s / 3600;
          }
        }
      }
    }
    return hoursPerDay;
  }

  Color _getBlueShade(double value, double max) {
    if (value == 0) return const Color(0xFFF1F5F9);
    if (value > 0 && value <= 2) return const Color(0xFFE0E7FF);
    if (value > 2 && value <= 4) return const Color(0xFFC7D2FE);
    if (value > 4 && value <= 6) return const Color(0xFFA5B4FC);
    if (value > 6 && value <= 8) return const Color(0xFF818CF8);
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: _fetchStudyHoursPerDay(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        final max = data.values.fold<double>(0, (p, v) => v > p ? v : p);
        // --- Streaks and stats ---
        int longestStreak = 0;
        int currentStreak = 0;
        int streak = 0;
        double highestProductivity = 0;
        double yesterdaysTotal = 0;
        final daysList = data.keys.toList();
        final todayIdx = daysList.length - 1;
        final yesterdayIdx = daysList.length - 2;
        for (int i = 0; i < daysList.length; i++) {
          final v = data[daysList[i]] ?? 0.0;
          if (v > 0) {
            streak++;
            if (streak > longestStreak) longestStreak = streak;
          } else {
            streak = 0;
          }
          if (v > highestProductivity) highestProductivity = v;
        }
        // Calculate current streak (ending at today)
        for (int i = daysList.length - 1; i >= 0; i--) {
          final v = data[daysList[i]] ?? 0.0;
          if (v > 0) {
            currentStreak++;
          } else {
            break;
          }
        }
        if (yesterdayIdx >= 0) {
          yesterdaysTotal = data[daysList[yesterdayIdx]] ?? 0.0;
        }
        // --- Chart ---
        const int cols = 10;
        const int rows = 6;
        const double minCellSize = 14.0;
        const double maxCellSize = 24.0;
        const double cellSpacing = 5.0;
        return Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                double cellSize =
                    (constraints.maxWidth - (cols - 1) * cellSpacing) / cols;
                cellSize = cellSize.clamp(minCellSize, maxCellSize);
                return SizedBox(
                  height: rows * cellSize + (rows - 1) * cellSpacing,
                  width: double.infinity,
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(cols, (col) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: col == cols - 1 ? 0 : cellSpacing,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: List.generate(rows, (row) {
                              final idx = col * rows + row;
                              if (idx >= daysList.length) {
                                return SizedBox(
                                  height: cellSize,
                                  width: cellSize,
                                );
                              }
                              final d = daysList[idx];
                              final v = data[d] ?? 0.0;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: row == rows - 1 ? 0 : cellSpacing,
                                ),
                                child: Tooltip(
                                  message: "$d\n${v.toStringAsFixed(2)}h",
                                  child: Container(
                                    width: cellSize,
                                    height: cellSize,
                                    decoration: BoxDecoration(
                                      color: _getBlueShade(v, max),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 32,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _ProductivityStat(
                  label: 'Longest Streak',
                  value: '${longestStreak} days',
                ),
                _ProductivityStat(
                  label: 'Current Streak',
                  value: '${currentStreak} days',
                ),
                _ProductivityStat(
                  label: 'Highest Productivity',
                  value: '${highestProductivity.toStringAsFixed(1)}h',
                ),
                _ProductivityStat(
                  label: "Yesterday's",
                  value: '${yesterdaysTotal.toStringAsFixed(1)}h',
                ),
              ],
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
