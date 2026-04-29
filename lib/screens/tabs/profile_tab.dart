import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../models/app_user.dart';
import '../extras/settings_screen.dart';
import '../extras/edit_profile_screen.dart';
import '../extras/shop_screen.dart';
import '../extras/moments_screen.dart';
import '../extras/visitors_screen.dart';

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
                _topBar(context),
                const SizedBox(height: 16),
                _profileCard(context, u),
                const SizedBox(height: 14),
                _quickActions(context),
                const SizedBox(height: 14),
                _menuList(context, u),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- TOP BAR ----------
  Widget _topBar(BuildContext context) {
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
              GestureDetector(
                onTap: () => _showQrSheet(context),
                child: _circleIconBtn(Icons.qr_code_scanner_rounded),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen())),
                child: _circleIconBtn(Icons.settings_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleIconBtn(IconData icon) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      );

  // ---------- PROFILE CARD ----------
  Widget _profileCard(BuildContext context, AppUser? u) {
    final name = u?.displayName ?? '...';
    final username = u?.username ?? '';
    final bio = u?.bio ?? 'Talk more, Worry less.';
    final level = u?.level ?? 1;

    return GestureDetector(
      onTap: () {
        if (u != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: u)));
        }
      },
      child: Container(
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
                Stack(children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF60A5FA), width: 2.5),
                      gradient: const LinearGradient(colors: [
                        Color(0xFFEC4899),
                        Color(0xFF8B5CF6),
                      ]),
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
                        border: Border.all(
                            color: const Color(0xFF4C1D95), width: 2.5),
                      ),
                    ),
                  ),
                ]),
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
                          if (u?.isVerified == true)
                            const Icon(Icons.verified,
                                color: Color(0xFF60A5FA), size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: '@$username'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Username copied')),
                          );
                        },
                        child: Row(
                          children: [
                            Text('@$username',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13)),
                            const SizedBox(width: 4),
                            Icon(Icons.copy_rounded,
                                size: 13,
                                color: Colors.white.withOpacity(0.7)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showLevelInfo(context, u),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
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
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _editBio(context, u),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(bio,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.edit_outlined,
                          size: 13, color: Colors.white.withOpacity(0.8)),
                    ],
                  ),
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
                  _stat(context, '${u?.friendsCount ?? 0}', 'Friends',
                      () => _info(context, '👥 Friends',
                          'You have ${u?.friendsCount ?? 0} friends.')),
                  _statDivider(),
                  _stat(context, _fmt(u?.momentsCount ?? 0), 'Moments',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MomentsScreen()))),
                  _statDivider(),
                  _stat(context, _fmt(u?.visitorsCount ?? 0), 'Visitors',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VisitorsScreen()))),
                  _statDivider(),
                  _stat(context, '${u?.followingCount ?? 0}', 'Following',
                      () => _info(context, '➕ Following',
                          'You\'re following ${u?.followingCount ?? 0} people.')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _stat(
      BuildContext context, String val, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(val,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 24,
        color: Colors.white.withOpacity(0.15),
      );

  // ---------- QUICK ACTIONS ----------
  Widget _quickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _action(Icons.diamond_rounded, 'VIP Center',
              const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
              onTap: () => _comingSoon(context, '💎 VIP Center',
                  'Premium perks unlock here soon. Stay tuned!')),
          _action(Icons.shopping_bag_rounded, 'Shop',
              const [Color(0xFFEC4899), Color(0xFFF472B6)],
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShopScreen()))),
          _action(Icons.chat_bubble_rounded, 'Show',
              const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              badge: 'New',
              onTap: () => _comingSoon(context, '💬 Show',
                  'Live shows are coming. Get ready to perform!')),
          _action(Icons.home_rounded, 'My Home',
              const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              onTap: () => _comingSoon(context, '🏠 My Home',
                  'Your personal space is being designed with love.')),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, List<Color> colors,
      {String? badge, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(clipBehavior: Clip.none, children: [
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
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
            ]),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ---------- MENU LIST ----------
  Widget _menuList(BuildContext context, AppUser? u) {
    final items = <_MenuItem>[
      _MenuItem(Icons.emoji_emotions_rounded, 'Moments',
          const [Color(0xFF8B5CF6), Color(0xFFA78BFA)], null,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MomentsScreen()))),
      _MenuItem(Icons.bar_chart_rounded, 'Stats',
          const [Color(0xFF22C55E), Color(0xFF4ADE80)], null,
          () => _showStats(context, u)),
      _MenuItem(Icons.visibility_rounded, 'Visitors',
          const [Color(0xFF06B6D4), Color(0xFF22D3EE)], null,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const VisitorsScreen()))),
      _MenuItem(Icons.person_add_rounded, 'Invite Friends',
          const [Color(0xFFF97316), Color(0xFFFB923C)], null,
          () => _invite(context, u)),
      _MenuItem(Icons.shield_rounded, 'Badge',
          const [Color(0xFFEF4444), Color(0xFFF87171)], null,
          () => _showBadges(context, u)),
      _MenuItem(Icons.card_giftcard_rounded, 'Contributions',
          const [Color(0xFF8B5CF6), Color(0xFFEC4899)], null,
          () => _showContributions(context, u)),
      _MenuItem(Icons.language_rounded, 'Language',
          const [Color(0xFF3B82F6), Color(0xFF60A5FA)], 'English',
          () => _pickLanguage(context)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _menuRow(items[i]),
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
                onPressed: () => _confirmSignOut(context),
                child: const Text('Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuRow(_MenuItem item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: item.colors),
        ),
        child: Icon(item.icon, color: Colors.white, size: 20),
      ),
      title: Text(item.label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.trailing != null)
            Text(item.trailing!,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4)),
        ],
      ),
      onTap: item.onTap,
    );
  }

  // ---------- DIALOGS / SHEETS ----------
  void _showQrSheet(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your WeChat ID',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2,
                        size: 140, color: Colors.black),
                    const SizedBox(height: 8),
                    Text(me?.uid.substring(0, 12) ?? '',
                        style: const TextStyle(
                            color: Colors.black54,
                            fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Share your ID for friends to find you',
                  style: TextStyle(color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: me?.uid ?? ''));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ID copied to clipboard')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text('Copy ID',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLevelInfo(BuildContext context, AppUser? u) {
    final charms = u?.charms ?? 0;
    final level = u?.level ?? 1;
    final nextLevelAt = level * 1000;
    final progress = (charms / nextLevelAt).clamp(0.0, 1.0);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: Color(0xFF60A5FA), size: 28),
                  const SizedBox(width: 8),
                  Text('Level $level',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white12,
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFFEC4899)),
                ),
              ),
              const SizedBox(height: 8),
              Text('$charms / $nextLevelAt charms to level ${level + 1}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),
              const Text(
                'Earn charms when friends send you gifts. Higher levels unlock new badges & perks. 💜',
                style: TextStyle(color: Colors.white60, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editBio(BuildContext context, AppUser? u) async {
    if (u == null) return;
    final controller = TextEditingController(text: u.bio);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0B2E),
        title: const Text('Edit bio',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Say something about yourself...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            border: const OutlineInputBorder(),
            enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF8B5CF6))),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Save',
                  style: TextStyle(
                      color: Color(0xFFEC4899),
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (result == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .update({'bio': result.isEmpty ? 'Talk more, Worry less.' : result});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color(0xFF8B5CF6),
        content: Text('Bio updated 💜'),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    }
  }

  void _showStats(BuildContext context, AppUser? u) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Stats',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _statRow('💜 Charms', '${u?.charms ?? 0}'),
              _statRow('🪙 Coins', '${u?.coins ?? 0}'),
              _statRow('⚡ Level', '${u?.level ?? 1}'),
              _statRow('👥 Friends', '${u?.friendsCount ?? 0}'),
              _statRow('📸 Moments', '${u?.momentsCount ?? 0}'),
              _statRow('👁️ Visitors', '${u?.visitorsCount ?? 0}'),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showBadges(BuildContext context, AppUser? u) {
    final earned = (u?.charms ?? 0) > 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Badges',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _badge('🔰', 'Newcomer', 'Joined WeChat', true),
              _badge('💜', 'First Charm', 'Earn your first charm', earned),
              _badge('🔥', 'Streak 7', 'Chat 7 days in a row', false),
              _badge('🏆', 'Top 100', 'Reach the leaderboard', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String icon, String name, String desc, bool earned) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Opacity(
        opacity: earned ? 1.0 : 0.4,
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text(desc,
                      style:
                          const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            if (earned)
              const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
          ],
        ),
      ),
    );
  }

  void _showContributions(BuildContext context, AppUser? u) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Contributions',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _statRow('🎁 Gifts received', '${u?.charms ?? 0} charms'),
              _statRow('🪙 Coins available', '${u?.coins ?? 0}'),
              const SizedBox(height: 12),
              const Text(
                'Send gifts to friends to climb their leaderboards 💜',
                style: TextStyle(color: Colors.white60, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context) async {
    const langs = ['English', 'हिंदी', 'Español', 'Français', '中文'];
    final pick = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0B2E),
        title: const Text('Choose language',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in langs)
              ListTile(
                title:
                    Text(l, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, l),
              ),
          ],
        ),
      ),
    );
    if (pick == null) return;
    final me = FirebaseAuth.instance.currentUser;
    if (me != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(me.uid)
            .update({'language': pick});
      } catch (_) {}
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Language set to $pick')),
    );
  }

  void _invite(BuildContext context, AppUser? u) {
    final code = u?.username.isNotEmpty == true
        ? u!.username
        : (u?.uid.substring(0, 6) ?? '');
    final inviteText =
        'Hey! Join me on WeChat 💜 Use my code: $code';
    Clipboard.setData(ClipboardData(text: inviteText));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      backgroundColor: Color(0xFF8B5CF6),
      content: Text('Invite copied! Paste it anywhere to share.'),
    ));
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0B2E),
        title: const Text('Sign out?',
            style: TextStyle(color: Colors.white)),
        content: const Text('You can sign back in any time.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out',
                  style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (confirm == true) await AuthService().signOut();
  }

  void _comingSoon(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(body,
                  style: const TextStyle(
                      color: Colors.white70, height: 1.5)),
              const SizedBox(height: 8),
              const Text('Coming soon ✨',
                  style: TextStyle(
                      color: Color(0xFFB794F6),
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _info(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0B2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body,
            style: const TextStyle(color: Colors.white70, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: Color(0xFFB794F6))),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final String? trailing;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label, this.colors, this.trailing, this.onTap);
}
