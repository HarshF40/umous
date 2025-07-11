import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimerScreen extends StatefulWidget {
  final String topicName;
  const TimerScreen({super.key, required this.topicName});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // ... existing fields ...
  DateTime? _startTime;
  Duration _pausedElapsed = Duration.zero;

  String _formattedTime = "00:00:00";
  Duration _lastDayTime = Duration.zero;

  bool _isRunning = false;

  Timer? _ticker;
  Timer? _midnightChecker;

  @override
  void initState() {
    super.initState();
    _restoreTimerState();
    _startTicker();
    _startMidnightChecker();
  }

  Future<void> _restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final isRunning = prefs.getBool('timer_isRunning') ?? false;
    final startMillis = prefs.getInt('timer_startTime');
    final pausedMillis = prefs.getInt('timer_pausedElapsed') ?? 0;
    if (isRunning && startMillis != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
      _isRunning = true;
      _pausedElapsed = Duration.zero;
      setState(() {});
    } else if (!isRunning && pausedMillis > 0) {
      _pausedElapsed = Duration(milliseconds: pausedMillis);
      _isRunning = false;
      setState(() {});
    }
  }

  Future<void> _persistTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_isRunning', _isRunning);
    if (_isRunning && _startTime != null) {
      await prefs.setInt('timer_startTime', _startTime!.millisecondsSinceEpoch);
      await prefs.setInt('timer_pausedElapsed', 0);
    } else {
      await prefs.setInt('timer_pausedElapsed', _pausedElapsed.inMilliseconds);
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _formattedTime = _formatDuration(_currentElapsed());
      });
    });
  }

  Duration _currentElapsed() {
    if (_isRunning && _startTime != null) {
      return DateTime.now().difference(_startTime!);
    } else {
      return _pausedElapsed;
    }
  }

  void _startMidnightChecker() {
    _midnightChecker = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = DateTime.now();
      if (now.hour == 0 && now.minute == 0) {
        _handleMidnightReset();
      }
    });
  }

  void _handleMidnightReset() {
    setState(() {
      _lastDayTime = _currentElapsed();
      _pausedElapsed = Duration.zero;
      _startTime = null;
      _isRunning = false;
      _formattedTime = _formatDuration(Duration.zero);
    });
    _persistTimerState();
  }

  void _toggleStartPause() {
    setState(() {
      if (_isRunning) {
        // Pause
        _pausedElapsed = _currentElapsed();
        _isRunning = false;
        _startTime = null;
      } else {
        // Start
        _startTime = DateTime.now().subtract(_pausedElapsed);
        _isRunning = true;
      }
    });
    _persistTimerState();
  }

  void _reset() {
    setState(() {
      _pausedElapsed = Duration.zero;
      _startTime = null;
      _isRunning = false;
      _formattedTime = _formatDuration(Duration.zero);
    });
    _persistTimerState();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> _saveTimeToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('topics')
        .doc('selected')
        .collection(widget.topicName)
        .doc('times');
    await docRef.set(
        {dateStr: _formatDuration(_currentElapsed())}, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Time saved for $dateStr!')),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _midnightChecker?.cancel();
    _persistTimerState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text(
          'Daily Stopwatch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDuration(_currentElapsed()),
              style: const TextStyle(
                fontSize: 64,
                color: Color(0xFF389bdc),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleStartPause,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveTimeToFirestore,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF389bdc),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Last Day Time: ${_formatDuration(_lastDayTime)}",
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF389bdc),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
