import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const String apiKey = 'AIzaSyCCRWAwg0a3sdnjfr7N1m2qKnT13KGWBT8';
  const String textUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey';

  final prompt = 'User wants recipes based on: . paneer. Diet: Any. Skill: Medium. Please include popular, everyday Indian recipes (like Palak Paneer, Paneer Tikka, Butter Masala, Dal Makhani, etc) if applicable.. Suggest 14 recipes. Return them as an exact JSON array of objects. Each object MUST have: "title" (string), "ingredients" (list of strings with measurements), "instructions" (list of strings as steps), "cookingTime" (integer in minutes). Do not include markdown formatting or backticks outside the JSON array.';

  try {
    final response = await http.post(
      Uri.parse(textUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [{"parts": [{"text": prompt}]}]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      print("SUCCESS");
      print(text.substring(0, 500));
      
      String cleanText = text.trim();
      if (cleanText.startsWith('```json')) cleanText = cleanText.replaceFirst('```json', '');
      if (cleanText.startsWith('```')) cleanText = cleanText.replaceFirst('```', '');
      if (cleanText.endsWith('```')) cleanText = cleanText.substring(0, cleanText.length - 3);

      cleanText = cleanText.trim();
      
      final parsedJson = jsonDecode(cleanText);
      if (parsedJson is! List) throw Exception("Not list");
      print("Parsed properly!");
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
