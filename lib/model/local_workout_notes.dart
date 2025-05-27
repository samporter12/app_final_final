import 'package:hive/hive.dart';

part 'local_workout_notes.g.dart';

@HiveType(typeId: 0)
class LocalWorkoutNote extends HiveObject {
  @HiveField(0)
  String dayIdentifier;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime lastUpdated;

  LocalWorkoutNote({
    required this.dayIdentifier,
    required this.content,
    required this.lastUpdated,
  });

  LocalWorkoutNote copyWith({
    String? dayIdentifier,
    String? content,
    DateTime? lastUpdated,
  }) {
    return LocalWorkoutNote(
      dayIdentifier: dayIdentifier ?? this.dayIdentifier,
      content: content ?? this.content,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
