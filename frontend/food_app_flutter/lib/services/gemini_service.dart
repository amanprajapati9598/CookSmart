import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String apiKey = 'AIzaSyCCRWAwg0a3sdnjfr7N1m2qKnT13KGWBT8';
  // Use universally available modern future-proof models
  static const String textUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey';
  static const String visionUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey';

  Future<List<Map<String, dynamic>>> getRecipeSuggestions(String userInput, {int limit = 5}) async {
    final prompt = 'User wants recipes based on: $userInput. Suggest $limit recipes. Return them as an exact JSON array of objects. Each object MUST have: "title" (string), "ingredients" (list of strings with measurements), "instructions" (list of strings as steps), "cookingTime" (integer in minutes), "calories" (integer), "proteins" (integer in grams), "carbs" (integer in grams), "fats" (integer in grams). Do not include markdown formatting or backticks outside the JSON array.';

    try {
      final response = await http.post(
        Uri.parse(textUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] == null || data['candidates'].isEmpty) {
           throw Exception('No response candidates found from Gemini.');
        }

        final text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Clean markdown JSON if Gemini adds it despite instructions
        String cleanText = text.trim();
        if (cleanText.startsWith('```json')) cleanText = cleanText.replaceFirst('```json', '');
        if (cleanText.startsWith('```')) cleanText = cleanText.replaceFirst('```', '');
        if (cleanText.endsWith('```')) cleanText = cleanText.substring(0, cleanText.length - 3);

        cleanText = cleanText.trim();
        
        final parsedJson = jsonDecode(cleanText);
        if (parsedJson is List) {
          return List<Map<String, dynamic>>.from(parsedJson);
        } else {
           throw Exception('Unexpected JSON format from API: $cleanText');
        }
      } else {
        throw Exception('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to communicate with AI model: $e');
    }
  }

  Future<String> analyzeImageForIngredients(List<int> imageBytes, String mimeType) async {
    final prompt = 'Identify the food ingredients in this image. Return them as a simple comma-separated string, like "tomato, egg, onion". Do not include extra text or markdown.';
    
    try {
      final response = await http.post(
        Uri.parse(visionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inlineData": {
                    "mimeType": mimeType,
                    "data": base64Encode(imageBytes)
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] == null || data['candidates'].isEmpty) {
           throw Exception('No response candidates found from Gemini vision.');
        }

        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return text.trim();
      } else {
        throw Exception('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to communicate with AI vision model: $e');
    }
  }
}
