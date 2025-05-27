import 'package:app_fitness/model/local_workout_notes.dart';
import 'package:hive/hive.dart';

class LocalNotesRepository {
  static const String _boxName = 'workout_notes_box';

  Future<Box<LocalWorkoutNote>> _getOpenBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<LocalWorkoutNote>(_boxName);
    }
    return Hive.box<LocalWorkoutNote>(_boxName);
  }

  Future<void> saveNote(LocalWorkoutNote note) async {
    final box = await _getOpenBox();
    await box.put(note.dayIdentifier, note);
    print("Nota guardada/actualizada para: ${note.dayIdentifier}");
  }

  Future<LocalWorkoutNote?> getNote(String dayIdentifier) async {
    final box = await _getOpenBox();
    return box.get(dayIdentifier);
  }

  Future<List<LocalWorkoutNote>> getAllNotes() async {
    final box = await _getOpenBox();
    return box.values.toList();
  }

  Future<void> deleteNote(String dayIdentifier) async {
    final box = await _getOpenBox();
    await box.delete(dayIdentifier);
    print("Nota eliminada para: $dayIdentifier");
  }

  Future<void> closeBox() async {
    final box = await _getOpenBox();
    await box.close();
  }
}
