import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/recipe.dart';
import 'recipe_details_screen.dart';
import 'settings_screen.dart';
import 'grocery_list_screen.dart';
import 'pantry_tracker_screen.dart';
import 'meal_planner_screen.dart';
import 'nutrition_dashboard.dart';
import '../utils/avatar_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  String _userName = "User";
  String _avatarType = 'none';
  String _customAvatarPath = '';

  List<dynamic> _savedRecipes = [];
  List<dynamic> _recentRecipes = [];
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check and clear recent recipes if the day has changed
    final today = DateTime.now().toString().split(' ')[0];
    final lastRecentDate = prefs.getString('recent_date') ?? '';
    if (today != lastRecentDate) {
      await prefs.setString('recent_recipes', '[]');
      await prefs.setString('recent_date', today);
    }
    
    setState(() {
      _userName = prefs.getString('user') ?? 'User';
      _avatarType = prefs.getString('user_avatar') ?? 'none';
      _customAvatarPath = prefs.getString('user_avatar_custom') ?? '';
      String saved = prefs.getString('saved_recipes') ?? '[]';
      String recent = prefs.getString('recent_recipes') ?? '[]';
      
      try {
        _savedRecipes = jsonDecode(saved);
        _recentRecipes = jsonDecode(recent);
      } catch(e) {
        _savedRecipes = [];
        _recentRecipes = [];
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.orange.shade600,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                        ),
                      ),
                      SafeArea(
                        child: _buildIdentitySection(),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.5)),
              centerTitle: true,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              )
            ],
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                   const SizedBox(height: 20),
                  _buildAppToolsGrid(),
                  const SizedBox(height: 24),
                  _buildActivityTracking(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: AvatarUtils.buildAvatar(
                  type: _avatarType,
                  customPath: _customAvatarPath,
                  radius: 40,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.2)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatPill(Icons.favorite, '${_savedRecipes.length} Saved'),
                        const SizedBox(width: 10),
                        _buildStatPill(Icons.history, '${_recentRecipes.length} Recent'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAppToolsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Tools', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildDelayedItem(0, _buildToolCard('Meal Planner', Icons.calendar_month, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlannerScreen())))),
              _buildDelayedItem(1, _buildToolCard('My Pantry', Icons.kitchen, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantryTrackerScreen())))),
              _buildDelayedItem(2, _buildToolCard('Grocery List', Icons.shopping_basket, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GroceryListScreen())))),
              _buildDelayedItem(3, _buildToolCard('Nutrition', Icons.health_and_safety, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionDashboard())))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDelayedItem(int index, Widget child) {
    double delay = (index * 0.1).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeIn)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOut)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, Color color, VoidCallback onTap) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTracking() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Food Journey', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 16),
          DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.white,
                      borderRadius: BorderRadius.circular(25.0),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                      ]
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.orangeAccent : Colors.orange.shade700,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    dividerColor: Colors.transparent,
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: 'Saved Recipes'),
                      Tab(text: 'Recently Viewed'),
                    ],
                  ),
                ),
                SizedBox(
                  height: 480, 
                  child: TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildRecipeGrid(_savedRecipes, "You haven't saved any recipes yet.", Icons.bookmark_border_rounded),
                      _buildRecipeGrid(_recentRecipes, "You haven't viewed any recipes recently.", Icons.history_rounded),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid(List<dynamic> recipesList, String emptyMessage, IconData emptyIcon) {
    if (recipesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 60, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: recipesList.length,
      itemBuilder: (context, index) {
        final recipe = recipesList[index];
        final imageUrl = recipe['imageUrl'] ?? recipe['Image_URL'] ?? '';
        final title = recipe['title'] ?? recipe['Title'] ?? 'Delicious Dish';
        
        return _buildDelayedItem(index + 4, GestureDetector(
          onTap: () {
            final recipeObj = Recipe.fromJson(recipe);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RecipeDetailsScreen(recipe: recipeObj)),
            ).then((_) => _loadData());
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 30),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title, 
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 15,
                            height: 1.2
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }
}
