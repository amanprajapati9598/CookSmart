import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_translations.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'English';

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguagePreference();
  }

  void _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'English';
    notifyListeners();
  }

  void changeLanguage(String newLanguage) async {
    if (_currentLanguage != newLanguage) {
      _currentLanguage = newLanguage;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', newLanguage);
      notifyListeners();
    }
  }

  String t(String key) {
    return AppTranslations.translations[_currentLanguage]?[key] ?? key;
  }
}
