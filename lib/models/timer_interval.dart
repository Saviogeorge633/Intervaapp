class TimerInterval {
  final String id;
  final String name;
  final int durationSeconds;
  final int colorValue;

  TimerInterval({
    required this.id,
    required this.name,
    required this.durationSeconds,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'durationSeconds': durationSeconds,
        'colorValue': colorValue,
      };

  factory TimerInterval.fromJson(Map<String, dynamic> json) => TimerInterval(
        id: json['id'] as String,
        name: json['name'] as String,
        durationSeconds: json['durationSeconds'] as int,
        colorValue: json['colorValue'] as int,
      );
}
