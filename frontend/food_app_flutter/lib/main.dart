import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'providers/recipe_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey('install_date')) {
    final now = DateTime.now();
    await prefs.setString('install_date', "${now.day}/${now.month}/${now.year}");
  }
  final isLoggedIn = prefs.containsKey('user');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: CookSmartApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class CookSmartApp extends StatelessWidget {
  final bool isLoggedIn;

  const CookSmartApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'CookSmart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: isLoggedIn ? const MainLayout() : const LoginScreen(),
        );
      }
    );
  }
}
