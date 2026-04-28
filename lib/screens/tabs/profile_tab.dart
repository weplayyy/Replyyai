import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/app_user.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    return SafeArea(
      child: StreamBuilder<AppUser>(
        stream: UserService().watchUser(me.uid),
        builder: (context, snap) {
          final u = snap.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topBar(),
                const SizedBox(height: 16),
                _profileCard(context, u),
                const SizedBox(height: 14),
                _quickActions(),
                const SizedBox(height: 14),
                _menuList(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Colors.white, Color(0xFFB794F6), Color(0xFFEC4899)],
            ).createShader(b),
            child: const Text(
              'WeChat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Row(
            children: [
              _circleIconBtn(Icons.qr_code_scanner_rounded),
              const SizedBox(width: 10),
              _circleIconBtn(Icons.settings_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _profileCard(BuildContext context, AppUser? u) {
    final name = u?.displayName ?? '...';
    final username = u?.username ?? '';
    final bio = u?.bio ?? 'Talk more, Worry less.';
    final level = u?.level ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF7C3AED)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF60A5FA), width: 2.5),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF4C1D95), width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Color(0xFF60A5FA), size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: '@$username'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Username copied')),
                        );
                      },
                      child: Row(
                        children: [
                          Text('@$username',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7), fontSize: 13)),
                          const SizedBox(width: 4),
                          Icon(Icons.copy_rounded,
                              size: 13, color: Colors.white.withOpacity(0.7)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: Color(0xFF60A5FA), size: 16),
                    const SizedBox(width: 2),
                    Text('Lv.$level',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(bio,
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined,
                      size: 13, color: Colors.white.withOpacity(0.8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _stat('${u?.friendsCount ?? 0}', 'Friends'),
                _statDivider(),
                _stat(_fmt(u?.momentsCount ?? 0), 'Moments'),
                _statDivider(),
                _stat(_fmt(u?.visitorsCount ?? 0), 'Visitors'),
                _statDivider(),
                _stat('${u?.followingCount ?? 0}', 'Following'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _stat(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(val,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 24,
        color: Colors.white.withOpacity(0.15),
      );

  Widget _quickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _action(Icons.diamond_rounded, 'VIP Center',
              const [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
          _action(Icons.shopping_bag_rounded, 'Shop',
              const [Color(0xFFEC4899), Color(0xFFF472B6)]),
          _action(Icons.chat_bubble_rounded, 'Show',
              const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              badge: 'New'),
          _action(Icons.home_rounded, 'My Home',
              const [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, List<Color> colors, {String? badge}) {
    return Expanded(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors),
                  boxShadow: [
                    BoxShadow(
                        color: colors.first.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badge,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _menuList(BuildContext context) {
    final items = [
      (Icons.emoji_emotions_rounded, 'Moments',
          const [Color(0xFF8B5CF6), Color(0xFFA78BFA)], null),
      (Icons.bar_chart_rounded, 'Stats',
          const [Color(0xFF22C55E), Color(0xFF4ADE80)], null),
      (Icons.visibility_rounded, 'Visitors',
          const [Color(0xFF06B6D4), Color(0xFF22D3EE)], null),
      (Icons.person_add_rounded, 'Invite Friends',
          const [Color(0xFFF97316), Color(0xFFFB923C)], null),
      (Icons.shield_rounded, 'Badge',
          const [Color(0xFFEF4444), Color(0xFFF87171)], null),
      (Icons.card_giftcard_rounded, 'Contributions',
          const [Color(0xFF8B5CF6), Color(0xFFEC4899)], null),
      (Icons.language_rounded, 'Language',
          const [Color(0xFF3B82F6), Color(0xFF60A5FA)], 'English'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _menuRow(items[i].$1, items[i].$2, items[i].$3, items[i].$4),
            if (i != items.length - 1)
              Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 64,
                  color: Colors.white.withOpacity(0.06)),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.08),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => AuthService().signOut(),
                child: const Text('Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(IconData icon, String label, List<Color> colors, String? trailingText) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: colors),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4)),
        ],
      ),
      onTap: () {},
    );
  }
}
