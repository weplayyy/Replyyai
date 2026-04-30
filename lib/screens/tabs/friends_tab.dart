import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../models/app_user.dart';
import '../../widgets/rank_badge.dart';
import '../chat_screen.dart';

class FriendsTab extends StatelessWidget {
  const FriendsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final users = UserService();

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Find Friends',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: users.watchAllUsersExcept(me.uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                        'No other users yet.\nInvite a friend to sign up!',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.white.withOpacity(0.6))),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _userTile(context, list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _userTile(BuildContext context, AppUser u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: _avatar(u),
        title: Text(u.displayName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(Icons.favorite,
                  size: 12, color: Color(0xFFEC4899)),
              const SizedBox(width: 4),
              Text('${u.charms}',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12)),
              const SizedBox(width: 8),
              Flexible(
                child: RankBadge(
                    charms: u.charms, scale: 0.85, showName: false),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chat_bubble_outline,
            color: Color(0xFFEC4899)),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ChatScreen(other: u))),
      ),
    );
  }

  Widget _avatar(AppUser u) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
      ),
      child: Center(
        child: Text(
          u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
      ),
    );
  }
}
