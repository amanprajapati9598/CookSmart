class Recipe {
  final String title;
  final int cookingTime;
  final int calories;
  final int proteins;
  final int carbs;
  final int fats;
  final int matchedIngredients;
  final int totalIngredients;
  final String imageUrl;
  final List<String> instructions;
  final List<String> ingredientsList;
  final List<String> missingIngredients;
  final Map<String, String> substitutes;
  final String difficulty;

  Recipe({
    required this.title,
    required this.cookingTime,
    required this.calories,
    this.proteins = 0,
    this.carbs = 0,
    this.fats = 0,
    required this.matchedIngredients,
    required this.totalIngredients,
    required this.imageUrl,
    required this.instructions,
    required this.ingredientsList,
    this.missingIngredients = const [],
    this.substitutes = const {},
    this.difficulty = 'Medium',
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    Map<String, String> parsedSubstitutes = {};
    if (json['Substitutes'] != null) {
      json['Substitutes'].forEach((key, value) {
        parsedSubstitutes[key.toString()] = value.toString();
      });
    }

    return Recipe(
      title: json['Title'] ?? json['title'] ?? 'Unknown Recipe',
      cookingTime: json['Cooking_Time'] ?? json['cookingTime'] ?? 0,
      calories: json['Calories'] ?? json['calories'] ?? 0,
      proteins: json['Proteins'] ?? json['proteins'] ?? 0,
      carbs: json['Carbs'] ?? json['carbs'] ?? 0,
      fats: json['Fats'] ?? json['fats'] ?? 0,
      matchedIngredients: json['Matched_Ingredients'] ?? 0,
      totalIngredients: json['Total_Ingredients'] ?? 0,
      imageUrl: json['Image_URL'] ?? json['imageUrl'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=1200',
      instructions: json['Instructions'] != null ? List<String>.from(json['Instructions']) : (json['instructions'] != null ? List<String>.from(json['instructions']) : []),
      ingredientsList: json['Ingredients_List'] != null ? List<String>.from(json['Ingredients_List']) : (json['ingredients'] != null ? List<String>.from(json['ingredients']) : []),
      missingIngredients: json['Missing_Ingredients'] != null ? List<String>.from(json['Missing_Ingredients']) : [],
      substitutes: parsedSubstitutes,
      difficulty: json['Difficulty'] ?? 'Medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'Cooking_Time': cookingTime,
      'Calories': calories,
      'Proteins': proteins,
      'Carbs': carbs,
      'Fats': fats,
      'Matched_Ingredients': matchedIngredients,
      'Total_Ingredients': totalIngredients,
      'Image_URL': imageUrl,
      'Instructions': instructions,
      'Ingredients_List': ingredientsList,
      'Missing_Ingredients': missingIngredients,
      'Substitutes': substitutes,
      'Difficulty': difficulty,
      // Provide compatibility fields for ProfileScreen
      'title': title,
      'imageUrl': imageUrl,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
    };
  }
}
