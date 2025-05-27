part of 'local_workout_notes.dart';

class LocalWorkoutNoteAdapter extends TypeAdapter<LocalWorkoutNote> {
  @override
  final int typeId = 0;

  @override
  LocalWorkoutNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalWorkoutNote(
      dayIdentifier: fields[0] as String,
      content: fields[1] as String,
      lastUpdated: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LocalWorkoutNote obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dayIdentifier)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalWorkoutNoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
