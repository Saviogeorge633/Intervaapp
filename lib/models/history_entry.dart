import 'package:hive/hive.dart';

class HistoryEntry {
  final String intervalName;
  final int durationSeconds;
  final DateTime completedAt;

  HistoryEntry({
    required this.intervalName,
    required this.durationSeconds,
    required this.completedAt,
  });
}

class HistoryEntryAdapter extends TypeAdapter<HistoryEntry> {
  @override
  final int typeId = 0;

  @override
  HistoryEntry read(BinaryReader reader) {
    return HistoryEntry(
      intervalName: reader.read() as String,
      durationSeconds: reader.read() as int,
      completedAt: DateTime.parse(reader.read() as String),
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntry obj) {
    writer.write(obj.intervalName);
    writer.write(obj.durationSeconds);
    writer.write(obj.completedAt.toIso8601String());
  }
}
