import 'package:app_fitness/model/exercise_model.dart';
import 'package:app_fitness/presentation/widgets/exercise_card.dart';
import 'package:flutter/material.dart';

class WorkoutDayPanel extends StatelessWidget {
  final WorkoutDayModel workoutDay;
  final int dayIndex;

  const WorkoutDayPanel({
    super.key,
    required this.workoutDay,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        key: PageStorageKey<String>('workout_day_$dayIndex'),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            (dayIndex + 1).toString(),
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          workoutDay.dayName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          "${workoutDay.exercises.length} ejercicios",
          style: theme.textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 4.0,
        ),
        children:
            workoutDay.exercises.map((exercise) {
              return ExerciseCard(exercise: exercise);
            }).toList(),
      ),
    );
  }
}
