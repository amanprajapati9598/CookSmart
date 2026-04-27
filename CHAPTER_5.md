# CHAPTER 5: IMPLEMENTATION AND TESTING (FINAL VERSION)

## 5.1 Implementation Approaches

### 5.1.1 Agile Methodology
The development of the CookSmart application follows the Agile methodology, which is an iterative and incremental approach to software development. Agile emphasizes flexibility, continuous feedback, user involvement, and early delivery of working software.

This methodology is well-suited for the CookSmart project as it involves multiple components such as Flutter-based frontend, PHP/MySQL backend, and AI integration, which require continuous refinement and testing.

**Implementation of Agile in CookSmart**
- **Iterative Development:** The application was developed in small cycles (iterations), where each phase delivered a functional module of the system. 
- **Feature Prioritization:** Core functionalities such as user authentication and recipe database were developed first, followed by advanced features like AI-based recipe recommendations and pantry tracking. 
- **Continuous Feedback:** Informal review sessions were conducted regularly to evaluate progress, identify issues, and plan further improvements. 
- **Incremental Delivery:** Each iteration produced a working version of the application, enabling early testing and validation. 

**Adaptation of Agile Approach**
Due to project constraints, a lightweight version of Agile was implemented instead of formal Agile ceremonies (such as sprint planning meetings or stand-ups).
- Regular discussions replaced formal meetings 
- Tasks were managed in a flexible manner 
- Focus remained on development and testing rather than documentation-heavy processes 

**Advantages of Agile in CookSmart**
- Improved flexibility in handling requirement changes 
- Faster development through incremental progress 
- Early detection and fixing of errors 
- Better integration of frontend and backend modules 
- Continuous improvement based on feedback

---

## 5.2 Coding Details and Code Efficiency

### 5.2.1 Coding Details
The CookSmart system is implemented using a combination of Flutter (frontend) and PHP/MySQL (backend). Key modules include:

**1. Database Configuration (Backend)**
- **File:** `backend/config/db.php`
- **Purpose:** Establishes connection with MySQL database
- **Feature:** Error handling ensures stable backend communication

```php
<?php

try {
    $conn = new mysqli("localhost", "root", "", "receipe_db");
    
    if($conn->connect_error){
        echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $conn->connect_error]);
        exit();
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $e->getMessage()]);
    exit();
}

?>
```

**2. Dashboard View (Frontend)**
- **File:** `frontend/food_app_flutter/screens/home_screen.dart`
- **Purpose:** Displays user dashboard with search and UI elements
- **Feature:** Uses Provider and animations

```dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/language_provider.dart';
import '../widgets/recipe_card.dart';
import 'search_screen.dart';
import 'recipe_results_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/history_manager.dart';
import '../utils/avatar_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Ingredient> _ingredients = [];
  final List<Ingredient> _selectedIngredients = [];
  
  final TextEditingController _inputCtrl = TextEditingController();
  final TextEditingController _naturalQueryCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String _selectedDiet = 'All';
  String _selectedSkill = 'Medium';

  final List<String> _diets = ['All', 'Veg', 'Non-Veg', 'Vegan', 'Keto'];
  final List<String> _skills = ['Beginner', 'Medium', 'Masterchef'];

  String _userName = 'Chef';
  String _avatarType = 'none';
  String _customAvatarPath = '';
  int _selectedLimit = 5;
  List<Recipe> _popularRecipes = [];
  bool _isLoadingPopular = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn)
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic)
    );
    
    _loadUser();
    _fetchIngredients();
    _fetchPopularToday('Any');
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _inputCtrl.dispose();
    _naturalQueryCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchPopularToday(String diet) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        setState(() => _isLoadingPopular = true);
        final provider = Provider.of<RecipeProvider>(context, listen: false);
        await provider.discoverMatches(
          query: '', 
          ingredients: [],
          diet: diet,
          skill: 'Medium',
          requestedLimit: 5,
        );
        if (mounted) {
          setState(() {
            _popularRecipes = List.from(provider.recipes);
            _isLoadingPopular = false;
          });
        }
      }
    });
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user') ?? 'Chef';
      _avatarType = prefs.getString('user_avatar') ?? 'none';
      _customAvatarPath = prefs.getString('user_avatar_custom') ?? '';
    });
  }

  Future<void> _fetchIngredients() async {
    final data = await ApiService.getIngredients();
    if (mounted) {
      setState(() => _ingredients = data);
    }
  }

  void _handleAddIngredient() {
    final val = _inputCtrl.text.trim();
    if (val.isEmpty) return;

    final found = _ingredients.where((i) => i.name.toLowerCase() == val.toLowerCase()).toList();
    final chipToAdd = found.isNotEmpty ? found.first : Ingredient(id: DateTime.now().millisecondsSinceEpoch, name: val);

    if (!_selectedIngredients.any((s) => s.name.toLowerCase() == chipToAdd.name.toLowerCase())) {
      setState(() {
        _selectedIngredients.add(chipToAdd);
        _inputCtrl.clear();
      });
      _focusNode.requestFocus();
    }
  }

  void _removeIngredient(Ingredient chip) {
    setState(() {
      _selectedIngredients.removeWhere((s) => s.id == chip.id || s.name == chip.name);
    });
    _focusNode.requestFocus();
  }

  void _performSearch() {
    if (_selectedIngredients.isEmpty && _naturalQueryCtrl.text.isEmpty) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.t('add_ingredients_smart'))));
      return;
    }
    HistoryManager.saveHistory(
      _naturalQueryCtrl.text.trim(),
      _selectedIngredients.map((e) => e.name).toList(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeResultsScreen(
          query: _naturalQueryCtrl.text.trim(),
          ingredients: _selectedIngredients.map((e) => e.name).toList(),
          diet: _selectedDiet == 'All' ? 'Any' : _selectedDiet,
          skill: _selectedSkill,
          limit: _selectedLimit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    String getDietKey(String diet) {
      switch (diet) {
        case 'All': return 'diet_all';
        case 'Veg': return 'diet_veg';
        case 'Non-Veg': return 'diet_nonveg';
        case 'Vegan': return 'diet_vegan';
        case 'Keto': return 'diet_keto';
        default: return diet;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFF9A8B).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 1.0), Theme.of(context).scaffoldBackgroundColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    AvatarUtils.buildAvatar(
                                      type: _avatarType,
                                      customPath: _customAvatarPath,
                                      radius: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${lang.t('hello_user')}, $_userName', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                                        const SizedBox(height: 2),
                                        Text(lang.t('lets_find_delicious'), style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
                              ),
                              child: TextField(
                                controller: _naturalQueryCtrl,
                                readOnly: true,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                                },
                                decoration: InputDecoration(
                                  hintText: lang.t('find_dishes_smart'),
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Icon(Icons.search, color: Colors.grey.shade600, size: 24),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.mic, color: Colors.grey.shade600, size: 24),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                                    },
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: _diets.map((diet) {
                                  bool isSelected = _selectedDiet == diet;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedDiet = diet);
                                      _fetchPopularToday(_selectedDiet == 'All' ? 'Any' : _selectedDiet);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFFF6D3B) : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: isSelected 
                                          ? [BoxShadow(color: const Color(0xFFFF6D3B).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
                                          : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
                                      ),
                                      child: Text(
                                        lang.t(getDietKey(diet)),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black87,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 32),

                            Text(lang.t('whats_in_fridge'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyMedium?.color)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _inputCtrl,
                                          focusNode: _focusNode,
                                          style: const TextStyle(color: Colors.black87),
                                          decoration: InputDecoration(
                                            hintText: lang.t('eg_tomato_chicken'),
                                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          ),
                                          onSubmitted: (_) => _handleAddIngredient(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _handleAddIngredient,
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)),
                                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_selectedIngredients.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _selectedIngredients.map((chip) => Chip(
                                        label: Text(chip.name, style: const TextStyle(color: Colors.black87)),
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                                        deleteIconColor: Colors.redAccent,
                                        onDeleted: () => _removeIngredient(chip),
                                      )).toList(),
                                    )
                                  ]
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                 Row(
                                   children: [
                                     Icon(Icons.format_list_numbered, color: Colors.grey.shade700, size: 20),
                                     const SizedBox(width: 8),
                                     Text(lang.t('results_count'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                   ],
                                 ),
                                 DropdownButton<int>(
                                   value: _selectedLimit,
                                   items: [5, 10, 15, 30].map((int val) {
                                      return DropdownMenuItem<int>(
                                         value: val,
                                         child: Text(
                                            '$val ${lang.t('recipes_count')}',
                                            style: TextStyle(
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
                                              fontWeight: val == 30 ? FontWeight.bold : FontWeight.normal
                                            )
                                         ),
                                      );
                                   }).toList(),
                                   onChanged: (val) {
                                      if (val != null) {
                                         setState(() => _selectedLimit = val);
                                      }
                                   },
                                   underline: const SizedBox(),
                                   icon: const Icon(Icons.arrow_drop_down),
                                 )
                              ],
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _performSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6D3B),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 4,
                                  shadowColor: const Color(0xFFFF6D3B).withOpacity(0.4),
                                ),
                                child: Text(lang.t('search_recipes'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                            
                            if (_isLoadingPopular) ...[
                              const SizedBox(height: 36),
                              const Center(child: CircularProgressIndicator(color: Colors.orange)),
                            ] else if (_popularRecipes.isNotEmpty) ...[
                              const SizedBox(height: 36),
                              Text(lang.t('popular_today'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                              const SizedBox(height: 16),
                              ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: _popularRecipes.length,
                                itemBuilder: (context, index) {
                                  return _buildStaggeredRecipe(index, _popularRecipes[index]);
                                },
                              ),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredRecipe(int index, Recipe recipe) {
    double delay = (index * 0.1).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeIn),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
          ),
        ),
        child: Container(
          height: 260,
          margin: const EdgeInsets.only(bottom: 16),
          child: RecipeCard(recipe: recipe),
        ),
      ),
    );
  }
}
```

