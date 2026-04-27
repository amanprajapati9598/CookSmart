import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/recipe.dart';
import 'recipe_details_screen.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1000)
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _mockPosts = [
    {
      "user": "Priya Sharma",
      "avatar": "https://randomuser.me/api/portraits/women/44.jpg",
      "time": "2 hours ago",
      "text": "Just tried the new Matar Paneer recipe! Scaled it up for 4 people, turned out absolutely perfect. The kids loved it! 🥘❤️",
      "image": "https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&q=80&w=1200",
      "likes": 124,
      "isLiked": false,
      "comments": <String>[]
    },
    {
      "user": "Rahul Desai",
      "avatar": "https://randomuser.me/api/portraits/men/32.jpg",
      "time": "5 hours ago",
      "text": "Made a quick Avocado Toast for breakfast using the Hands-Free Cook mode. Such a game changer when your hands are messy!",
      "image": "https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?auto=format&fit=crop&q=80&w=1200",
      "likes": 89,
      "isLiked": true,
      "comments": <String>[]
    },
    {
      "user": "Anita Kumar",
      "avatar": "https://randomuser.me/api/portraits/women/68.jpg",
      "time": "1 day ago",
      "text": "My first attempt at baking a chocolate cake. CookSmart's step-by-step instructions made it so easy. 🎂✨",
      "image": "https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?auto=format&fit=crop&q=80&w=1200",
      "likes": 210,
      "isLiked": false,
      "comments": <String>[]
    }
  ];

  void _toggleLike(int index) {
    setState(() {
      _mockPosts[index]['isLiked'] = !_mockPosts[index]['isLiked'];
      _mockPosts[index]['isLiked'] ? _mockPosts[index]['likes']++ : _mockPosts[index]['likes']--;
    });
  }

  Future<void> _toggleSave(int index) async {
    final post = _mockPosts[index];
    setState(() {
      post['isSaved'] = !(post['isSaved'] ?? false);
    });
    
    if (post['isSaved']) {
      final prefs = await SharedPreferences.getInstance();
      List<dynamic> savedRecipes = [];
      try {
        final existing = prefs.getString('saved_recipes');
        if (existing != null) savedRecipes = jsonDecode(existing);
      } catch (_) {}
      
      final dummyRecipe = {
        'Title': '${post['user']}\'s Shared Recipe',
        'Image_URL': post['image'],
        'Cooking_Time': 30,
        'Difficulty': 'Medium',
        'Calories': 400,
        'Ingredients_List': ['1 shared item', '1 pinch of love'],
        'Instructions': [post['text']]
      };
      
      savedRecipes.insert(0, dummyRecipe); 
      await prefs.setString('saved_recipes', jsonEncode(savedRecipes));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved to your Profile!'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Community Cooks', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add_box_outlined), onPressed: _showCreatePostSheet),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _mockPosts.length,
        itemBuilder: (context, index) {
          return _buildAnimatedPost(index, _mockPosts[index], isDark);
        },
      ),
    );
  }

  Widget _buildAnimatedPost(int index, Map<String, dynamic> post, bool isDark) {
    double delay = (index * 0.15).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeIn)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic)),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                     ClipOval(
                       child: Image.network(
                         post['avatar'],
                         width: 40,
                         height: 40,
                         fit: BoxFit.cover,
                         errorBuilder: (context, error, stackTrace) {
                           return Container(
                             width: 40,
                             height: 40,
                             color: Colors.orange.shade100,
                             child: Icon(Icons.person, color: Colors.orange.shade800, size: 24),
                           );
                         },
                       ),
                     ),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(post['user'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                           Text(post['time'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                         ],
                       ),
                     ),
                     PopupMenuButton<String>(
                       icon: const Icon(Icons.more_horiz, color: Colors.grey),
                       onSelected: (value) {
                         if (value == 'delete') {
                           setState(() {
                             _mockPosts.removeWhere((p) => p == post);
                           });
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Post deleted successfully.'), backgroundColor: Colors.redAccent)
                           );
                         } else if (value == 'report') {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Post reported. Admins will review it.'), backgroundColor: Colors.orange)
                           );
                         }
                       },
                       itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                         const PopupMenuItem(
                           value: 'delete',
                           child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 20), SizedBox(width: 8), Text('Delete Post')]),
                         ),
                         const PopupMenuItem(
                           value: 'report',
                           child: Row(children: [Icon(Icons.flag_outlined, size: 20), SizedBox(width: 8), Text('Report Post')]),
                         ),
                       ],
                     )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(post['text'], style: TextStyle(fontSize: 14, height: 1.4, color: isDark ? Colors.grey.shade300 : Colors.black87)),
              ),
              const SizedBox(height: 12),
              if (post['image'] != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      final dummyRecipe = Recipe(
                        title: '${post['user']}\'s Recipe',
                        cookingTime: 30,
                        calories: 400,
                        matchedIngredients: 2,
                        totalIngredients: 4,
                        imageUrl: post['image'],
                        ingredientsList: ['2 cups Flour', '1 cup Sugar', '1/2 cup Butter', '1 tsp Vanilla'],
                        instructions: ['Prep all ingredients.', 'Cook step by step.', 'Serve hot and enjoy!'],
                        difficulty: 'Medium',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RecipeDetailsScreen(recipe: dummyRecipe))
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        post['image'], 
                        width: double.infinity, 
                        height: 250, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 250,
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  children: [
                    _buildActionButton(
                       post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                       post['likes'].toString(),
                       post['isLiked'] ? Colors.red : Colors.grey,
                       () => _toggleLike(_mockPosts.indexOf(post))
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                       Icons.comment_outlined, 
                       post['comments'].length.toString(), 
                       Colors.grey, 
                       () => _showCommentsBox(_mockPosts.indexOf(post))
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon((post['isSaved'] ?? false) ? Icons.bookmark : Icons.bookmark_border, color: (post['isSaved'] ?? false) ? Colors.orange : Colors.grey), 
                      onPressed: () => _toggleSave(_mockPosts.indexOf(post))
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePostSheet() {
    TextEditingController msgCtrl = TextEditingController();
    TextEditingController imgUrlCtrl = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.55,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                const Text('Create New Post', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                TextField(
                  controller: msgCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share your recipe experience, tips, or ingredients...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: imgUrlCtrl,
                  decoration: InputDecoration(
                    hintText: 'Paste Recipe Image URL (Optional)',
                    prefixIcon: const Icon(Icons.image_outlined, color: Colors.orange),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    onPressed: () {
                      if (msgCtrl.text.trim().isNotEmpty) {
                        setState(() {
                          _mockPosts.insert(0, {
                            "user": "You (Chef)",
                            "avatar": "assets/avatars/male.png",
                            "time": "Just now",
                            "text": msgCtrl.text.trim(),
                            "image": imgUrlCtrl.text.trim().isNotEmpty ? imgUrlCtrl.text.trim() : null,
                            "likes": 0,
                            "isLiked": false,
                            "comments": <String>[],
                            "isSaved": false
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your recipe post is live!'), backgroundColor: Colors.green));
                      }
                    },
                    child: const Text('Post Recipe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  void _showCommentsBox(int postIndex) {
    TextEditingController commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final comments = _mockPosts[postIndex]['comments'] as List<String>;
            bool isDark = Theme.of(context).brightness == Brightness.dark;
            
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 16),
                    Text('Comments (${comments.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Divider(),
                    Expanded(
                      child: comments.isEmpty 
                        ? Center(child: Text("No comments yet. Be the first to reply!", style: TextStyle(color: Colors.grey.shade500)))
                        : ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, idx) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    const CircleAvatar(radius: 16, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 16, color: Colors.white)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                                        child: Text(comments[idx], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentCtrl,
                            decoration: InputDecoration(
                              hintText: 'Add a reply...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.orange.shade600,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 18),
                            onPressed: () {
                              if (commentCtrl.text.trim().isNotEmpty) {
                                setModalState(() {
                                  comments.add(commentCtrl.text.trim());
                                });
                                setState(() {}); 
                                commentCtrl.clear();
                              }
                            },
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildActionButton(IconData icon, String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
