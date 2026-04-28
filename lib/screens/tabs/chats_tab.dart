import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import '../../models/app_user.dart';
import '../chat_screen.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final chatSvc = ChatService();

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Chats',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatSvc.watchMyChats(me.uid),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats = snap.data!;
                if (chats.isEmpty) {
                  return Center(
                    child: Text(
                      'No chats yet.\nGo to Friends and start one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chats.length,
                  itemBuilder: (_, i) {
                    final c = chats[i];
                    final otherUid =
                        (c['participants'] as List).firstWhere((p) => p != me.uid);
                    return _chatTile(context, otherUid, c);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatTile(BuildContext context, String otherUid, Map<String, dynamic> c) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUid).get(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox(height: 70);
        final other = AppUser.fromMap(snap.data!.data() ?? {'uid': otherUid});
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              ),
              child: Center(
                child: Text(
                  other.displayName.isNotEmpty
                      ? other.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            ),
            title: Text(other.displayName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(
              c['lastMessage'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => ChatScreen(other: other))),
          ),
        );
      },
    );
  }
}
