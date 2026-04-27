import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import 'main_layout.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';
  bool _obscureText = true;
  bool _rememberMe = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1200)
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController, 
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut)
      )
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animController, 
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)
      )
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController, 
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)
      )
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    final res = await ApiService.login(_emailCtrl.text.trim(), _passwordCtrl.text);

    setState(() => _loading = false);

    if (res['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', res['user']['Name'] ?? 'Chef');
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (c) => const MainLayout()),
          (r) => false,
        );
      }
    } else {
      setState(() => _error = res['message'] ?? 'Invalid credentials');
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', account.displayName ?? 'Google User');
        await prefs.setString('email', account.email);
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (c) => const MainLayout()), 
            (r) => false,
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Google Sign-In failed: $error'),
             backgroundColor: Colors.red.shade400,
           ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFAEAE), Color(0xFFFF85B3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, spreadRadius: 5),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Logo
                          ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF4E3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.restaurant, size: 40, color: Colors.orangeAccent),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildAnimatedItem(
                            delay: 0.3,
                            child: const Text(
                              'Welcome Back', 
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF333333))
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildAnimatedItem(
                            delay: 0.4,
                            child: Text(
                              'Login to your CookSmart account', 
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)
                            ),
                          ),
                          const SizedBox(height: 28),
                          
                          if (_error.isNotEmpty)
                            _buildAnimatedItem(
                              delay: 0.0,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade800, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_error, style: TextStyle(color: Colors.red.shade800, fontSize: 13))),
                                  ],
                                ),
                              ),
                            ),

                          // Staggered Fields
                          _buildAnimatedItem(
                            delay: 0.5,
                            child: _buildTextField(
                              controller: _emailCtrl, 
                              label: 'Email Address', 
                              icon: Icons.mail_outline, 
                              obscure: false
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildAnimatedItem(
                            delay: 0.6,
                            child: _buildTextField(
                              controller: _passwordCtrl, 
                              label: 'Password', 
                              icon: Icons.lock_outline, 
                              obscure: _obscureText,
                              isPassword: true,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          _buildAnimatedItem(
                            delay: 0.7,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe, 
                                        onChanged: (val) {
                                          setState(() => _rememberMe = val ?? false);
                                        },
                                        activeColor: Colors.orange,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        side: BorderSide(color: Colors.grey.shade400),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Remember Me', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Forgot Password?', style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          _buildAnimatedItem(
                            delay: 0.8,
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: _loading 
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                      : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          _buildAnimatedItem(
                            delay: 0.9,
                            child: TextButton(
                              onPressed: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('user', 'Guest');
                                if (mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (c) => const MainLayout()), (r) => false,
                                  );
                                }
                              },
                              child: Text('Continue as Guest', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                            ),
                          ),
                          
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(color: Color(0xFFEEEEEE)),
                          ),
                          
                          _buildAnimatedItem(
                            delay: 1.0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                                  },
                                  child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          _buildAnimatedItem(
                            delay: 1.1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialButton(
                                  iconWidget: Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) => const FaIcon(FontAwesomeIcons.google, color: Colors.red, size: 20),
                                  ),
                                  onPressed: _loading ? null : _handleGoogleLogin,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedItem({required double delay, required Widget child}) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeIn),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(delay.clamp(0.0, 0.99), (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    required bool obscure,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
        prefixIcon: Icon(icon, color: Colors.orange.shade300, size: 20),
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
      ),
    );
  }
  
  Widget _buildSocialButton({required Widget iconWidget, required VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: IconButton(
        icon: iconWidget,
        onPressed: onPressed,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
