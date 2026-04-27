import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'main_layout.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';
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
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    final res = await ApiService.signup(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text);

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
      setState(() => _error = res['message'] ?? 'Signup failed');
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
                colors: [Color(0xFF84fab0), Color(0xFF8fd3f4)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ScaleTransition(
                                scale: _logoScaleAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person_add_alt_1, size: 50, color: Colors.green),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildAnimatedItem(
                                delay: 0.3,
                                child: const Text('Join CookSmart', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87)),
                              ),
                              const SizedBox(height: 8),
                              _buildAnimatedItem(
                                delay: 0.4,
                                child: Text('Create an account to save recipes!', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                              ),
                              const SizedBox(height: 32),
                              
                              if (_error.isNotEmpty)
                                _buildAnimatedItem(
                                  delay: 0.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.red.shade800, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(_error, style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  ),
                                ),

                              _buildAnimatedItem(
                                delay: 0.5,
                                child: _buildTextField(_nameCtrl, 'Full Name', Icons.person_outline, false),
                              ),
                              const SizedBox(height: 16),
                              _buildAnimatedItem(
                                delay: 0.6,
                                child: _buildTextField(_emailCtrl, 'Email Address', Icons.email_outlined, false),
                              ),
                              const SizedBox(height: 16),
                              _buildAnimatedItem(
                                delay: 0.7,
                                child: _buildTextField(_passwordCtrl, 'Password', Icons.lock_outline, true),
                              ),
                              const SizedBox(height: 32),
                              
                              _buildAnimatedItem(
                                delay: 0.8,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _handleSignup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: Colors.greenAccent.withOpacity(0.5),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: _loading 
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                      : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
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
                                  child: const Text('Continue as Guest', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildAnimatedItem(
                                delay: 1.0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Already have an account? ", style: TextStyle(color: Colors.grey.shade700)),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                      },
                                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
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

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, bool obscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 2)),
      ),
    );
  }
}
