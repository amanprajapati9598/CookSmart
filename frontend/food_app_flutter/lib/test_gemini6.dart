import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const String apiKey = 'AIzaSyB7lM81g23qF5PMtBiprR6b2-J6INT85Qw';
  const String url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      for (var model in data['models']) {
        print('\${model["name"]} - \${model["version"]}');
      }
    } else {
      print('HTTP Error: \${response.statusCode} \${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
