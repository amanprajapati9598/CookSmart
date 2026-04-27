import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../providers/recipe_provider.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import '../utils/history_manager.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  List<Recipe> _results = [];
  bool _hasSearched = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    Future.delayed(Duration.zero, () => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _hasSearched = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(query);
    });
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _searchController.text = val.recognizedWords;
            if (val.finalResult) {
              _isListening = false;
              _performSearch(val.recognizedWords);
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    const defaultSuggestions = [
      'chicken biryani recipe', 'chicken leg piece', 'chicken biryani',
      'chicken kaise banaye', 'chicken recipe', 'chicken curry', 'chicken fry',
      'chicken fry recipe', 'chicken gravy in tamil', 'chicken soup recipe',
      'paneer tikka', 'paneer butter masala', 'mutton curry', 'fish fry',
      'maggie recipe', 'pasta white sauce', 'pizza at home'
    ];
    
    final matches = defaultSuggestions
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .toList();

    // Fill with themealdb data if you want more dynamic:
    try {
      final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=$query'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['meals'] != null) {
          final mealNames = (data['meals'] as List).map<String>((m) => m['strMeal'].toString().toLowerCase() + ' recipe').toList();
          for (var name in mealNames) {
            if (!matches.contains(name)) matches.add(name);
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _suggestions = matches.take(10).toList();
      });
    }
  }

  void _performSearch(String query) async {
    if (query.isEmpty) return;
    
    _searchController.text = query;
    _focusNode.unfocus();
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _suggestions = [];
    });

    HistoryManager.saveHistory(query, []);

    final provider = Provider.of<RecipeProvider>(context, listen: false);
    
    await provider.discoverMatches(
      query: query,
      ingredients: [],
      diet: 'Any',
      skill: 'Medium',
      requestedLimit: 15,
    );
    
    if (mounted) {
      setState(() {
        _results = provider.recipes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          onSubmitted: _performSearch,
          decoration: InputDecoration(
            hintText: _isListening ? 'Listening...' : 'Search YouTube style...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          ),
          style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            onPressed: _listen,
          )
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          if (_suggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.search, color: Colors.grey),
                    title: Text(
                      _suggestions[index],
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    trailing: const Icon(Icons.north_west, color: Colors.grey, size: 18),
                    onTap: () => _performSearch(_suggestions[index]),
                  );
                },
              ),
            ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_isLoading && _hasSearched && _results.isEmpty && _suggestions.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No results found', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              ),
            ),
          if (!_isLoading && _hasSearched && _results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  return Container(
                    height: 260,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: RecipeCard(recipe: _results[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
