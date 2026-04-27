import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryManager {
  static const String _key = 'search_history';

  static Future<void> saveHistory(String query, List<String> ingredients) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> rawHistory = prefs.getStringList(_key) ?? [];
    
    // Check if duplicate and remove old one
    rawHistory.removeWhere((item) {
      final map = jsonDecode(item);
      return map['query'] == query;
    });

    final newEntry = {
      'query': query,
      'ingredients': ingredients,
      'timestamp': DateTime.now().toIso8601String(),
    };

    rawHistory.insert(0, jsonEncode(newEntry));

    // Limit to 50 recent searches
    if (rawHistory.length > 50) {
      rawHistory = rawHistory.sublist(0, 50);
    }

    await prefs.setStringList(_key, rawHistory);
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> rawHistory = prefs.getStringList(_key) ?? [];
    
    return rawHistory.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
