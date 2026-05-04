import 'timer_interval.dart';

class IntervalSession {
  final String id;
  final String name;
  final List<TimerInterval> intervals;

  IntervalSession({
    required this.id,
    required this.name,
    required this.intervals,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'intervals': intervals.map((e) => e.toJson()).toList(),
      };

  factory IntervalSession.fromJson(Map<String, dynamic> json) => IntervalSession(
        id: json['id'] as String,
        name: json['name'] as String,
        intervals: (json['intervals'] as List<dynamic>)
            .map((e) => TimerInterval.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
