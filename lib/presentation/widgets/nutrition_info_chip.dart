import 'package:flutter/material.dart';

class NutritionInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? backgroundColor;

  const NutritionInfoChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar:
          icon != null
              ? Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              )
              : null,
      label: Text(
        '$label: $value',
        style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
      ),
      backgroundColor:
          backgroundColor ??
          theme.colorScheme.secondaryContainer.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }
}
