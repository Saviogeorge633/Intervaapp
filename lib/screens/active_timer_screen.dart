import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../models/timer_interval.dart';
import '../models/active_session_state.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_progress_ring.dart';
import '../widgets/timer_card.dart';
import '../services/timer_service.dart';

class ActiveTimerScreen extends StatefulWidget {
  final List<TimerInterval> intervals;
  final ActiveSessionState? resumingState;

  const ActiveTimerScreen({Key? key, required this.intervals, this.resumingState}) : super(key: key);

  @override
  _ActiveTimerScreenState createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen> {
  int _currentIndex = 0;
  int _secondsLeft = 0;
  bool _isPaused = false;
  StreamSubscription? _updateSub;
  StreamSubscription? _completedSub;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.resumingState != null) {
      _currentIndex = widget.resumingState!.currentIndex;
      _secondsLeft = widget.resumingState!.secondsLeft;
      
      FlutterBackgroundService().isRunning().then((isRunning) {
        if (!isRunning) {
          TimerService().startSession(widget.resumingState!);
        }
      });
    } else if (widget.intervals.isNotEmpty) {
      _secondsLeft = widget.intervals[0].durationSeconds;
      
      final initialState = ActiveSessionState(
        intervals: widget.intervals,
        currentIndex: 0,
        secondsLeft: widget.intervals[0].durationSeconds,
      );
      
      TimerService().startSession(initialState);
    }

    _updateSub = FlutterBackgroundService().on('update').listen((event) {
      if (event != null && mounted) {
        final state = ActiveSessionState.fromJson(Map<String, dynamic>.from(event));
        setState(() {
          _currentIndex = state.currentIndex;
          _secondsLeft = state.secondsLeft;
        });
      }
    });

    _completedSub = FlutterBackgroundService().on('completed').listen((event) {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _updateSub?.cancel();
    _completedSub?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(isDark);
    
    if (widget.intervals.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Timer')),
        body: const Center(child: Text("No intervals to play.")),
      );
    }

    final currentInterval = widget.intervals[_currentIndex];
    final progress = _secondsLeft / currentInterval.durationSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Session'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          SizedBox(
            width: 260,
            height: 260,
            child: CircularProgressRing(
              progress: progress,
              activeColor: Color(currentInterval.colorValue),
              trackColor: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentInterval.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(_secondsLeft),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: colors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 32,
                icon: Icon(Icons.skip_previous, color: colors.primaryText),
                onPressed: () {
                  TimerService().skipPrevious();
                },
              ),
              const SizedBox(width: 24),
              Container(
                decoration: BoxDecoration(
                  color: Color(currentInterval.colorValue),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: 48,
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isPaused = !_isPaused;
                    });
                    if (_isPaused) {
                      TimerService().pauseSession();
                    } else {
                      TimerService().resumeSession();
                    }
                  },
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                iconSize: 32,
                icon: Icon(Icons.skip_next, color: colors.primaryText),
                onPressed: () {
                  TimerService().skipNext();
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Up Next",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.intervals.length - _currentIndex - 1,
                      itemBuilder: (context, index) {
                        final interval = widget.intervals[_currentIndex + 1 + index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: TimerCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(interval.colorValue),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    interval.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  _formatTime(interval.durationSeconds),
                                  style: TextStyle(color: colors.mutedText),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
