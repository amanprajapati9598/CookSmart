import 'dart:convert';
import 'package:http/http.dart' as http;

class SpoonacularService {
  static const String apiKey = 'YOUR_SPOONACULAR_API_KEY';
  static const String baseUrl = 'https://api.spoonacular.com/recipes/complexSearch';

  Future<Map<String, dynamic>?> fallbackSearch(String query) async {
    try {
      final url = Uri.parse('$baseUrl?apiKey=$apiKey&query=$query&number=1&addRecipeInformation=true');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          return data['results'][0];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
