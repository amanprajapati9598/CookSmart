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
