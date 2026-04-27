import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/language_provider.dart';
import 'login_screen.dart';
import '../utils/avatar_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  String _userName = 'Chef';
  String _avatarType = 'none';
  String _customAvatarPath = '';
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

    _animController.forward();
    _loadUser();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (c) => const LoginScreen()),
        (r) => false,
      );
    }
  }

  int _savedCount = 0;

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    String savedString = prefs.getString('saved_recipes') ?? '[]';
    int count = 0;
    try {
      List<dynamic> saved = jsonDecode(savedString);
      count = saved.length;
    } catch (_) {}

    setState(() {
      _userName = prefs.getString('user') ?? 'Chef';
      _avatarType = prefs.getString('user_avatar') ?? 'none';
      _customAvatarPath = prefs.getString('user_avatar_custom') ?? '';
      _savedCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).primaryColor, const Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16, right: 24),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lang.t('dashboard_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('${lang.t('hello_user')}, $_userName! 👋', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                  AvatarUtils.buildAvatar(
                    type: _avatarType,
                    customPath: _customAvatarPath,
                    radius: 20,
                    borderColor: Colors.white.withOpacity(0.2),
                    borderWidth: 1,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            _buildAnimatedStat(0.3, '$_savedCount', lang.t('saved'), FontAwesomeIcons.solidHeart, const [Color(0xFFff9a9e), Color(0xFFfecfef)]),
                            const SizedBox(width: 16),
                            _buildAnimatedStat(0.4, '12k', lang.t('calories'), FontAwesomeIcons.fireFlameCurved, const [Color(0xFFf6d365), Color(0xFFfda085)]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      _buildSectionHeader(lang.t('trending_recipes'), lang),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 240,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildAnimatedCard(0.5, 'Paneer Tikka', '20 min', 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?auto=format&fit=crop&q=80&w=800'),
                            _buildAnimatedCard(0.6, 'Masala Dosa', '40 min', 'https://images.unsplash.com/photo-1589301760014-d929f39ce9b1?auto=format&fit=crop&q=80&w=800'),
                            _buildAnimatedCard(0.7, 'Chole Bhature', '45 min', 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?auto=format&fit=crop&q=80&w=800'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      _buildSectionHeader(lang.t('fast_10_min_meals'), lang),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 240,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildAnimatedCard(0.8, 'Avocado Toast', '5 min', 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?auto=format&fit=crop&q=80&w=800'),
                            _buildAnimatedCard(0.9, 'Omelette', '8 min', 'https://images.unsplash.com/photo-1510693248842-8cbf28de41b8?auto=format&fit=crop&q=80&w=800'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(lang.t('expiring_soon'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            _buildAnimatedExpiring(1.0, context, 'Fresh Milk', 'Expires in 1 day', FontAwesomeIcons.glassWater, Colors.blueAccent),
                            _buildAnimatedExpiring(1.1, context, 'Baby Spinach', 'Expires today', FontAwesomeIcons.leaf, Colors.redAccent),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: OutlinedButton(
                          onPressed: _handleLogout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: Colors.white,
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(FontAwesomeIcons.arrowRightFromBracket, size: 18),
                              const SizedBox(width: 12),
                              Text(lang.t('sign_out'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStat(double delay, String value, String label, dynamic icon, List<Color> gradientColors) {
    return Expanded(
      child: _buildDelayedItem(
        delay: delay,
        child: _buildStatCard(context, value, label, icon, gradientColors),
      ),
    );
  }

  Widget _buildAnimatedCard(double delay, String title, String time, String imgUrl) {
    return _buildDelayedItem(
      delay: delay,
      child: _buildHorizontalCard(title, time, imgUrl),
    );
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

  Widget _buildAnimatedExpiring(double delay, BuildContext context, String title, String subtitle, dynamic icon, Color indicator) {
    return _buildDelayedItem(
      delay: delay,
      child: _buildExpiringItem(context, title, subtitle, icon, indicator),
    );
  }

  Widget _buildDelayedItem({required double delay, required Widget child}) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval((delay * 0.5).clamp(0.0, 0.99), (delay * 0.5 + 0.3).clamp(0.0, 1.0), curve: Curves.easeIn),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval((delay * 0.5).clamp(0.0, 0.99), (delay * 0.5 + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(String title, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
          Text(lang.t('see_all'), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(String title, String time, String imgUrl) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            imgUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imgUrl,
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey.shade100),
                    errorWidget: (context, url, err) => _buildNoImageWidget(),
                  )
                : _buildNoImageWidget(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.clock, size: 12, color: Colors.orangeAccent),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, dynamic icon, List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: gradientColors.last.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
            child: FaIcon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildExpiringItem(BuildContext context, String title, String subtitle, dynamic icon, Color indicator) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: indicator, width: 6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: indicator.withOpacity(0.1), radius: 24, child: FaIcon(icon, color: indicator, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}

  Widget _buildSectionHeader(String title, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
          Text(lang.t('see_all'), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(String title, String time, String imgUrl) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.network(imgUrl, height: double.infinity, width: double.infinity, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.clock, size: 12, color: Colors.orangeAccent),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, dynamic icon, List<Color> gradientColors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: gradientColors.last.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
              child: FaIcon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 20),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringItem(BuildContext context, String title, String subtitle, dynamic icon, Color indicator) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: indicator, width: 6)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: indicator.withOpacity(0.1), radius: 24, child: FaIcon(icon, color: indicator, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
