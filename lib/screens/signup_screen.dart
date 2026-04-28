import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _busy = false;

  Future<void> _signUp() async {
    final name = _nameC.text.trim();
    final email = _emailC.text.trim();
    final pass = _passC.text;
    if (name.isEmpty || email.isEmpty || pass.length < 6) {
      _err('Fill all fields. Password must be 6+ characters.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _auth.signUpWithEmail(email, pass, name);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _err(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signUpGoogle() async {
    setState(() => _busy = true);
    try {
      await _auth.signInWithGoogle();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _err(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _err(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e is String ? e : e.toString().replaceAll('Exception: ', '')),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0717),
      body: Stack(
        children: [
          const _AuthBg(),
          SafeArea(
            child: Column(
              children: [
                _topBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _avatarPlaceholder(),
                        const SizedBox(height: 22),
                        const Text('All set! 🎉',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text("Let's complete your profile",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          'Add a few details to help your friends find you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5), fontSize: 13),
                        ),
                        const SizedBox(height: 26),
                        _field(
                            controller: _nameC,
                            hint: 'Your name',
                            icon: Icons.person_outline_rounded,
                            showClear: true),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            'This is how your name will appear to others on WeChat.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _field(
                            controller: _emailC,
                            hint: 'Email',
                            icon: Icons.alternate_email_rounded),
                        const SizedBox(height: 12),
                        _field(
                            controller: _passC,
                            hint: 'Password (min 6 chars)',
                            icon: Icons.lock_outline_rounded,
                            obscure: true),
                        const SizedBox(height: 24),
                        _startButton(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.1))),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 13)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: Colors.white.withOpacity(0.1))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _googleButton(),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6))),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: ShaderMask(
                                shaderCallback: (b) => const LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                ).createShader(b),
                                child: const Text('Log in',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'By continuing, you agree to our Terms of Service & Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_busy)
            Container(
              color: Colors.black.withOpacity(0.4),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Color(0xFFEC4899)),
            ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Skip',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 4),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(Icons.person_rounded,
                size: 56, color: Colors.white.withOpacity(0.6)),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                border: Border.all(color: const Color(0xFF0A0717), width: 2.5),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          Positioned(
            top: -6,
            left: 30,
            child: Transform.rotate(
              angle: -0.4,
              child: const Text('👑', style: TextStyle(fontSize: 28)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool showClear = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => showClear ? setState(() {}) : null,
        decoration: InputDecoration(
          prefixIcon:
              Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
          suffixIcon: showClear && controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.cancel,
                      color: Colors.white.withOpacity(0.4), size: 18),
                  onPressed: () {
                    controller.clear();
                    setState(() {});
                  },
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _startButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: _busy ? null : _signUp,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Start WeChat',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 20),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: _busy ? null : _signUpGoogle,
          child: SizedBox(
            height: 54,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [
                      Color(0xFF4285F4),
                      Color(0xFF34A853),
                      Color(0xFFFBBC05),
                      Color(0xFFEA4335),
                    ],
                    stops: [0.0, 0.4, 0.7, 1.0],
                  ).createShader(b),
                  child: const Text('G',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1)),
                ),
                const SizedBox(width: 12),
                const Text('Sign up with Google',
                    style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBg extends StatelessWidget {
  const _AuthBg();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A0B2E), Color(0xFF0A0717)],
            ),
          ),
        ),
        _bubble(top: 80, left: 30, size: 50, color: const Color(0xFF8B5CF6)),
        _bubble(top: 130, right: 40, size: 16, color: const Color(0xFFEC4899)),
        _bubble(top: 220, left: 60, size: 22, color: const Color(0xFF60A5FA)),
        _bubble(bottom: 200, right: 30, size: 38, color: const Color(0xFF8B5CF6)),
        _bubble(bottom: 80, left: 30, size: 28, color: const Color(0xFFEC4899)),
        _spark(top: 100, right: 80),
        _spark(top: 280, left: 40),
        _spark(bottom: 240, right: 70),
      ],
    );
  }

  Widget _bubble({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(0.55), color.withOpacity(0.0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _spark({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: Icon(Icons.auto_awesome,
            color: Colors.white.withOpacity(0.5), size: 14),
      ),
    );
  }
}
