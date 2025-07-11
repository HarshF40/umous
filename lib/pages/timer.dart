import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late Stopwatch _stopwatch;
  late Timer _ticker;
  late Timer _midnightChecker;

  String _formattedTime = "00:00:00";
  Duration _lastDayTime = Duration.zero;

  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _startTicker();
    _startMidnightChecker();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopwatch.isRunning) {
        setState(() {
          _formattedTime = _formatDuration(_stopwatch.elapsed);
        });
      }
    });
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
      _lastDayTime = _stopwatch.elapsed;
      _stopwatch.reset();
      _formattedTime = _formatDuration(_stopwatch.elapsed);
    });
    // You could also persist _lastDayTime using SharedPreferences or Firebase
  }

  void _toggleStartPause() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _isRunning = false;
      } else {
        _stopwatch.start();
        _isRunning = true;
      }
    });
  }

  void _reset() {
    setState(() {
      _stopwatch.reset();
      _formattedTime = _formatDuration(_stopwatch.elapsed);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _ticker.cancel();
    _midnightChecker.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('Daily Stopwatch', style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formattedTime,
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
