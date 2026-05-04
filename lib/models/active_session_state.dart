import 'timer_interval.dart';

class ActiveSessionState {
  final List<TimerInterval> intervals;
  final int currentIndex;
  final int secondsLeft;

  ActiveSessionState({
    required this.intervals,
    required this.currentIndex,
    required this.secondsLeft,
  });

  Map<String, dynamic> toJson() => {
        'intervals': intervals.map((e) => e.toJson()).toList(),
        'currentIndex': currentIndex,
        'secondsLeft': secondsLeft,
      };

  factory ActiveSessionState.fromJson(Map<String, dynamic> json) => ActiveSessionState(
        intervals: (json['intervals'] as List<dynamic>)
            .map((e) => TimerInterval.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        currentIndex: json['currentIndex'] as int,
        secondsLeft: json['secondsLeft'] as int,
      );
}
