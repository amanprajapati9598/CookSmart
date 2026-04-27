import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';

class RecipeResultsScreen extends StatefulWidget {
  final List<String> ingredients;
  final String query;
  final String diet;
  final String skill;
  final int limit;

  const RecipeResultsScreen({
    super.key,
    required this.ingredients,
    required this.query,
    required this.diet,
    required this.skill,
    required this.limit,
  });

  @override
  State<RecipeResultsScreen> createState() => _RecipeResultsScreenState();
}

class _RecipeResultsScreenState extends State<RecipeResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeProvider>(context, listen: false).discoverMatches(
        query: widget.query,
        ingredients: widget.ingredients,
        diet: widget.diet,
        skill: widget.skill,
        requestedLimit: widget.limit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<RecipeProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).cardColor,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        elevation: 1,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : provider.error != null
              ? Center(child: Text(provider.error!, style: const TextStyle(color: Colors.red)))
              : provider.recipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No recipes found for these ingredients.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.recipes.length,
                      itemBuilder: (context, index) {
                        return Container(
                          height: 260,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: RecipeCard(recipe: provider.recipes[index]),
                        );
                      },
                    ),
    );
  }
}
