import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final titles = [
    "Palak Paneer",
    "Paneer Butter Masala",
    "Kadai Paneer",
    "Paneer Tikka",
    "Chilli Paneer",
    "Mutter Paneer"
  ];
  
  for (var title in titles) {
    try {
      final url = Uri.parse('https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch=${Uri.encodeComponent(title)}&gsrlimit=1&prop=pageimages&format=json&pithumbsize=800');
      final response = await http.get(url, headers: {'User-Agent': 'FoodRecipeApp/1.0'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['query'] != null && data['query']['pages'] != null) {
          final pages = data['query']['pages'] as Map<String, dynamic>;
          if (pages.isNotEmpty) {
            final firstPage = pages.values.first;
            if (firstPage['thumbnail'] != null) {
               print("$title: ${firstPage['thumbnail']['source']}");
               continue;
            }
          }
        }
      }
    } catch(e) {}
    print("$title: FAILED");
  }
}
