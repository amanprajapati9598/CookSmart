import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<String, List<String>> _plannedMeals = {}; // 'YYYY-MM-DD-MealType': ['Recipe Title']

  @override
  void initState() {
    super.initState();
    _loadPlanner();
  }

  Future<void> _loadPlanner() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('meal_planner');
    if (data != null) {
      setState(() {
        final decoded = json.decode(data) as Map<String, dynamic>;
        _plannedMeals = decoded.map((key, value) => MapEntry(key, List<String>.from(value)));
      });
    }
  }

  Future<void> _savePlanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('meal_planner', json.encode(_plannedMeals));
  }
  
  void _addMeal(String mealType, String recipe) {
    if (recipe.isEmpty) return;
    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String exactKey = '$dateKey-$mealType';
    
    setState(() {
      if (_plannedMeals[exactKey] == null) {
        _plannedMeals[exactKey] = [];
      }
      _plannedMeals[exactKey]!.add(recipe);
    });
    _savePlanner();
  }

  void _removeMeal(String mealType, int index) {
    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    String exactKey = '$dateKey-$mealType';
    setState(() {
      _plannedMeals[exactKey]?.removeAt(index);
    });
    _savePlanner();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Meal Planner', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Weekly Calendar View
          _buildDatePicker(isDark),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildMealSection('Breakfast', Icons.wb_twilight_rounded, '$dateKey-Breakfast', isDark, Colors.orange),
                _buildMealSection('Lunch', Icons.wb_sunny_rounded, '$dateKey-Lunch', isDark, Colors.green),
                _buildMealSection('Dinner', Icons.nightlight_round, '$dateKey-Dinner', isDark, Colors.indigoAccent),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 14,
        itemBuilder: (context, index) {
          DateTime day = DateTime.now().add(Duration(days: index - 3));
          bool isSelected = day.day == _selectedDate.day && day.month == _selectedDate.month && day.year == _selectedDate.year;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 65,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: isSelected 
                  ? LinearGradient(colors: [Colors.orange.shade600, Colors.orange.shade800]) 
                  : null,
                color: !isSelected ? (isDark ? const Color(0xFF1E1E1E) : Colors.white) : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected 
                  ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
                  : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
                border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade100)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day), 
                    style: TextStyle(
                      color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 12
                    )
                  ),
                  const SizedBox(height: 6),
                  Text(
                    day.day.toString(), 
                    style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87), 
                      fontSize: 20, 
                      fontWeight: FontWeight.w900
                    )
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealSection(String title, IconData icon, String exactKey, bool isDark, Color themeColor) {
    List<String> meals = _plannedMeals[exactKey] ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Row(
                   children: [
                     Container(
                       padding: const EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: themeColor.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(10),
                       ),
                       child: Icon(icon, color: themeColor, size: 20),
                     ),
                     const SizedBox(width: 12),
                     Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                   ],
                 ),
                 IconButton(
                   icon: Icon(Icons.add_circle_outline_rounded, color: Colors.orange.shade600),
                   onPressed: () => _showAddMealDialog(title),
                 )
              ],
            ),
          ),
          const Divider(height: 1),
          if (meals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu_rounded, color: Colors.grey.withOpacity(0.3), size: 30),
                    const SizedBox(height: 8),
                    Text(
                      'No meals planned', 
                      style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 13)
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: meals.length,
              itemBuilder: (context, index) {
                return _buildMealItem(title, meals[index], index, isDark);
              },
            )
        ],
      ),
    );
  }

  Widget _buildMealItem(String mealType, String recipeName, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recipeName, 
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
              )
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
            onPressed: () => _removeMeal(mealType, index),
          ),
        ],
      ),
    );
  }

  void _showAddMealDialog(String mealType) {
    TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Plan $mealType', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl, 
          style: TextStyle(color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Recipe name or dish...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Theme.of(ctx).brightness == Brightness.dark ? Colors.black26 : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () { 
              _addMeal(mealType, ctrl.text); 
              Navigator.pop(ctx); 
            }, 
            child: const Text('Add to Plan', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }
}

