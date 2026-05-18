import 'package:hive/hive.dart';

class HistoryEntry {
  final String intervalName;
  final int durationSeconds;   // The full planned duration
  final int actualSeconds;     // How long the user actually ran it
  final DateTime completedAt;

  HistoryEntry({
    required this.intervalName,
    required this.durationSeconds,
    required this.completedAt,
    int? actualSeconds,
  }) : actualSeconds = actualSeconds ?? durationSeconds;

  /// Was this interval fully completed?
  bool get isCompleted => actualSeconds >= durationSeconds;
}

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 0;

  @override
  HistoryEntry read(BinaryReader reader) {
    final intervalName = reader.read() as String;
    final durationSeconds = reader.read() as int;
    final completedAt = DateTime.parse(reader.read() as String);
    // actualSeconds was added later — read it if available, else default to durationSeconds
    int actualSeconds;
    try {
      actualSeconds = reader.read() as int;
    } catch (_) {
      actualSeconds = durationSeconds;
    }
    return HistoryEntry(
      intervalName: intervalName,
      durationSeconds: durationSeconds,
      completedAt: completedAt,
      actualSeconds: actualSeconds,
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer.write(obj.intervalName);
    writer.write(obj.durationSeconds);
    writer.write(obj.completedAt.toIso8601String());
    writer.write(obj.actualSeconds);
  }
}
