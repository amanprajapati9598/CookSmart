import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  List<Map<String, dynamic>> _groceryItems = [];
  final TextEditingController _itemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGroceryList();
  }

  Future<void> _loadGroceryList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsString = prefs.getString('grocery_list');
    if (itemsString != null) {
      if (mounted) {
        setState(() {
          _groceryItems = List<Map<String, dynamic>>.from(json.decode(itemsString));
        });
      }
    }
  }

  Future<void> _saveGroceryList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('grocery_list', json.encode(_groceryItems));
  }

  void _addItem(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      _groceryItems.add({'name': name.trim(), 'isChecked': false});
    });
    _itemController.clear();
    _saveGroceryList();
  }

  void _toggleItem(int index) {
    setState(() {
      _groceryItems[index]['isChecked'] = !_groceryItems[index]['isChecked'];
    });
    _saveGroceryList();
  }

  void _deleteItem(int index) {
    setState(() {
      _groceryItems.removeAt(index);
    });
    _saveGroceryList();
  }

  void _clearAll() {
    if (_groceryItems.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Items?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will remove all items from your grocery list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _groceryItems.clear());
              _saveGroceryList();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        title: Text('Grocery List', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            onPressed: _clearAll,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildAddBar(isDark),
          Expanded(
            child: _groceryItems.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _groceryItems.length,
                    itemBuilder: (context, index) {
                      return _buildGroceryCard(_groceryItems[index], index, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
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
                  hintText: 'Add new ingredient...',
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

  Widget _buildGroceryCard(Map<String, dynamic> item, int index, bool isDark) {
    bool isChecked = item['isChecked'] ?? false;
    
    return Dismissible(
      key: Key('${item['name']}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 25),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteItem(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            item['name'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: isChecked ? TextDecoration.lineThrough : null,
              color: isChecked ? Colors.grey : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          value: isChecked,
          onChanged: (bool? value) => _toggleItem(index),
          activeColor: Colors.orange.shade600,
          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.orange.shade600.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'Your grocery list is empty',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Plan your meals and add ingredients\nto your list here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

