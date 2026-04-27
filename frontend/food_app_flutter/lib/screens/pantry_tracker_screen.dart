import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PantryTrackerScreen extends StatefulWidget {
  const PantryTrackerScreen({super.key});

  @override
  State<PantryTrackerScreen> createState() => _PantryTrackerScreenState();
}

class _PantryTrackerScreenState extends State<PantryTrackerScreen> {
  List<String> _pantryItems = [];
  final TextEditingController _itemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPantry();
  }

  Future<void> _loadPantry() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsString = prefs.getString('pantry_items');
    if (itemsString != null) {
      setState(() {
        _pantryItems = List<String>.from(json.decode(itemsString));
      });
    }
  }

  Future<void> _savePantry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pantry_items', json.encode(_pantryItems));
  }

  void _addItem(String name) {
    if (name.trim().isEmpty) return;
    if (!_pantryItems.contains(name.trim())) {
      setState(() {
        _pantryItems.add(name.trim());
      });
      _savePantry();
    }
    _itemController.clear();
  }

  void _deleteItem(int index) {
    setState(() {
      _pantryItems.removeAt(index);
    });
    _savePantry();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Pantry', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildInfoBanner(isDark),
          _buildAddBar(isDark),
          Expanded(
            child: _pantryItems.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _pantryItems.length,
                    itemBuilder: (context, index) {
                      return _buildIngredientCard(_pantryItems[index], index, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.orange.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.orange.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.orange.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Add items you have at home. We will suggest recipes using these ingredients!',
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _itemController,
                decoration: InputDecoration(
                  hintText: 'e.g. Garlic, Onions...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onSubmitted: _addItem,
              ),
            ),
            GestureDetector(
              onTap: () => _addItem(_itemController.text),
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientCard(String name, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade600.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.kitchen_rounded, color: Colors.orange.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
            onPressed: () => _deleteItem(index),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            'Your pantry is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Add ingredients to get personalized\nrecipe recommendations.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

