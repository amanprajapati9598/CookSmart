import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const String apiKey = 'AIzaSyB7lM81g23qF5PMtBiprR6b2-J6INT85Qw';
  const String textUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

  final prompt = 'User wants recipes based on: . I want egg bhurji. Diet: Any. Skill: Any. Suggest 4 recipes. Return them as an exact JSON array of objects. Each object MUST have: "title" (string, exact proper name of the dish only, no extra words), "ingredients" (list of strings with measurements), "instructions" (list of strings as steps), "cookingTime" (integer in minutes), "calories" (integer), "proteins" (integer in grams), "carbs" (integer in grams), "fats" (integer in grams). Do not include markdown formatting or backticks outside the JSON array.';

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
        final parsed = jsonDecode(cleanText);
        print('Extracted valid array of length \${parsed.length}');
        
        // Let's test the Recipe mapper logic too
        for(var recipe in parsed) {
          int defaultTime = parseInt(recipe['cookingTime'], 30);
          print('Title: \${recipe["title"]}, Time: $defaultTime');
        }
      } else {
        print('Exception: No JSON array found. Text: $cleanText');
      }
    } else {
      print('HTTP Error: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

int parseInt(dynamic value, int fallback) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? fallback;
  }
  return fallback;
}
