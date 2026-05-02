import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const String apiKey = 'AIzaSyB7lM81g23qF5PMtBiprR6b2-J6INT85Qw';
  const String textUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

  final prompt = "You are CookSmart AI Chef. The user said: 'hi'.\\nIf the user is explicitly asking for food, recipes, meal ideas, or ingredients (e.g. 'breakfast', 'lunch', 'chicken', 'I am hungry', 'paneer'), reply with EXACTLY the word 'RECIPE'.\\nIf the user is just greeting or chatting (e.g. 'hi', 'how are you', 'who are you', 'thanks'), reply with a friendly conversational response as a Chef.";

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
      print('Intent response: $text');
    }
  } catch (e) {
    print('Error: $e');
  }
}
