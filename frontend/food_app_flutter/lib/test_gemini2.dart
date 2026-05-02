import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const String apiKey = 'AIzaSyB7lM81g23qF5PMtBiprR6b2-J6INT85Qw';
  const String textUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

  final prompt = 'User wants recipes based on: Lunch. Suggest 4 recipes. Return them as an exact JSON array of objects. Each object MUST have: "title" (string), "ingredients" (list of strings with measurements), "instructions" (list of strings as steps), "cookingTime" (integer in minutes), "calories" (integer), "proteins" (integer in grams), "carbs" (integer in grams), "fats" (integer in grams). Do not include markdown formatting or backticks outside the JSON array.';

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
      if (cleanText.startsWith('```json')) cleanText = cleanText.replaceFirst('```json', '');
      if (cleanText.startsWith('```')) cleanText = cleanText.replaceFirst('```', '');
      if (cleanText.endsWith('```')) cleanText = cleanText.substring(0, cleanText.length - 3);

      cleanText = cleanText.trim();
      
      try {
        final parsedJson = jsonDecode(cleanText);
        print('Parsed successfully: \${parsedJson.length} recipes');
      } catch (e) {
        print('JSON Decode Error: $e');
        print('Clean Text:\\n$cleanText');
      }
    } else {
      print('HTTP Error: \${response.statusCode} - \${response.body}');
    }
  } catch (e) {
    print('Network Error: $e');
  }
}
