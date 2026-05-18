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
  final bool shouldAutoResume; // true = auto-start timer on open (from Resume dialog)

  const ActiveTimerScreen({
    super.key,
    required this.intervals,
    this.resumingState,
    this.shouldAutoResume = false,
  });

  @override
  _ActiveTimerScreenState createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen> {
  int _currentIndex = 0;
  int _secondsLeft = 0;
  bool _isPaused = false;
  bool _needsServiceStart = false;
  StreamSubscription? _updateSub;
  StreamSubscription? _completedSub;
  StreamSubscription? _stoppedSub;
  
  @override
  void initState() {
    super.initState();
    
    // Request immediate state from the background service
    FlutterBackgroundService().invoke('requestUpdate');

    _updateSub = FlutterBackgroundService().on('update').listen((event) {
      if (event != null && mounted) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event);
        final state = ActiveSessionState.fromJson(Map<String, dynamic>.from(data['state']));
        setState(() {
          _currentIndex = state.currentIndex;
          _secondsLeft = state.secondsLeft;
          _isPaused = data['isPaused'] ?? false;
        });
      }
    });

    _completedSub = FlutterBackgroundService().on('completed').listen((event) {
      if (mounted) Navigator.pop(context);
    });

    _stoppedSub = FlutterBackgroundService().on('stopped').listen((event) {
      if (mounted) Navigator.pop(context);
    });

    if (widget.resumingState != null) {
      _currentIndex = widget.resumingState!.currentIndex;
      _secondsLeft = widget.resumingState!.secondsLeft;
      
      if (widget.shouldAutoResume) {
        // Came from the Resume dialog — ensure the timer is running.
        FlutterBackgroundService().isRunning().then((isRunning) {
          if (isRunning) {
            // Service alive but may be paused — unpause it.
            TimerService().resumeSession();
          } else {
            // Service was killed — restart it from the saved position.
            TimerService().startSession(widget.resumingState!);
          }
        });
      }
      // If shouldAutoResume is false (mini toolbar tap), preserve whatever
      // state the service is in — updates arrive via _updateSub.
    } else if (widget.intervals.isNotEmpty) {
      _secondsLeft = widget.intervals[0].durationSeconds;
      
      final initialState = ActiveSessionState(
        intervals: widget.intervals,
        currentIndex: 0,
        secondsLeft: widget.intervals[0].durationSeconds,
      );
      
      TimerService().startSession(initialState);
    }
  }

  @override
  void dispose() {
    _updateSub?.cancel();
    _completedSub?.cancel();
    _stoppedSub?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _handlePlayPause() {
    if (_isPaused) {
      // Resuming
      if (_needsServiceStart) {
        // Service was dead — start it fresh from current position
        final state = ActiveSessionState(
          intervals: widget.intervals,
          currentIndex: _currentIndex,
          secondsLeft: _secondsLeft,
        );
        TimerService().startSession(state);
        _needsServiceStart = false;
      } else {
        TimerService().resumeSession();
      }
    } else {
      // Pausing
      TimerService().pauseSession();
    }
    setState(() { _isPaused = !_isPaused; });
  }

  void _handleStop() {
    // Cancel listeners FIRST to prevent double-pop
    _updateSub?.cancel();
    _completedSub?.cancel();
    _stoppedSub?.cancel();
    TimerService().stopSession();
    Navigator.pop(context);
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
          onPressed: () => Navigator.pop(context),
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
                onPressed: () => TimerService().skipPrevious(),
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
                  onPressed: _handlePlayPause,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                iconSize: 32,
                icon: Icon(Icons.skip_next, color: colors.primaryText),
                onPressed: () => TimerService().skipNext(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _handleStop,
            icon: Icon(Icons.stop_circle_outlined, color: colors.warning),
            label: Text("Stop Session", style: TextStyle(color: colors.warning, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
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
                  Text("Up Next", style: Theme.of(context).textTheme.titleLarge),
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
                                Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(interval.colorValue), shape: BoxShape.circle)),
                                const SizedBox(width: 16),
                                Expanded(child: Text(interval.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                Text(_formatTime(interval.durationSeconds), style: TextStyle(color: colors.mutedText)),
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
