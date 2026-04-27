import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe.dart';
import '../screens/recipe_details_screen.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
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

  @override
  void didUpdateWidget(RecipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe.title != widget.recipe.title) {
      _checkSavedStatus();
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
          content: Text(_isSaved ? 'Recipe saved to profile!' : 'Recipe removed from saved.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildNoImageWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 12),
            Text(
              'Image not found', 
              style: TextStyle(
                color: Colors.grey.shade500, 
                fontSize: 14,
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsScreen(recipe: widget.recipe),
          ),
        ).then((_) => _checkSavedStatus()); // Re-check if it was unsaved in details page
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: widget.recipe.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              key: ValueKey(widget.recipe.imageUrl),
                              imageUrl: widget.recipe.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey.shade100,
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, err) => _buildNoImageWidget(),
                            )
                          : _buildNoImageWidget(),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: _toggleSave,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isSaved ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: _isSaved ? Colors.redAccent : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Text Section
            const SizedBox(height: 12),
            Text(
              widget.recipe.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.recipe.cookingTime} mins • ${widget.recipe.difficulty}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
