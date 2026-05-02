import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const String apiKey = 'AIzaSyB7lM81g23qF5PMtBiprR6b2-J6INT85Qw';
  const String textUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

  final prompt = 'User wants recipes based on: . I want egg bhurji recipe. Diet: Any. Skill: Any. . Suggest 4 recipes. Return them as an exact JSON array of objects. Each object MUST have: "title" (string), "ingredients" (list of strings with measurements), "instructions" (list of strings as steps), "cookingTime" (integer in minutes), "calories" (integer), "proteins" (integer in grams), "carbs" (integer in grams), "fats" (integer in grams). Do not include markdown formatting or backticks outside the JSON array.';

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
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      print('Raw text:\\n$text');
      
      String cleanText = text.trim();
      
      int startIndex = cleanText.indexOf('[');
      int endIndex = cleanText.lastIndexOf(']');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleanText = cleanText.substring(startIndex, endIndex + 1);
        print('Extracted valid array');
      } else {
        print('Exception: No JSON array found. Text: $cleanText');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
