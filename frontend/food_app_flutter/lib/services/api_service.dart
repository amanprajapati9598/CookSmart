import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/ingredient.dart';
import '../models/recipe.dart';

class ApiService {
  static String get _baseUrl {
    String suffix = "/food-recipe-app/backend/api";
    if (kIsWeb) {
      return "http://localhost$suffix";
    }
    try {
      if (Platform.isAndroid) return "http://10.0.2.2$suffix";
    } catch (_) {
      // Ignored
    }
    return "http://localhost$suffix";
  }

  static String get baseUrl => _baseUrl;

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<Ingredient>> getIngredients() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/getIngredients.php"));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Ingredient.fromJson(e)).toList();
      }
    } catch (e) {
      // Ignored for production
    }
    return [];
  }

  // Fetch AI Recommendations with new smart filters
  static Future<List<Recipe>> fetchAIRecommendations({
    required List<Ingredient> selectedIngredients,
    String query = "",
    String diet = "Any",
    String skillLevel = "Medium",
  }) async {
    if (selectedIngredients.isEmpty && query.isEmpty) return [];

    final ingredientNames = selectedIngredients.map((i) => i.name).join(", ");
    final filterText = "Filters - Diet: $diet, Skill Level: $skillLevel.";
    final naturalQuery = query.isNotEmpty ? "User Search Priority: '$query'." : "";

    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer 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",
          "HTTP-Referer": "http://10.0.2.2",
          "X-Title": "CookSmart_Flutter_Pro",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "model": "meta-llama/llama-3.3-70b-instruct:free",
          "messages": [
            {
              "role": "user",
              "content": '''You are a masterchef assistant. The user has these ingredients: $ingredientNames. 
              $filterText
              $naturalQuery
              Return ONLY a valid JSON array of 2-3 recipe objects (no markdown blocks or intro, just raw JSON). 
              Each object MUST have EXACTLY these keys: 
              "Title" (string), 
              "Cooking_Time" (number in minutes), 
              "Calories" (number), 
              "Proteins" (number in grams),
              "Carbs" (number in grams),
              "Fats" (number in grams),
              "Matched_Ingredients" (how many they have), 
              "Total_Ingredients" (total needed, match should be realistic),
              "Missing_Ingredients" (array of strings, up to 3 ingredients they DON'T have),
              "Substitutes" (JSON object mapping a missing ingredient to a valid substitute, e.g. {"Butter": "Oil", "Lemon": "Vinegar"}),
              "Difficulty" (string, "Beginner", "Medium", or "Masterchef"),
              "Image_URL" (IMPORTANT: Use a UNIQUE Unsplash food URL for EVERY recipe. DO NOT repeat images. If you cannot find a specific unique URL, use a general high-quality food image link but ensure it is different from the others. Example: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=800"),
              "Instructions" (array of strings, step-by-step cooking guide),
              "Ingredients_List" (array of strings, full list of ingredients with quantities).'''
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'][0]['message'] != null) {
          String content = data['choices'][0]['message']['content'];
          try {
            final regex = RegExp(r'\[[\s\S]*\]');
            final match = regex.firstMatch(content);
            List<dynamic> jsonList;
            if (match != null) {
                jsonList = jsonDecode(match.group(0)!);
            } else {
                jsonList = jsonDecode(content);
            }
            return jsonList.map((e) => Recipe.fromJson(e)).toList();
          } catch(e) {
            return [];
          }
        }
      } else if (response.statusCode == 429) {
        throw Exception("You've hit the AI Rate Limit. Please wait a minute and try again.");
      } else {
        throw Exception("AI Server Error: ${response.statusCode}");
      }
    } catch (e) {
      // Throw error to be caught by UI
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
    return [];
  }
}
