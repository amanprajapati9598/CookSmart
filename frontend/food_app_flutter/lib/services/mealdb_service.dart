import 'dart:convert';
import 'package:http/http.dart' as http;

class MealDBService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1/search.php';

  Future<Map<String, dynamic>?> searchRecipe(String dishName) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?s=$dishName'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
          return data['meals'][0]; // Return the first match
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<List<Map<String, dynamic>>> searchRecipesList(String keyword, {int limit = 5}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?s=$keyword'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
           final List meals = data['meals'];
           meals.shuffle(); // Randomize to not always get the same fallback
           return meals.take(limit).map((e) => e as Map<String, dynamic>).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchByCategory(String category, {int limit = 5}) async {
    try {
      final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?c=$category'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
           final List meals = data['meals'];
           meals.shuffle();
           
           // Fetch full details for the limited meals since filter.php only returns id and thumb
           List<Map<String, dynamic>> fullMeals = [];
           final futures = meals.take(limit).map((m) async {
             try {
               final detailResponse = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/lookup.php?i=${m['idMeal']}'));
               if (detailResponse.statusCode == 200) {
                 final detailData = jsonDecode(detailResponse.body);
                 if (detailData['meals'] != null) return detailData['meals'][0] as Map<String, dynamic>?;
               }
             } catch (_) {}
             return null;
           });
           
           final results = await Future.wait(futures);
           for (var res in results) {
             if (res != null) fullMeals.add(res);
           }
           return fullMeals;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<String?> fetchImageByKeyword(String keyword) async {
    try {
      // First try broad search by meal name
      final responseName = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=$keyword'));
      if (responseName.statusCode == 200) {
        final data = jsonDecode(responseName.body);
        if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
           final List meals = data['meals'];
           meals.shuffle();
           return meals[0]['strMealThumb'] as String?;
        }
      }

      // Clean keyword (take first word if it's too complex)
      String cleanKeyword = keyword.split(' ').first;
      final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/filter.php?i=$cleanKeyword'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
           final List meals = data['meals'];
           meals.shuffle();
           return meals[0]['strMealThumb'] as String?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> fetchWikimediaImage(String query) async {
    try {
      // Free Wikipedia image search for ANY dish globally
      final url = Uri.parse('https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch=${Uri.encodeComponent(query)}&gsrlimit=1&prop=pageimages&format=json&pithumbsize=800&origin=*');
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FoodRecipeApp/1.0 (contact@example.com)'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['query'] != null && data['query']['pages'] != null) {
          final pages = data['query']['pages'] as Map<String, dynamic>;
          if (pages.isNotEmpty) {
            final firstPage = pages.values.first;
            if (firstPage['thumbnail'] != null) {
              return firstPage['thumbnail']['source'] as String;
            }
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
