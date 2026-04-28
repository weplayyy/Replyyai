import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFEC4899).withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 4),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (u?.displayName.isNotEmpty ?? false)
                            ? u!.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 44),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(u?.displayName ?? 'Loading…',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text('ID: ${u?.uid.substring(0, 8) ?? ''}',
                      style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _stat('Level', '${u?.level ?? 1}', const Color(0xFF8B5CF6)),
                    const SizedBox(width: 12),
                    _stat('Charms', '${u?.charms ?? 0}', const Color(0xFFEC4899)),
                    const SizedBox(width: 12),
                    _stat('Coins', '${u?.coins ?? 0}', const Color(0xFFFBBF24)),
                  ],
                ),
                const SizedBox(height: 32),
                _menuItem(Icons.diamond_outlined, 'Top Up Coins', () {}),
                _menuItem(Icons.favorite_border, 'My CP (Couple Pair)', () {}),
                _menuItem(Icons.workspace_premium_outlined, 'Rings', () {}),
                _menuItem(Icons.settings_outlined, 'Settings', () {}),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.08),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => AuthService().signOut(),
                  child: const Text('Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stat(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(val,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFEC4899)),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
