import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (_emailC.text.isEmpty || _passC.text.isEmpty) {
      _showSnack('Please fill in both fields');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.signInWithEmail(_emailC.text.trim(), _passC.text);
    } catch (e) {
      _showSnack('Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      _showSnack('Google sign-in failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A0B2E), Color(0xFF0F0A1F), Color(0xFF2D0F3D)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withOpacity(0.5),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue chatting',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _glassField(controller: _emailC, hint: 'Email', icon: Icons.email_outlined),
                  const SizedBox(height: 14),
                  _glassField(
                    controller: _passC,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _gradientButton(text: 'Sign In', onPressed: _login),
                  const SizedBox(height: 22),
                  Row(children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or continue with',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                  ]),
                  const SizedBox(height: 22),
                  _googleButton(_google),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: const Text('Sign Up',
                            style: TextStyle(
                                color: Color(0xFFEC4899), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          prefixIcon: Icon(icon, color: Colors.white54),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        ),
      ),
    );
  }

  Widget _gradientButton({required String text, required VoidCallback onPressed}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _loading ? null : onPressed,
          child: Center(
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }

  Widget _googleButton(VoidCallback onPressed) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _loading ? null : onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('G',
                      style: TextStyle(
                          color: Color(0xFF4285F4),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Continue with Google',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
