import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _busy = false;
  bool _showEmail = false;

  Future<void> _signInGoogle() async {
    setState(() => _busy = true);
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      _err(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInEmail() async {
    if (_emailC.text.trim().isEmpty || _passC.text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _auth.signInWithEmail(_emailC.text.trim(), _passC.text);
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
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFEF4444)),
    );
  }

  @override
  void dispose() {
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
          const _AuthBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.vertical),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    _logo(),
                    const SizedBox(height: 16),
                    _brandText(),
                    const SizedBox(height: 14),
                    Text(
                      'Talk more. Connect deeper.\nBe you, with ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 15,
                          height: 1.5),
                    ),
                    const SizedBox(height: 36),
                    _googleButton(),
                    const SizedBox(height: 14),
                    if (!_showEmail)
                      TextButton(
                        onPressed: () => setState(() => _showEmail = true),
                        child: Text('Use email instead',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14)),
                      ),
                    if (_showEmail) ...[
                      const SizedBox(height: 6),
                      _glassField(
                          controller: _emailC,
                          hint: 'Email',
                          icon: Icons.alternate_email_rounded),
                      const SizedBox(height: 12),
                      _glassField(
                          controller: _passC,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: true),
                      const SizedBox(height: 18),
                      _gradientButton(
                          label: 'Sign In',
                          icon: Icons.arrow_forward_rounded,
                          onTap: _busy ? null : _signInEmail),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("New here? ",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6))),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen())),
                          child: ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                                .createShader(b),
                            child: const Text(
                              'Create account',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 12, color: Colors.white.withOpacity(0.4)),
                        const SizedBox(width: 5),
                        Text('Safe, secure & private',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
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

  Widget _logo() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.55),
              blurRadius: 60,
              spreadRadius: 6),
          BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.4),
              blurRadius: 80,
              spreadRadius: 2),
        ],
      ),
      child: Image.asset('assets/wechat_logo.png', fit: BoxFit.contain),
    );
  }

  Widget _brandText() {
    return ShaderMask(
      shaderCallback: (b) => const LinearGradient(
        colors: [Colors.white, Color(0xFFB794F6), Color(0xFFEC4899)],
      ).createShader(b),
      child: const Text(
        'WeChat',
        style: TextStyle(
          color: Colors.white,
          fontSize: 50,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          letterSpacing: -1,
        ),
      ),
    );
  }

  Widget _googleButton() {
    return _PillButton(
      onTap: _busy ? null : _signInGoogle,
      color: Colors.white,
      shadow: Colors.white.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          _GoogleG(),
          SizedBox(width: 12),
          Text(
            'Continue with Google',
            style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
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
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return _PillButton(
      onTap: onTap,
      gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
      shadow: const Color(0xFFEC4899).withOpacity(0.45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white, size: 18),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Color? shadow;
  const _PillButton({
    required this.child,
    this.onTap,
    this.color,
    this.gradient,
    this.shadow,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: shadow != null
            ? [BoxShadow(color: shadow!, blurRadius: 24, offset: const Offset(0, 10))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
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
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();
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
        const _Bubble(top: 80, left: 30, size: 60, color: Color(0xFF8B5CF6)),
        const _Bubble(top: 140, right: 40, size: 18, color: Color(0xFFEC4899)),
        const _Bubble(top: 260, right: 70, size: 26, color: Color(0xFF8B5CF6)),
        const _Bubble(bottom: 220, left: 20, size: 50, color: Color(0xFF8B5CF6)),
        const _Bubble(bottom: 120, right: 30, size: 40, color: Color(0xFFEC4899)),
        const _Bubble(bottom: 60, left: 60, size: 22, color: Color(0xFF60A5FA)),
        const _Sparkle(top: 110, right: 60),
        const _Sparkle(top: 320, left: 50),
        const _Sparkle(bottom: 280, right: 50),
        const _Sparkle(bottom: 80, left: 30),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  const _Bubble({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
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
}

class _Sparkle extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  const _Sparkle({this.top, this.bottom, this.left, this.right});
  @override
  Widget build(BuildContext context) {
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
