import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app_fitness/controller/local_notes_controller.dart';

class WorkoutNoteEditPage extends StatefulWidget {
  const WorkoutNoteEditPage({super.key});

  @override
  State<WorkoutNoteEditPage> createState() => _WorkoutNoteEditPageState();
}

class _WorkoutNoteEditPageState extends State<WorkoutNoteEditPage> {
  final LocalNotesController _notesController =
      Get.find<LocalNotesController>();
  final TextEditingController _noteTextController = TextEditingController();

  late String dayIdentifier = '';
  String dayName = "Nota de Entrenamiento";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = Get.arguments as Map<String, dynamic>?;
      if (arguments != null && arguments.containsKey('dayIdentifier')) {
        if (mounted) {
          setState(() {
            dayIdentifier = arguments['dayIdentifier'];
            if (arguments.containsKey('dayName')) {
              dayName = arguments['dayName'];
            }
          });
          _loadExistingNote();
        }
      } else {
        Get.snackbar(
          "Error",
          "No se especificó el día para la nota.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        if (Get.previousRoute.isNotEmpty) {
          Get.back();
        }
      }
    });
  }

  void _loadExistingNote() async {
    if (dayIdentifier.isEmpty || !mounted) return;
    await _notesController.loadNoteForDay(dayIdentifier);
    final note = _notesController.getNoteForDay(dayIdentifier);
    if (note != null && mounted) {
      _noteTextController.text = note.content;
    }
  }

  void _saveNote() {
    if (dayIdentifier.isEmpty) {
      Get.snackbar(
        "Error",
        "No se puede guardar la nota: identificador de día no disponible.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _notesController.saveOrUpdateNote(dayIdentifier, _noteTextController.text);
    if (Get.isSnackbarOpen ?? false) {
      Get.closeCurrentSnackbar();
    }
    if (Get.previousRoute.isNotEmpty) {
      Get.back();
    }
  }

  @override
  void dispose() {
    _noteTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(dayName),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: "Guardar Nota",
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          if (_notesController.isLoadingNote.value &&
              _noteTextController.text.isEmpty &&
              dayIdentifier.isNotEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteTextController,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText:
                        "Escribe tus notas para este día de entrenamiento...",
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon:
                      _notesController.isLoadingNote.value
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                          : const Icon(Icons.save),
                  label: const Text("Guardar Nota"),
                  onPressed:
                      _notesController.isLoadingNote.value ? null : _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