**3. Search API Module (Backend)**
- **File:** `backend/api/search.php`
- **Purpose:** Fetch recipes based on ingredients
- **Feature:** Efficient SQL queries and filtering

```php
<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

include("../config/db.php");

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$input = json_decode(file_get_contents('php://input'), true);
$user_ingredients = isset($input['ingredients']) ? $input['ingredients'] : [];

if (empty($user_ingredients)) {
    echo json_encode(['error' => 'No ingredients provided']);
    exit();
}

// Sanitize user ingredients to integers
$user_ingredients = array_map('intval', $user_ingredients);
$in_clause = implode(',', $user_ingredients);

$sql = "
SELECT 
    r.Recipe_ID, r.Title, r.Instructions, r.Cooking_Time, r.Calories, r.Difficulty_Level, r.Is_Veg, r.Image_URL,
    (SELECT COUNT(*) FROM Recipe_Ingredients ri WHERE ri.Recipe_ID = r.Recipe_ID) AS Total_Ingredients,
    (SELECT COUNT(*) FROM Recipe_Ingredients ri WHERE ri.Recipe_ID = r.Recipe_ID AND ri.Ingredient_ID IN ($in_clause)) AS Matched_Ingredients
FROM Recipes r
HAVING Matched_Ingredients > 0
ORDER BY Matched_Ingredients DESC, Total_Ingredients ASC
";

$result = $conn->query($sql);
$recipes = [];

while($row = $result->fetch_assoc()){
    if ($row['Matched_Ingredients'] == 0) continue; // safety check
    
    // Find missing ingredients
    $recipe_id = intval($row['Recipe_ID']);
    $missing_sql = "
        SELECT i.Name, i.Substitutes 
        FROM Recipe_Ingredients ri 
        JOIN Ingredients i ON ri.Ingredient_ID = i.Ingredient_ID
        WHERE ri.Recipe_ID = $recipe_id 
        AND i.Ingredient_ID NOT IN ($in_clause)
    ";
    
    $missing_result = $conn->query($missing_sql);
    $missing_ingredients = [];
    while($m_row = $missing_result->fetch_assoc()) {
        $missing_ingredients[] = $m_row;
    }
    
    $row['Missing_Ingredients'] = $missing_ingredients;
    
    // If we only have missing 1-2 ingredients or enough matched
    $recipes[] = $row;
}

echo json_encode(['success' => true, 'data' => $recipes]);
?>
```

**4. AI Recommendation Module**
- **File:** `frontend/food_app_flutter/services/api_service.dart`
- **Purpose:** Generate AI-based recipes
- **Feature:** Uses external AI API with async calls

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/ingredient.dart';
import '../models/recipe.dart';

