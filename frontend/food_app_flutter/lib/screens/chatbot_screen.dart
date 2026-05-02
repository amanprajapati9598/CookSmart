import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import '../screens/recipe_details_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final Widget? customWidget;
  
  ChatMessage({required this.text, required this.isUser, this.customWidget});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Initial Bot Message
    _messages.add(ChatMessage(
      text: "Hello! I'm your CookSmart AI Chef. What would you like to cook today?",
      isUser: false,
      customWidget: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildQuickChip(context, "🍳 Breakfast"),
              _buildQuickChip(context, "🍛 Lunch"),
              _buildQuickChip(context, "🍲 Dinner"),
              _buildQuickChip(context, "🥗 Healthy"),
            ],
          ),
        ),
      )
    ));
  }

  Widget _buildQuickChip(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _sendMessage(label.replaceAll(RegExp(r'[^a-zA-Z ]'), '').trim(), isButton: true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), 
              blurRadius: 8, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Text(label, style: TextStyle(
          fontWeight: FontWeight.w600, 
          fontSize: 13,
          color: isDark ? Colors.white : Colors.black87,
        )),
      ),
    );
  }

  void _sendMessage(String text, {bool isButton = false}) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    
    if (!isButton) _msgController.clear();
    _scrollToBottom();

    _handleBotResponse(text);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
             setState(() => _isListening = false);
             if (_msgController.text.isNotEmpty) {
               _sendMessage(_msgController.text);
             }
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
          print('onError: $val');
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _msgController.text = val.recognizedWords;
          }),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied.')));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile == null) return;
    
    setState(() {
      _messages.add(ChatMessage(text: "📸 Scanning image for ingredients...", isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();
    
    try {
      final imageBytes = await pickedFile.readAsBytes();
      String mimeType = 'image/jpeg';
      if (pickedFile.name.toLowerCase().endsWith('.png')) mimeType = 'image/png';
      else if (pickedFile.name.toLowerCase().endsWith('.webp')) mimeType = 'image/webp';
      
      final geminiService = GeminiService();
      String ingredientsStr = await geminiService.analyzeImageForIngredients(imageBytes.toList(), mimeType);
      
      if (!mounted) return;
      _handleBotResponse(ingredientsStr);
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(text: "Sorry, I couldn't scan the image: $e", isUser: false));
      });
      _scrollToBottom();
    }
  }

  Future<void> _handleBotResponse(String userText) async {
    try {
      final geminiService = GeminiService();
      String intentOrReply = await geminiService.getChatIntentOrReply(userText);
      
      if (!mounted) return;

      if (intentOrReply.toUpperCase() != 'RECIPE') {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(text: intentOrReply, isUser: false));
        });
        _scrollToBottom();
        return;
      }

      // Use the actual AI RecipeProvider
      await Provider.of<RecipeProvider>(context, listen: false).discoverMatches(
        query: userText,
        ingredients: [],
        diet: 'Any',
        skill: 'Any',
        requestedLimit: 4,
      );

      if (!mounted) return;
      final recipes = Provider.of<RecipeProvider>(context, listen: false).recipes;

      setState(() {
        _isTyping = false;
        
        if (recipes.isEmpty) {
          _messages.add(ChatMessage(
            text: "I couldn't find any specific recipes for that. Please try giving me some different ingredients or cuisines!",
            isUser: false,
          ));
        } else {
          _messages.add(ChatMessage(
            text: "Sure! Here is what I found for you based on '$userText':",
            isUser: false,
            customWidget: Column(
              children: [
                const SizedBox(height: 12),
                SizedBox(
                  height: 380,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: recipes.map((r) => _buildRecipeCard(r)).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _buildNutritionInfo(),
                const SizedBox(height: 12),
                 Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildActionChip("🍅 Veg Snacks"),
                    _buildActionChip("🥦 Low Calorie"),
                    _buildActionChip("🇮🇳 Indian"),
                  ],
                )
              ],
            )
          ));
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(text: "I encountered a network issue finding that recipe. Please try again.", isUser: false));
      });
    }
    _scrollToBottom();
  }

  Future<void> _saveRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();
    String savedString = prefs.getString('saved_recipes') ?? '[]';
    List<dynamic> savedList;
    try {
      savedList = jsonDecode(savedString);
    } catch (_) {
      savedList = [];
    }

    if (!savedList.any((item) => item['title'] == recipe.title)) {
      savedList.insert(0, recipe.toJson());
      await prefs.setString('saved_recipes', jsonEncode(savedList));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe Saved to Profile!'), duration: Duration(seconds: 2)));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe is already saved!'), duration: Duration(seconds: 2)));
      }
    }
  }

  Widget _buildRecipeCard(Recipe recipe) {
    String title = recipe.title;
    String time = "${recipe.cookingTime} mins";
    String cal = "${recipe.calories} cal";
    String ingredients = recipe.ingredientsList.take(3).join(', ');
    String image = recipe.imageUrl;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailsScreen(recipe: recipe))),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.08), 
              blurRadius: 12, 
              offset: const Offset(0, 6)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  image.isNotEmpty
                      ? Image.network(
                          image, 
                          height: 120, 
                          width: double.infinity, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 120, 
                            width: double.infinity,
                            color: Theme.of(context).cardColor,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 30),
                                const SizedBox(height: 4),
                                Text('Image not found', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ]
                            ),
                          ),
                        )
                      : Container(
                          height: 120, 
                          width: double.infinity,
                          color: Theme.of(context).disabledColor.withOpacity(0.05),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 30),
                              const SizedBox(height: 4),
                              Text('Image not found', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ]
                          ),
                        ),
                  Positioned(
                    top: 8, right: 8, 
                    child: GestureDetector(
                      onTap: () => _saveRecipe(recipe),
                      child: const Icon(Icons.favorite_border, color: Colors.white)
                    )
                  ),
                ]
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _tag(time, Colors.orange.shade100, Colors.orange.shade900),
                      const SizedBox(width: 6),
                      _tag(cal, Colors.blue.shade50, Colors.blue.shade700),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Ingredients:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  Text('• $ingredients', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  // Use Wrap to prevent overflow on smaller screens
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      GestureDetector(
                        onTap: () => _saveRecipe(recipe),
                        child: _filledBtn("Save", Colors.orange.shade100, Colors.orange.shade900, Icons.favorite),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailsScreen(recipe: recipe))),
                        child: _filledBtn("Steps", Colors.grey.shade100, Colors.grey.shade800, Icons.message),
                      ),
                    ],
                  )
                ]
              )
            )
          ]
        )
      )
    );
  }

  Widget _tag(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: textCol, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _filledBtn(String text, Color bg, Color textCol, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textCol, size: 12),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: textCol, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      )
    );
  }

  Widget _buildNutritionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Nutrition Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _nutriNode("300", "Cals", Colors.orange.shade100),
              _nutriNode("12g", "Protein", Colors.blue.shade100),
              _nutriNode("20g", "Fat", Colors.red.shade100),
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle), child: const Icon(Icons.info_outline, size: 16)),
            ],
          )
        ],
      )
    );
  }

  Widget _nutriNode(String val, String lbl, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           Text(val, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
           const SizedBox(width: 4),
           Text(lbl, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      )
    );
  }

  Widget _buildActionChip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _sendMessage(label.replaceAll(RegExp(r'[^\w\s-]'), '').trim(), isButton: true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), 
              blurRadius: 8, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Text(label, style: TextStyle(
          fontWeight: FontWeight.w600, 
          fontSize: 13,
          color: isDark ? Colors.white : Colors.black87,
        )),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
             title: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Container(
                   padding: const EdgeInsets.all(6),
                   decoration: BoxDecoration(
                     gradient: const LinearGradient(colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)]),
                     borderRadius: BorderRadius.circular(10),
                   ),
                   child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 18),
                 ),
                 const SizedBox(width: 10),
                 Text('CookSmart AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyMedium?.color)),
               ],
             ),
             backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
             elevation: 0,
             centerTitle: true,
             iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
             bottom: PreferredSize(
               preferredSize: const Size.fromHeight(1.0),
               child: Container(
                 color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                 height: 1.0,
               ),
             ),
           ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: const Color(0xFFFF7E5F)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Chef AI is thinking...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: msg.isUser 
                        ? const LinearGradient(
                            colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ) 
                        : null,
                    color: msg.isUser ? null : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(msg.isUser ? 24 : 8),
                      bottomRight: Radius.circular(msg.isUser ? 8 : 24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: msg.isUser 
                            ? const Color(0xFFFF7E5F).withOpacity(0.3) 
                            : Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Text(
                    msg.text, 
                    style: TextStyle(
                      fontSize: 15, 
                      color: msg.isUser ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: msg.isUser ? FontWeight.w500 : FontWeight.normal,
                      height: 1.4,
                    )
                  ),
                ),
              ),
            ],
          ),
          if (msg.customWidget != null) Padding(
            padding: const EdgeInsets.only(top: 12),
            child: msg.customWidget!,
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90), // padded for bottom nav
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
            blurRadius: 20,
            spreadRadius: 10,
            offset: const Offset(0, -10),
          )
        ]
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _listen,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red.withOpacity(0.15) : Colors.transparent, 
                    shape: BoxShape.circle
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none_rounded, 
                    color: _isListening ? Colors.redAccent : (isDark ? Colors.grey.shade400 : Colors.grey.shade600), 
                    size: 24
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _msgController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening...' : 'Type your recipe request...',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  ),
                  onSubmitted: (text) => _sendMessage(text),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                onPressed: _pickImage,
              ),
              GestureDetector(
                onTap: () => _sendMessage(_msgController.text),
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
