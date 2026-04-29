import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = true;
  bool _showOnline = true;

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0B2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Account'),
          _tile(Icons.email_outlined, 'Email', subtitle: me?.email ?? '—'),
          _tile(Icons.fingerprint, 'User ID',
              subtitle: me?.uid.substring(0, 12) ?? '—'),
          const SizedBox(height: 18),
          _section('Preferences'),
          _switchTile(Icons.notifications_outlined, 'Notifications',
              _notifications, (v) => setState(() => _notifications = v)),
          _switchTile(Icons.dark_mode_outlined, 'Dark mode', _darkMode,
              (v) => setState(() => _darkMode = v)),
          _switchTile(Icons.circle_outlined, 'Show online status',
              _showOnline, (v) => setState(() => _showOnline = v)),
          const SizedBox(height: 18),
          _section('Privacy & Support'),
          _tile(Icons.lock_outline, 'Privacy policy',
              onTap: () => _info(context, 'Privacy',
                  'We respect your privacy. Your data stays yours. 💜')),
          _tile(Icons.shield_outlined, 'Blocked users',
              onTap: () => _info(context, 'Blocked', 'No blocked users yet.')),
          _tile(Icons.help_outline, 'Help & support',
              onTap: () => _info(context, 'Need help?',
                  'Reach us at support@wechat.app — we\'re here for you.')),
          _tile(Icons.info_outline, 'About',
              subtitle: 'WeChat v1.0.0',
              onTap: () => _info(context, 'About WeChat',
                  'Talk more. Connect deeper.\nMade with 💜')),
          const SizedBox(height: 24),
          _signOutButton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFB794F6),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      );

  Widget _tile(IconData icon, String title,
      {String? subtitle, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFB794F6)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle,
                style: TextStyle(color: Colors.white.withOpacity(0.55))),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }

  Widget _switchTile(
      IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFFB794F6)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        value: value,
        activeColor: const Color(0xFFEC4899),
        onChanged: onChanged,
      ),
    );
  }

  Widget _signOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
          foregroundColor: const Color(0xFFEF4444),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
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
          if (confirm == true) {
            await AuthService().signOut();
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Sign out',
            style: TextStyle(fontWeight: FontWeight.w600)),
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
