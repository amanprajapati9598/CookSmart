import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

class NutritionDashboard extends StatefulWidget {
  const NutritionDashboard({super.key});

  @override
  State<NutritionDashboard> createState() => _NutritionDashboardState();
}

class _NutritionDashboardState extends State<NutritionDashboard> with SingleTickerProviderStateMixin {
  int _calories = 0;
  int _proteins = 0;
  int _carbs = 0;
  int _fats = 0;
  bool _isLoading = true;
  final int _calorieGoal = 2000;
  late AnimationController _refreshController;
  final List<String> _healthTips = [
    'Logging your meals right after cooking ensures 25% better tracking accuracy!',
    'Drink at least 8 glasses of water a day to stay hydrated during your meals.',
    'Include green leafy vegetables in your diet for a natural source of fiber.',
    'A 10-minute walk after your dinner can significantly help with digestion.',
    'Try to include high-protein ingredients in your breakfast for lasting energy.',
    'Using original spices instead of pre-mixed ones can reduce sodium intake.'
  ];

  late String _currentTip;

  @override
  void initState() {
    super.initState();
    _currentTip = _healthTips[math.Random().nextInt(_healthTips.length)];
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadLogs();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _currentTip = _healthTips[math.Random().nextInt(_healthTips.length)];
    });
    _refreshController.repeat();
    
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];
    final logKey = 'nutrition_log_$today';
    
    // Simulate a short network-like delay for the animation to look meaningful
    await Future.delayed(const Duration(milliseconds: 800));
    
    final existing = prefs.getString(logKey);
    if (existing != null) {
      final log = jsonDecode(existing);
      if (mounted) {
        setState(() {
          _calories = log['calories'] ?? 0;
          _proteins = log['proteins'] ?? 0;
          _carbs = log['carbs'] ?? 0;
          _fats = log['fats'] ?? 0;
        });
      }
    } else {
       if (mounted) {
         setState(() {
           _calories = 0; _proteins = 0; _carbs = 0; _fats = 0;
         });
       }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      _refreshController.stop();
      _refreshController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double progress = (_calories / _calorieGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('Nutrition Sync', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87, letterSpacing: -0.5)), 
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          RotationTransition(
            turns: _refreshController,
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : Colors.black87),
              onPressed: _isLoading ? null : _loadLogs,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Goal Card (Circular Progress)
            _buildGoalHeader(progress, isDark),
            const SizedBox(height: 32),
            
            // Macros Layout
            Row(
              children: [
                Expanded(child: _buildMacroItem('Proteins', '${_proteins}g', 'P', Colors.redAccent, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildMacroItem('Carbs', '${_carbs}g', 'C', Colors.blueAccent, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildMacroItem('Fats', '${_fats}g', 'F', Colors.amber, isDark)),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Health Tips / Info Section
            _buildInfoCard(isDark),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalHeader(double progress, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF1E1E1E), const Color(0xFF121212)] 
            : [Colors.white, const Color(0xFFF0F0F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _RadialProgressPainter(
                    progress: progress,
                    color: Colors.orange.shade600,
                    bgColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$_calories',
                    style: TextStyle(
                      fontSize: 36, 
                      fontWeight: FontWeight.w900, 
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'of $_calorieGoal kcal',
                    style: TextStyle(
                      fontSize: 14, 
                      color: Colors.grey.shade500, 
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            progress >= 1.0 ? 'Goal Reached! 🎉' : 'Keep going! ${_calorieGoal - _calories} kcal to go',
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: progress >= 1.0 ? Colors.green : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, String initial, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              initial, 
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 17, 
              fontWeight: FontWeight.w900, 
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12, 
              color: Colors.grey, 
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade400.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt, color: Colors.green.shade400),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Health Pro-Tip:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentTip,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _RadialProgressPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 14.0;

    // Background circle
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


