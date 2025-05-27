import 'package:app_fitness/model/recipe_model.dart';
import 'package:app_fitness/presentation/widgets/nutrition_info_chip.dart';
import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final int recipeIndex;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.recipeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        key: PageStorageKey<String>('recipe_card_$recipeIndex'),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.tertiaryContainer,
          child: Icon(
            _getRecipeTypeIcon(recipe.type),
            color: theme.colorScheme.onTertiaryContainer,
          ),
        ),
        title: Text(
          recipe.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          recipe.type +
              (recipe.description != null && recipe.description!.isNotEmpty
                  ? " - ${recipe.description}"
                  : ""),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.all(16.0),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ingredientes:",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4.0),
          ...recipe.ingredients
              .map(
                (ing) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                  child: Text("• $ing"),
                ),
              )
              .toList(),
          const SizedBox(height: 12.0),
          Text(
            "Preparación:",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(recipe.preparation),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              if (recipe.calories != null)
                NutritionInfoChip(
                  label: "Calorías",
                  value: "${recipe.calories} kcal",
                  icon: Icons.local_fire_department_outlined,
                ),
              if (recipe.protein != null)
                NutritionInfoChip(
                  label: "Proteína",
                  value: "${recipe.protein}g",
                  icon: Icons.fitness_center,
                ),
              if (recipe.carbs != null)
                NutritionInfoChip(
                  label: "Carbs",
                  value: "${recipe.carbs}g",
                  icon: Icons.grain_outlined,
                ),
              if (recipe.fats != null)
                NutritionInfoChip(
                  label: "Grasas",
                  value: "${recipe.fats}g",
                  icon: Icons.oil_barrel_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getRecipeTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'desayuno':
        return Icons.free_breakfast_outlined;
      case 'almuerzo':
        return Icons.lunch_dining_outlined;
      case 'cena':
        return Icons.dinner_dining_outlined;
      case 'snack':
        return Icons.fastfood_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }
}
