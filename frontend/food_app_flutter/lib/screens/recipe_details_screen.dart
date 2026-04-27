import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recipe.dart';
import 'hands_free_cooking_screen.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailsScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isSaved = false;
  int _servings = 2; // Default servings

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
    _checkSavedStatus();
    _addToRecent();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _scaleIngredient(String ingredient, int currentServings) {
    if (currentServings == 2) return ingredient;
    final regex = RegExp(r'^(\d+(?:\.\d+)?|\d+\/\d+|\d+ \d+\/\d+)\s*(.*)');
    final match = regex.firstMatch(ingredient);
    if (match != null) {
      double parseFraction(String frac) {
        if (frac.contains(' ')) {
          var parts = frac.split(' ');
          return double.parse(parts[0]) + parseFraction(parts[1]);
        }
        if (frac.contains('/')) {
          var parts = frac.split('/');
          return double.parse(parts[0]) / double.parse(parts[1]);
        }
        return double.tryParse(frac) ?? 0;
      }
      try {
        double amount = parseFraction(match.group(1)!);
        String rest = match.group(2)!;
        double newAmount = (amount / 2) * currentServings;
        String formatAmount(double num) {
          if (num == num.roundToDouble()) return num.round().toString();
          return num.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        }
        return '${formatAmount(newAmount)} $rest';
      } catch (e) {
        return ingredient;
      }
    }
    return ingredient;
  }

  Future<void> _checkSavedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String savedString = prefs.getString('saved_recipes') ?? '[]';
    try {
      List<dynamic> savedList = jsonDecode(savedString);
      if (mounted) {
        setState(() {
          _isSaved = savedList.any((item) => item['title'] == widget.recipe.title);
        });
      }
    } catch (_) {}
  }

  Future<void> _addToRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    final lastRecentDate = prefs.getString('recent_date') ?? '';

    List<dynamic> recentList = [];
    if (today == lastRecentDate) {
      String recentString = prefs.getString('recent_recipes') ?? '[]';
      try {
        recentList = jsonDecode(recentString);
      } catch (_) {}
    } else {
      await prefs.setString('recent_date', today);
    }

    if (!recentList.any((item) => item['title'] == widget.recipe.title)) {
      recentList.insert(0, widget.recipe.toJson());
      await prefs.setString('recent_recipes', jsonEncode(recentList));
    }
  }

  Future<void> _toggleSave() async {
    final prefs = await SharedPreferences.getInstance();
    String savedString = prefs.getString('saved_recipes') ?? '[]';
    List<dynamic> savedList;
    try {
      savedList = jsonDecode(savedString);
    } catch (_) {
      savedList = [];
    }

    if (_isSaved) {
      savedList.removeWhere((item) => item['title'] == widget.recipe.title);
    } else {
      savedList.insert(0, widget.recipe.toJson());
    }

    await prefs.setString('saved_recipes', jsonEncode(savedList));
    
    if (mounted) {
      setState(() {
        _isSaved = !_isSaved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Recipe Saved!' : 'Removed from Saved!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildNoImageWidget() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8F8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 64),
            const SizedBox(height: 16),
            Text(
              'Image not found', 
              style: TextStyle(
                color: Colors.grey.shade500, 
                fontSize: 18,
                fontWeight: FontWeight.w500
              )
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black87),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: widget.recipe.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.recipe.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey.shade100),
                            errorWidget: (context, url, err) => _buildNoImageWidget(),
                          )
                        : _buildNoImageWidget(),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                          stops: const [0.0, 0.3, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 4, bottom: 4),
              child: _GlassButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
            ),
            actions: [
              _GlassButton(
                icon: _isSaved ? Icons.favorite : Icons.favorite_border,
                color: _isSaved ? Colors.redAccent : Colors.white,
                onTap: _toggleSave,
              ),
              const SizedBox(width: 12),
              _GlassButton(
                icon: Icons.share_outlined,
                onTap: () {
                  final String shareText = 'Check out this recipe for *${widget.recipe.title}* on CookSmart!\n\n'
                      '⏱ Time: ${widget.recipe.cookingTime} mins\n'
                      '🔥 Difficulty: ${widget.recipe.difficulty}\n\n'
                      'Get the app to see the full ingredients and steps!';
                  Share.share(shareText);
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.recipe.title,
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.2),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: const Color(0xFFFFF4E5), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  const Text('4.8', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.orange)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_filled_rounded, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, size: 16),
                                  const SizedBox(width: 6),
                                  Text('${widget.recipe.cookingTime} mins', style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                              child: Row(
                                children: [
                                  Icon(Icons.local_fire_department_rounded, color: const Color(0xFFFF7E5F), size: 16),
                                  const SizedBox(width: 6),
                                  Text(widget.recipe.difficulty, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                      const SizedBox(height: 10),
                      Text(
                        'An AI-crafted recipe blending perfect flavors selected based on your preferences and available ingredients. Experience seamless cooking filled with rich aromas and delightful taste.',
                        style: TextStyle(fontSize: 15, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.6),
                      ),

                      const SizedBox(height: 32),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(onTap: () { if(_servings > 1) setState(() => _servings--); }, child: Icon(Icons.remove, size: 20, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(width: 12),
                                Text('$_servings Servings', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                const SizedBox(width: 12),
                                GestureDetector(onTap: () { if(_servings < 12) setState(() => _servings++); }, child: Icon(Icons.add, size: 20, color: isDark ? Colors.white : Colors.black87)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(vertical: 8)
                                    ),
                                    icon: const Icon(Icons.shopping_cart_checkout, size: 18, color: Colors.white),
                                    label: const Text('Add List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    onPressed: () async {
                                       final prefs = await SharedPreferences.getInstance();
                                       List<dynamic> currentList = [];
                                       try {
                                         final existing = prefs.getString('grocery_list');
                                         if (existing != null) currentList = jsonDecode(existing);
                                       } catch (_) {}
                                       
                                       int added = 0;
                                       for (var ing in widget.recipe.ingredientsList) {
                                         String scaled = _scaleIngredient(ing, _servings);
                                         if (!currentList.any((i) => i['name'] == scaled)) {
                                           currentList.add({'name': scaled, 'isChecked': false});
                                           added++;
                                         }
                                       }
                                       await prefs.setString('grocery_list', jsonEncode(currentList));
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $added items to your Grocery List!')));
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(vertical: 8)
                                    ),
                                    icon: const Icon(Icons.health_and_safety, size: 18, color: Colors.white),
                                    label: const Text('Log Meal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    onPressed: () async {
                                      final prefs = await SharedPreferences.getInstance();
                                      final today = DateTime.now().toString().split(' ')[0];
                                      final logKey = 'nutrition_log_$today';
                                      
                                      Map<String, dynamic> log = {};
                                      final existing = prefs.getString(logKey);
                                      if (existing != null) {
                                        log = jsonDecode(existing);
                                      } else {
                                        log = {'calories': 0, 'proteins': 0, 'carbs': 0, 'fats': 0};
                                      }

                                      double multiplier = _servings / 2.0;
                                      log['calories'] = (log['calories'] ?? 0) + (widget.recipe.calories * multiplier).round();
                                      log['proteins'] = (log['proteins'] ?? 0) + (widget.recipe.proteins * multiplier).round();
                                      log['carbs'] = (log['carbs'] ?? 0) + (widget.recipe.carbs * multiplier).round();
                                      log['fats'] = (log['fats'] ?? 0) + (widget.recipe.fats * multiplier).round();

                                      await prefs.setString(logKey, jsonEncode(log));
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Meal logged to Nutrition Tracker!'), backgroundColor: Colors.green),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                          Text('${widget.recipe.ingredientsList.length} items', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (widget.recipe.ingredientsList.isEmpty)
                        const Text('Check your pantry for essential items.', style: TextStyle(fontSize: 15, color: Colors.grey))
                      else
                        Column(
                          children: widget.recipe.ingredientsList.asMap().entries.map((entry) {
                            int index = entry.key;
                            String item = entry.value;
                            return _buildAnimatedIngredient(index, item, isDark);
                          }).toList(),
                        ),

                      const SizedBox(height: 32),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('How to Make It', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C2E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                            icon: const Icon(Icons.mic, color: Colors.white, size: 16),
                            label: const Text('Cook Mode', style: TextStyle(color: Colors.white)),
                            onPressed: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => HandsFreeCookingScreen(recipe: widget.recipe)));
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (widget.recipe.instructions.isEmpty)
                        const Text('Standard cooking instructions apply.', style: TextStyle(fontSize: 15, color: Colors.grey))
                      else
                        Column(
                          children: widget.recipe.instructions.asMap().entries.map((entry) {
                            int index = entry.key;
                            String step = entry.value;
                            return _buildAnimatedStep(index, step, isDark);
                          }).toList(),
                        ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIngredient(int index, String item, bool isDark) {
    double delay = (index * 0.05).clamp(0.0, 1.0);
    String displayItem = _scaleIngredient(item, _servings);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeIn)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
               Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFFF7E5F).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFFFF7E5F), size: 20),
               ),
              const SizedBox(width: 16),
              Expanded(child: Text(displayItem, style: TextStyle(fontSize: 16, color: isDark ? Colors.grey.shade200 : Colors.grey.shade800, fontWeight: FontWeight.w600))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStep(int index, String step, bool isDark) {
    double delay = (index * 0.05 + 0.2).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeIn)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 8, offset: const Offset(0, 4))
            ]
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)]),
                  borderRadius: BorderRadius.circular(10)
                ),
                alignment: Alignment.center,
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    step,
                    style: TextStyle(fontSize: 15, height: 1.6, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _GlassButton({required this.icon, required this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}