class ApiService {
  static String get _baseUrl {
    String suffix = "/food-recipe-app/backend/api";
    if (kIsWeb) {
      return "http://localhost$suffix";
    }
    try {
      if (Platform.isAndroid) return "http://10.0.2.2$suffix";
    } catch (_) {
      // Ignored
    }
    return "http://localhost$suffix";
  }

  static String get baseUrl => _baseUrl;

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'HTTP Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<Ingredient>> getIngredients() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/getIngredients.php"));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Ingredient.fromJson(e)).toList();
      }
    } catch (e) {
      // Ignored for production
    }
    return [];
  }

  // Fetch AI Recommendations with new smart filters
  static Future<List<Recipe>> fetchAIRecommendations({
    required List<Ingredient> selectedIngredients,
    String query = "",
    String diet = "Any",
    String skillLevel = "Medium",
  }) async {
    if (selectedIngredients.isEmpty && query.isEmpty) return [];

    final ingredientNames = selectedIngredients.map((i) => i.name).join(", ");
    final filterText = "Filters - Diet: $diet, Skill Level: $skillLevel.";
    final naturalQuery = query.isNotEmpty ? "User Search Priority: '$query'." : "";

    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer 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",
          "HTTP-Referer": "http://10.0.2.2",
          "X-Title": "CookSmart_Flutter_Pro",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "model": "meta-llama/llama-3.3-70b-instruct:free",
          "messages": [
            {
              "role": "user",
              "content": '''You are a masterchef assistant. The user has these ingredients: $ingredientNames. 
              $filterText
              $naturalQuery
              Return ONLY a valid JSON array of 2-3 recipe objects (no markdown blocks or intro, just raw JSON). 
              Each object MUST have EXACTLY these keys: 
              "Title" (string), 
              "Cooking_Time" (number in minutes), 
              "Calories" (number), 
              "Proteins" (number in grams),
              "Carbs" (number in grams),
              "Fats" (number in grams),
              "Matched_Ingredients" (how many they have), 
              "Total_Ingredients" (total needed, match should be realistic),
              "Missing_Ingredients" (array of strings, up to 3 ingredients they DON'T have),
              "Substitutes" (JSON object mapping a missing ingredient to a valid substitute, e.g. {"Butter": "Oil", "Lemon": "Vinegar"}),
              "Difficulty" (string, "Beginner", "Medium", or "Masterchef"),
              "Image_URL" (IMPORTANT: Use a UNIQUE Unsplash food URL for EVERY recipe. DO NOT repeat images. If you cannot find a specific unique URL, use a general high-quality food image link but ensure it is different from the others. Example: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=800"),
              "Instructions" (array of strings, step-by-step cooking guide),
              "Ingredients_List" (array of strings, full list of ingredients with quantities).'''
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'][0]['message'] != null) {
          String content = data['choices'][0]['message']['content'];
          try {
            final regex = RegExp(r'\[[\s\S]*\]');
            final match = regex.firstMatch(content);
            List<dynamic> jsonList;
            if (match != null) {
                jsonList = jsonDecode(match.group(0)!);
            } else {
                jsonList = jsonDecode(content);
            }
            return jsonList.map((e) => Recipe.fromJson(e)).toList();
          } catch(e) {
            return [];
          }
        }
      } else if (response.statusCode == 429) {
        throw Exception("You've hit the AI Rate Limit. Please wait a minute and try again.");
      } else {
        throw Exception("AI Server Error: ${response.statusCode}");
      }
    } catch (e) {
      // Throw error to be caught by UI
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
    return [];
  }
}
```

### 5.2.2 Coding Efficiency

To evaluate the overall coding efficiency, maintainability, and structure of the CookSmart application, we analyzed the source code metrics. The following table provides a comprehensive breakdown of the project's codebase:

| Language | Files | Lines | Blanks | Comments | Code Complexity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Dart | 43 | 9,411 | 658 | 98 | 434 |
| Markdown | 10 | 1,683 | 303 | 124 | 64 |
| SQL | 4 | 365 | 52 | 7 | 16 |
| PHP | 7 | 220 | 46 | 4 | 10 |
| YAML | 2 | 138 | 17 | 79 | 2 |
| JSON | 2 | 9 | 0 | 0 | 0 |
| **Total** | **68** | **11,826** | **1,076** | **312** | **526** |

#### Performance Optimization Techniques
The following table summarizes performance optimization techniques:

| Category | Technique | Benefits |
| :--- | :--- | :--- |
| **Frontend** | Provider State Management | Smooth UI updates |
| | Async Programming | Non-blocking operations |
| | Reusable Widgets | Clean and maintainable code |
| **Backend** | REST APIs | Fast communication |
| | Security (PDO, Hashing) | Data protection |
| | Optimized Queries | Faster response |
| **Efficiency** | Lazy Loading | Better performance |
| | Indexing | Faster search |
| | Caching | Offline support |

---

## 5.3 Testing Approach
Testing is performed at multiple levels to ensure reliability and performance.

### 5.3.1 Unit Testing

#### 1. Authentication Component (Backend & Frontend)
| Test Case ID | Description | Inputs | Expected Result | Actual Result |
| :--- | :--- | :--- | :--- | :--- |
| UNIT-AUTH-01 | Validate registration with valid data | Name: "John Doe", Email: "john@cooksmart.com", Password: "SecurePassword123" | Validation passes, user account is created in MySQL. | PASS |
| UNIT-AUTH-02 | Validate registration with short password | Password: "123" | Validation fails: "Password must be at least 8 characters". | PASS |
| UNIT-AUTH-03 | Validate login with unregistered email | Email: "unknown@test.com", Password: "Password123" | Validation fails: "User not found". | PASS |

#### 2. Recipe Search Logic (Backend)
| Test Case ID | Description | Inputs | Expected Result | Actual Result |
| :--- | :--- | :--- | :--- | :--- |
| UNIT-RECIPE-01| Fetch recipes with valid ingredients | Ingredients: [1, 5, 8] (Tomato, Onion, Chicken) | Returns JSON array of recipes matching ingredients. | PASS |
| UNIT-RECIPE-02| Fetch recipes with empty array | Ingredients: [] | Validation fails: "No ingredients provided". | PASS |

### 5.3.2 Integration Testing

#### 1. Frontend-Backend API Integration
| Test Case ID | Description | Inputs | Expected Result | Actual Result |
| :--- | :--- | :--- | :--- | :--- |
| INT-API-01 | Login API Request from Flutter to PHP | Valid Email & Password submitted via Login Screen | HTTP 200 OK, returns User Data & Auth Token. | PASS |
| INT-API-02 | Fetch Ingredients API | App requests `getIngredients.php` on load | HTTP 200 OK, returns list of available ingredients. | PASS |

#### 2. AI Recommendation Engine Integration
| Test Case ID | Description | Inputs | Expected Result | Actual Result |
| :--- | :--- | :--- | :--- | :--- |
| INT-AI-01 | Request AI Recipe Recommendation | Selected Ingredients: "Tomato, Chicken", Diet: "Keto" | OpenRouter AI returns a valid JSON array of 2-3 Keto-friendly recipes. | PASS |
| INT-AI-02 | AI Rate Limit Handling | Sending requests exceeding API limit | App gracefully catches error: "You've hit the AI Rate Limit". | PASS |

### 5.3.3 System Testing

#### 1. End-to-End User Workflows
| Test Case ID | Description | Inputs | Expected Result | Actual Result |
| :--- | :--- | :--- | :--- | :--- |
| SYS-E2E-01 | Complete Recipe Discovery Flow | User logs in, adds ingredients, clicks Search, views details | App navigates smoothly through Dashboard -> Search -> Recipe Details without crashing. | PASS |
| SYS-E2E-02 | Profile Updates and Avatar Selection | User navigates to Profile, changes Avatar and Name | Settings are saved locally via SharedPreferences and updated across UI instantly. | PASS |

#### 2. Performance and UI Compatibility
| Test Case ID | Description | Inputs | Expected Result | Actual Result |
| :--- | :--- | :--- | :--- | :--- |
| SYS-PERF-01 | Image Loading Performance | Scrolling through 20+ Recipe Cards in Search Results | Images load asynchronously with smooth fade-in animations, no stuttering. | PASS |
| SYS-COMP-01 | Cross-Platform Responsiveness | App loaded on Android Device and Web Browser | UI scales correctly; navigation drawer works smoothly on both platforms. | PASS |
