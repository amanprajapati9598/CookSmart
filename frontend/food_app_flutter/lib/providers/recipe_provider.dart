import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe.dart';
import '../services/gemini_service.dart';
import '../services/mealdb_service.dart';
import '../services/spoonacular_service.dart';
import '../data/indian_recipes.dart';

class RecipeProvider with ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final MealDBService _mealDbService = MealDBService();
  final SpoonacularService _spoonacularService = SpoonacularService();

  List<Recipe> _recipes = [];
  bool _isLoading = false;
  String? _error;

  List<Recipe> get recipes => _recipes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> clearRecipes() async {
    _recipes = [];
    notifyListeners();
  }

  Future<void> discoverMatches({
    required String query,
    required List<String> ingredients,
    required String diet,
    required String skill,
    int? requestedLimit,
  }) async {
    _isLoading = true;
    _error = null;
    _recipes = [];
    notifyListeners();

    try {
      // Subscription feature removed. All users can access max limits freely.
      int limit = requestedLimit ?? 30;

      // 1. Prioritize authentic recipes from MealDB matching the exact user input!
      String baseSearchQuery = query.isNotEmpty ? query : (ingredients.isNotEmpty ? ingredients.join(' ') : '');
      
      List<Map<String, dynamic>> mealList = [];
      if (baseSearchQuery.isEmpty) {
        if (diet == 'Veg') {
          mealList = await _mealDbService.fetchByCategory('Vegetarian', limit: limit * 2);
        } else if (diet == 'Vegan') {
          mealList = await _mealDbService.fetchByCategory('Vegan', limit: limit * 2);
        } else if (diet == 'All' || diet == 'Any') {
          final vegList = await _mealDbService.fetchByCategory('Vegetarian', limit: limit);
          final nonVegList = await _mealDbService.searchRecipesList('chicken', limit: limit);
          mealList = [...vegList, ...nonVegList];
          mealList.shuffle();
        } else {
          mealList = await _mealDbService.searchRecipesList('chicken', limit: limit * 2);
        }
      } else {
        mealList = await _mealDbService.searchRecipesList(baseSearchQuery, limit: limit * 2);
      }
      if (mealList.isNotEmpty) {
         var fetched = mealList.map((m) => _mapMealDbToRecipe(m, m['strMeal'] ?? baseSearchQuery, skill)).toList();
         var filtered = _filterRecipesByDiet(fetched, diet);
         
         if (filtered.isNotEmpty) {
            _recipes = filtered.take(limit).toList();
         }
      }

      // 1.5 Inject offline Indian recipes to combat API scarcity and Gemini rate limits for "paneer"
      final checkStr = baseSearchQuery.toLowerCase();
      if (checkStr.contains('paneer') || checkStr.contains('indian') || diet == 'Veg') {
         // Find matching offline recipes
         var offlineMatches = IndianRecipesData.paneerRecipes.where((r) {
             if (checkStr.isEmpty || diet == 'Veg') return true;
             
             // If multiple ingredients are provided, skip offline recipes and let Gemini handle the complex combination.
             // Offline recipes like 'Palak Paneer' require spinach which might not be in the user's fridge.
             if (ingredients.length > 1) {
                return false;
             }
             
             if (checkStr.contains('paneer') || checkStr.contains('indian')) return true;
             return r.title.toLowerCase().contains(checkStr);
         }).toList();
         
         // If they specifically searched for JUST "paneer" as a single ingredient or query, show all paneer variants
         if (ingredients.length == 1 && ingredients.first.toLowerCase() == 'paneer') {
             offlineMatches = IndianRecipesData.paneerRecipes;
         } else if (query.toLowerCase().trim() == 'paneer') {
             offlineMatches = IndianRecipesData.paneerRecipes;
         }

         if (offlineMatches.isNotEmpty) {
             _recipes.insertAll(0, offlineMatches);
         }
         
         // Remove duplicates and respect limit
         final uniqueTitles = <String>{};
         _recipes.retainWhere((recipe) => uniqueTitles.add(recipe.title.toLowerCase()));
         if (_recipes.length > limit) {
             _recipes = _recipes.take(limit).toList();
         }
      }

      if (_recipes.length >= limit) {
         _isLoading = false;
         notifyListeners();
         return;
      }

      // 2. Fallback to AI Generation for remaining recipes
      try {
        int remainingLimit = limit - _recipes.length;
        if (remainingLimit <= 0) remainingLimit = limit;
        
        // Add a prompt hint for Indian recipes if the user is explicitly searching for common Indian keywords
        String contextHint = "";
        final checkStr = baseSearchQuery.toLowerCase();
        if (checkStr.contains('paneer') || checkStr.contains('dal') || checkStr.contains('sabzi') || checkStr.contains('roti') || diet == 'Veg') {
           contextHint = "Please include popular, everyday Indian recipes (like Palak Paneer, Paneer Tikka, Butter Masala, Dal Makhani, etc) if applicable.";
        }
        
        final userInput = '${ingredients.join(', ')}. $query. Diet: $diet. Skill: $skill. $contextHint'.trim();
        final suggestions = await _geminiService.getRecipeSuggestions(userInput, limit: remainingLimit);
        
        final Set<String> usedImages = _recipes.map((r) => r.imageUrl).where((url) => url.isNotEmpty).toSet();

        final recipeFutures = (suggestions as List).map<Future<Recipe>>((data) {
          return _mapGeminiToRecipe(data as Map<String, dynamic>, skill, usedImages, extractedKeyword: ingredients.isNotEmpty ? ingredients.last : query);
        }).toList();
        
        final List<Recipe> fetchedRecipes = await Future.wait(recipeFutures);

        _recipes.addAll(_filterRecipesByDiet(fetchedRecipes, diet));
        
        // Remove duplicates just in case AI generates something MealDB already had
        final uniqueTitles = <String>{};
        _recipes.retainWhere((recipe) => uniqueTitles.add(recipe.title.toLowerCase()));

      } catch (geminiError) {
         if (_recipes.isEmpty) {
            throw Exception('Our Chef AI is currently busy. Please try again in a few seconds!');
         }
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Recipe> _filterRecipesByDiet(List<Recipe> recipes, String diet) {
    if (diet == 'All' || diet == 'Any') return recipes;

    final nonVegKeywords = ['chicken', 'meat', 'beef', 'pork', 'bacon', 'fish', 'prawn', 'shrimp', 'crab', 'salmon', 'tuna', 'duck', 'lamb', 'mutton', 'egg', 'sausage', 'lambc', 'steak'];
    final dairyKeywords = ['milk', 'butter', 'cheese', 'ghee', 'paneer', 'cream', 'yogurt', 'curd', 'honey', 'buttermilk'];

    return recipes.where((recipe) {
      String ingredientsStr = recipe.ingredientsList.join(' ').toLowerCase();
      String titleStr = recipe.title.toLowerCase();
      String fullContext = '$ingredientsStr $titleStr';

      bool hasNonVeg = nonVegKeywords.any((kw) => fullContext.contains(kw));
      bool hasDairy = dairyKeywords.any((kw) => fullContext.contains(kw));

      if (diet == 'Veg') {
        return !hasNonVeg; // Must not have meat/egg
      } else if (diet == 'Non-Veg') {
        return hasNonVeg; // Must have meat/egg
      } else if (diet == 'Vegan') {
        return !hasNonVeg && !hasDairy; // No meat, no dairy
      } else if (diet == 'Keto') {
        final carbKeywords = ['rice', 'bread', 'pasta', 'sugar', 'potato', 'wheat', 'flour', 'noodle', 'corn', 'oat'];
        return !carbKeywords.any((kw) => fullContext.contains(kw));
      }
      return true;
    }).toList();
  }

  // Mapper for internal Gemini full object
  Future<Recipe> _mapGeminiToRecipe(Map<String, dynamic> data, String fallbackDifficulty, Set<String> usedImages, {String? extractedKeyword}) async {
    List<String> ings = [];
    if (data['ingredients'] != null && data['ingredients'] is List) {
      ings = List<String>.from(data['ingredients'].map((x) => x.toString()));
    }
    
    List<String> insts = [];
    if (data['instructions'] != null && data['instructions'] is List) {
      insts = List<String>.from(data['instructions'].map((x) => x.toString()));
    }

    String title = data['title'] ?? 'AI Recipe';
    int defaultTime = data['cookingTime'] ?? 30;

    // Attempt realistic image fetch
    String fetchedImageUrl = '';
    
    // Extract unique meaningful keywords from the AI title to prevent image repetition
    final List<String> titleWords = title.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').split(' ')..removeWhere((w) => w.length < 4);
    List<String> sortedWords = List.from(titleWords)..sort((a, b) => b.length.compareTo(a.length));
    String uniqueKeyword = sortedWords.isNotEmpty ? sortedWords.first : (extractedKeyword ?? 'food');
    String broadTitle = titleWords.length > 1 ? titleWords.sublist(titleWords.length - 2).join(' ') : title;

    // First try exact match from Wikipedia to ensure high-precision dietary accuracy
    final wikiImage = await _mealDbService.fetchWikimediaImage(title);
    if (wikiImage != null && wikiImage.isNotEmpty && !usedImages.contains(wikiImage)) {
      usedImages.add(wikiImage);
      fetchedImageUrl = wikiImage;
    }
    // If no exact match is found, we do NOT fallback to broad keywords.
    // This prevents showing non-vegetarian images (like Mutton Biryani) for vegetarian recipes (like Paneer Biryani).
    // The UI will correctly display 'Image not found' instead.

    return Recipe(
      title: title,
      cookingTime: defaultTime,
      calories: data['calories'] ?? 350,
      proteins: data['proteins'] ?? 20,
      carbs: data['carbs'] ?? 40,
      fats: data['fats'] ?? 15,
      matchedIngredients: ings.length > 2 ? ings.length - 1 : ings.length,
      totalIngredients: ings.isEmpty ? 5 : ings.length,
      imageUrl: fetchedImageUrl,
      instructions: insts.isEmpty ? ['Cook and assemble your ingredients.'] : insts,
      ingredientsList: ings.isEmpty ? ['Various ingredients based on selection'] : ings,
      missingIngredients: [],
      substitutes: {},
      difficulty: fallbackDifficulty == 'Any' ? 'Medium' : fallbackDifficulty,
    );
  }

  // Mapper for MealDB
  Recipe _mapMealDbToRecipe(Map<String, dynamic> meal, String suggestedName, String fallbackDifficulty) {
    List<String> ingredientsList = [];
    
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredientsList.add('${measure ?? ''} $ingredient'.trim());
      }
    }

    final int totalIngredients = ingredientsList.length;
    int matchCount = totalIngredients > 0 ? (totalIngredients ~/ 2) + 1 : 1;

    String diff = fallbackDifficulty;
    if (diff == 'Any') diff = 'Medium';

    return Recipe(
      title: meal['strMeal'] ?? suggestedName,
      cookingTime: 30, // MealDB does not return cooking time
      calories: 400 + (meal['idMeal']?.hashCode ?? 0) % 200, // Semi-randomized realistic estimate
      proteins: 15 + (meal['idMeal']?.hashCode ?? 0) % 20,
      carbs: 30 + (meal['idMeal']?.hashCode ?? 0) % 40,
      fats: 10 + (meal['idMeal']?.hashCode ?? 0) % 20,
      matchedIngredients: matchCount,
      totalIngredients: totalIngredients > 0 ? totalIngredients : 5,
      imageUrl: meal['strMealThumb'] ?? '',
      instructions: (meal['strInstructions'] as String?)?.split(RegExp(r'\r\n|\n')).where((s) => s.trim().isNotEmpty).toList() ?? [],
      ingredientsList: ingredientsList,
      missingIngredients: [],
      substitutes: {},
      difficulty: diff,
    );
  }

  // Mapper for Spoonacular
  Recipe _mapSpoonacularToRecipe(Map<String, dynamic> meal, String suggestedName, String fallbackDifficulty) {
    String diff = fallbackDifficulty;
    if (diff == 'Any') diff = 'Medium';

    return Recipe(
      title: meal['title'] ?? suggestedName,
      cookingTime: meal['readyInMinutes'] ?? 30,
      calories: 400,
      proteins: 20,
      carbs: 45,
      fats: 18,
      matchedIngredients: 2,
      totalIngredients: 5,
      imageUrl: meal['image'] ?? '',
      instructions: ['View full instructions on Spoonacular'],
      ingredientsList: [suggestedName],
      missingIngredients: [],
      substitutes: {},
      difficulty: diff,
    );
  }

}
