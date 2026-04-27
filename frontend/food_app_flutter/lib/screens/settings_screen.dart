import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import 'login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'history_screen.dart';
import 'feedback_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  // Notification states
  bool _dailyRecipeOn = true;
  bool _mealReminderOn = true;
  bool _newRecipesAlert = true;
  bool _achievementNotif = true;

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showThemeDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    bool isDark = themeProvider.themeMode == ThemeMode.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('Light mood'),
                trailing: !isDark ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  themeProvider.setTheme(false);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Dark mood'),
                trailing: isDark ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  themeProvider.setTheme(true);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showLanguageDialog() {
    final langs = ['English', 'Hindi'];
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(langProvider.t('select_language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...langs.map((l) => ListTile(
                title: Text(l),
                trailing: langProvider.currentLanguage == l ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () {
                  langProvider.changeLanguage(l);
                  Navigator.pop(context);
                },
              )).toList(),
            ],
          ),
        );
      }
    );
  }

  void _showNotificationsSheet() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(lang.t('notifications'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    SwitchListTile(
                      title: Text(lang.t('daily_recipe_suggestion')),
                      value: _dailyRecipeOn,
                      onChanged: (v) {
                        setSheetState(() => _dailyRecipeOn = v);
                        setState(() => _dailyRecipeOn = v);
                      },
                    ),
                    SwitchListTile(
                      title: Text(lang.t('meal_reminder')),
                      value: _mealReminderOn,
                      onChanged: (v) {
                        setSheetState(() => _mealReminderOn = v);
                        setState(() => _mealReminderOn = v);
                      },
                    ),
                    SwitchListTile(
                      title: Text(lang.t('new_recipes_alert')),
                      value: _newRecipesAlert,
                      onChanged: (v) {
                        setSheetState(() => _newRecipesAlert = v);
                        setState(() => _newRecipesAlert = v);
                      },
                    ),
                    SwitchListTile(
                      title: Text(lang.t('achievement_notification')),
                      value: _achievementNotif,
                      onChanged: (v) {
                        setSheetState(() => _achievementNotif = v);
                        setState(() => _achievementNotif = v);
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400);
    
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar', 'custom');
      await prefs.setString('user_avatar_custom', pickedFile.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Photo Updated!'), backgroundColor: Colors.green));
      }
    }
  }

  void _showAvatarSelectionDialog(LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Select Avatar Character', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAvatarOption('male', 'Male', 'assets/avatars/male.png'),
                      const SizedBox(width: 16),
                      _buildAvatarOption('female', 'Female', 'assets/avatars/female.png'),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.blueAccent),
                ),
                title: Text('Upload Custom Photo', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.no_accounts_rounded, color: Colors.grey),
                ),
                title: Text('Reset to Default', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_avatar', 'none');
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default Icon Selected!'), backgroundColor: Colors.blue));
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildAvatarOption(String type, String label, String asset) {
  return GestureDetector(
    onTap: () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar', type);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label Avatar Selected!'), backgroundColor: Colors.green));
      }
    },
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.5), width: 2),
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage(asset),
            backgroundColor: Colors.transparent,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

  void _showEditFieldDialog(String title, String prefKey, String hint, LanguageProvider lang) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('cancel'))),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(prefKey, ctrl.text.trim());
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.t('updated_success')), backgroundColor: Colors.green));
                  }
                }
              },
              child: Text(lang.t('save')),
            ),
          ],
        );
      }
    );
  }

  void _showAccountSettingsSheet() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(lang.t('account_settings'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(leading: const Icon(Icons.edit), title: Text(lang.t('edit_profile')), onTap: () {
                Navigator.pop(context);
                _showEditFieldDialog(lang.t('edit_profile'), 'user', lang.t('enter_new_name'), lang);
              }),
              ListTile(leading: const Icon(Icons.email), title: Text(lang.t('email_change')), onTap: () {
                Navigator.pop(context);
                _showEditFieldDialog(lang.t('email_change'), 'email', lang.t('enter_new_email'), lang);
              }),
              ListTile(leading: const Icon(Icons.lock), title: Text(lang.t('change_password')), onTap: () {
                Navigator.pop(context);
                _showEditFieldDialog(lang.t('change_password'), 'password', lang.t('enter_new_password'), lang);
              }),
              const Divider(),
              ListTile(leading: const Icon(Icons.face_retouching_natural), title: const Text('Set Profile Avatar'), onTap: () {
                Navigator.pop(context);
                _showAvatarSelectionDialog(lang);
              }),
            ],
          ),
        );
      }
    );
  }

  void _showAccountInfoSheet() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user') ?? 'Guest';
    final email = prefs.getString('email') ?? 'Not Set';
    final installDate = prefs.getString('install_date') ?? 'Just now';
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Text(lang.t('account_info'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                const SizedBox(height: 20),
                _infoRow(lang.t('user_name'), name),
                _infoRow(lang.t('user_email'), email),
                _infoRow(lang.t('start_date'), installDate),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAboutAppSheet() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(lang.t('about_app'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(leading: const Icon(Icons.info), title: Text(lang.t('version_info')), subtitle: const Text('1.0.0'), onTap: () {}),
              ListTile(
                leading: const Icon(Icons.code), 
                title: Text(lang.t('dev_info')), 
                subtitle: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Developed by '),
                      TextSpan(text: 'Aman Prajapati', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' and '),
                      TextSpan(text: 'Saumya Gupta', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ), 
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Developer Info'),
                      content: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'This application has been successfully designed and developed by '),
                            TextSpan(text: 'Aman Prajapati', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: ' and '),
                            TextSpan(text: 'Saumya Gupta', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: ' as part of a software development project.\nThe main objective of this application is to deliver an efficient, reliable, and user-friendly solution.\n\nYour support and usage of this application are highly appreciated.'),
                          ],
                        ),
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                    ),
                  );
                }
              ),
              ListTile(leading: const Icon(Icons.description), title: Text(lang.t('terms_conditions')), onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()));
              }),
            ],
          ),
        );
      }
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildDelayedItem({required Widget child, required double delay}) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeIn)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic)),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    
    bool isDark = themeProvider.themeMode == ThemeMode.dark;
    String themeText = isDark ? lang.t('dark_mode') : lang.t('light_mode');

    Color bgColor = isDark ? const Color(0xFF0F0F0F) : Colors.grey.shade50;
    Color cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subTextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            iconTheme: IconThemeData(color: textColor),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                lang.t('settings'),
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                      : [Colors.white, Colors.grey.shade50],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDelayedItem(
                    delay: 0.1,
                    child: _buildSectionTitle(lang.t('general'), textColor),
                  ),
                  _buildDelayedItem(
                    delay: 0.2,
                    child: _buildSettingsContainer(
                      cardColor: cardColor,
                      isDark: isDark,
                      children: [
                        _buildListTile(lang.t('theme'), Icons.dark_mode_rounded, textColor, subTextColor, value: themeText, onTap: _showThemeDialog, color: Colors.blueAccent),
                        _buildDivider(isDark),
                        _buildListTile(lang.t('language'), Icons.language_rounded, textColor, subTextColor, value: lang.currentLanguage, onTap: _showLanguageDialog, color: Colors.greenAccent),
                        _buildDivider(isDark),
                        _buildListTile(lang.t('notifications'), Icons.notifications_active_rounded, textColor, subTextColor, onTap: _showNotificationsSheet, color: Colors.orangeAccent),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildDelayedItem(
                    delay: 0.3,
                    child: _buildSectionTitle(lang.t('account_security'), textColor),
                  ),
                  _buildDelayedItem(
                    delay: 0.4,
                    child: _buildSettingsContainer(
                      cardColor: cardColor,
                      isDark: isDark,
                      children: [
                        _buildListTile(lang.t('account_settings'), Icons.manage_accounts_rounded, textColor, subTextColor, onTap: _showAccountSettingsSheet, color: Colors.purpleAccent),
                        _buildDivider(isDark),
                        _buildListTile(lang.t('account_info'), Icons.badge_rounded, textColor, subTextColor, onTap: _showAccountInfoSheet, color: Colors.tealAccent),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildDelayedItem(
                    delay: 0.5,
                    child: _buildSectionTitle(lang.t('other'), textColor),
                  ),
                  _buildDelayedItem(
                    delay: 0.6,
                    child: _buildSettingsContainer(
                      cardColor: cardColor,
                      isDark: isDark,
                      children: [
                        _buildListTile(lang.t('history'), Icons.history_rounded, textColor, subTextColor, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                        }, color: Colors.amberAccent),
                        _buildDivider(isDark),
                        _buildListTile(lang.t('feedback'), Icons.rate_review_rounded, textColor, subTextColor, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
                        }, color: Colors.pinkAccent),
                        _buildDivider(isDark),
                        _buildListTile(lang.t('about_app'), Icons.help_center_rounded, textColor, subTextColor, onTap: _showAboutAppSheet, color: Colors.indigoAccent),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  _buildDelayedItem(
                    delay: 0.7,
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: cardColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text(lang.t('logout_confirm_title'), style: GoogleFonts.outfit(color: textColor, fontWeight: FontWeight.bold)),
                                content: Text(lang.t('logout_confirm_content'), style: GoogleFonts.outfit(color: subTextColor)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('cancel'), style: const TextStyle(color: Colors.grey))),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _logout();
                                    }, 
                                    child: Text(lang.t('logout'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
                                  ),
                                ],
                              )
                            );
                          },
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                          label: Text(lang.t('logout'), style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: Colors.redAccent.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          color: textColor.withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer({required Color cardColor, required List<Widget> children, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, Color textColor, Color subTextColor, {String? value, VoidCallback? onTap, required Color color}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null) 
              Text(
                value, 
                style: GoogleFonts.outfit(
                  color: subTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (value != null) const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subTextColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, indent: 56, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200);
  }
}
