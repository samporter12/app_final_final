import 'package:app_fitness/model/local_workout_notes.dart';
import 'package:get/get.dart';
import 'package:app_fitness/data/repositories/local_notes_repository.dart';

class LocalNotesController extends GetxController {
  final LocalNotesRepository _repository = Get.find<LocalNotesRepository>();

  final RxMap<String, LocalWorkoutNote> workoutNotes =
      <String, LocalWorkoutNote>{}.obs;
  final RxBool isLoadingNote = false.obs;
  final RxString noteError = ''.obs;

  Future<void> loadNoteForDay(String dayIdentifier) async {
    isLoadingNote.value = true;
    noteError.value = '';
    try {
      final note = await _repository.getNote(dayIdentifier);
      if (note != null) {
        workoutNotes[dayIdentifier] = note;
      } else {
        workoutNotes.remove(dayIdentifier);
      }
    } catch (e) {
      noteError.value = "Error al cargar la nota: $e";
      print(noteError.value);
    } finally {
      isLoadingNote.value = false;
    }
  }

  Future<void> saveOrUpdateNote(String dayIdentifier, String content) async {
    isLoadingNote.value = true;
    noteError.value = '';
    try {
      LocalWorkoutNote? existingNote = workoutNotes[dayIdentifier];
      if (existingNote != null) {
        existingNote.content = content;
        existingNote.lastUpdated = DateTime.now();
        await _repository.saveNote(existingNote);
        workoutNotes[dayIdentifier] = existingNote;
      } else {
        final newNote = LocalWorkoutNote(
          dayIdentifier: dayIdentifier,
          content: content,
          lastUpdated: DateTime.now(),
        );
        await _repository.saveNote(newNote);
        workoutNotes[dayIdentifier] = newNote;
      }
      Get.snackbar(
        "Nota Guardada",
        "Tu nota ha sido guardada localmente.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      noteError.value = "Error al guardar la nota: $e";
      print(noteError.value);
      Get.snackbar(
        "Error",
        noteError.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingNote.value = false;
    }
  }

  LocalWorkoutNote? getNoteForDay(String dayIdentifier) {
    return workoutNotes[dayIdentifier];
  }
}
