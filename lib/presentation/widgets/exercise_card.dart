import 'package:app_fitness/model/exercise_model.dart';
import 'package:flutter/material.dart';

class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback? onToggleComplete;
  final bool isCompleted;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.onToggleComplete,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  context,
                  "Series",
                  exercise.sets.toString(),
                  Icons.repeat,
                ),
                _buildInfoChip(
                  context,
                  "Reps",
                  exercise.reps,
                  Icons.fitness_center,
                ),
                _buildInfoChip(
                  context,
                  "Descanso",
                  "${exercise.rest}s",
                  Icons.timer_outlined,
                ),
              ],
            ),
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Text(
                "Notas:",
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(exercise.notes!, style: theme.textTheme.bodySmall),
            ],
            if (onToggleComplete != null) ...[
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color:
                        isCompleted
                            ? Colors.green
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  onPressed: onToggleComplete,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
