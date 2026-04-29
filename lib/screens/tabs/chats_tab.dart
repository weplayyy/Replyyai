import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import '../../models/app_user.dart';
import '../chat_screen.dart';
import 'friends_tab.dart';

class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final chatSvc = ChatService();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _topBar(context),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatSvc.watchMyChats(me.uid),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Could not load chats.\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70)),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats = snap.data!;
                return ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _storiesRow(context, chats, me.uid),
                    const SizedBox(height: 8),
                    if (chats.isEmpty)
                      _emptyState(context)
                    else
                      _chatsList(context, chats, me.uid),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.5),
                    blurRadius: 14,
                    spreadRadius: 1),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset('assets/wechat_logo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Chats',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12),
                    children: [
                      TextSpan(
                          text: 'Talk more. ',
                          style: TextStyle(color: Colors.white60)),
                      TextSpan(
                          text: 'Connect deeper.',
                          style: TextStyle(
                              color: Color(0xFFB794F6),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon')),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const _PickFriendPage())),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storiesRow(
      BuildContext context, List<Map<String, dynamic>> chats, String myUid) {
    final recentOtherUids = <String>[];
    for (final c in chats) {
      final ps = c['participants'] as List?;
      if (ps == null) continue;
      final other = ps.firstWhere((p) => p != myUid, orElse: () => null);
      if (other != null && !recentOtherUids.contains(other)) {
        recentOtherUids.add(other as String);
      }
      if (recentOtherUids.length >= 12) break;
    }
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _createRoomPill(context),
          for (final uid in recentOtherUids) _storyAvatar(context, uid),
        ],
      ),
    );
  }

  Widget _createRoomPill(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rooms coming soon')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: const Color(0xFF8B5CF6).withOpacity(0.4),
                        width: 1.2),
                  ),
                  alignment: Alignment.center,
                  child: const Text('😊', style: TextStyle(fontSize: 26)),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                      border: Border.all(
                          color: const Color(0xFF0F0A1F), width: 2),
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const SizedBox(
              width: 64,
              child: Text(
                'Create\nRoom',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyAvatar(BuildContext context, String uid) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox(width: 70);
        final u = AppUser.fromMap(snap.data!.data() ?? {'uid': uid});
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChatScreen(other: u))),
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0F0A1F),
                    ),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        u.displayName.isNotEmpty
                            ? u.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 64,
                  child: Text(
                    u.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, height: 1.15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chatsList(
      BuildContext context, List<Map<String, dynamic>> chats, String myUid) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < chats.length; i++) ...[
            _chatTile(context, chats[i], myUid),
            if (i != chats.length - 1)
              Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 76,
                  endIndent: 16,
                  color: Colors.white.withOpacity(0.06)),
          ],
        ],
      ),
    );
  }

  Widget _chatTile(
      BuildContext context, Map<String, dynamic> c, String myUid) {
    final ps = (c['participants'] as List?) ?? [];
    final otherUid = ps.firstWhere((p) => p != myUid, orElse: () => '');
    if (otherUid == '') return const SizedBox.shrink();

    final lastMsg = c['lastMessage'] as String? ?? '';
    final lastSenderId = c['lastSenderId'] as String?;
    final ts = c['lastMessageAt'] as Timestamp?;
    final isMine = lastSenderId == myUid;
    final unread = !isMine && ts != null;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(otherUid)
          .get(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox(height: 70);
        final u = AppUser.fromMap(snap.data!.data() ?? {'uid': otherUid});
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ChatScreen(other: u))),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          u.displayName.isNotEmpty
                              ? u.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF14092B), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(
                          isMine ? 'You: $lastMsg' : lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: unread
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.55),
                              fontSize: 13,
                              fontWeight: unread
                                  ? FontWeight.w500
                                  : FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_timeLabel(ts),
                          style: TextStyle(
                              color: unread
                                  ? const Color(0xFFB794F6)
                                  : Colors.white.withOpacity(0.45),
                              fontSize: 11,
                              fontWeight: unread
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                      const SizedBox(height: 6),
                      if (unread)
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                          ),
                          alignment: Alignment.center,
                          child: const Text('•',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  height: 0.6)),
                        )
                      else
                        const SizedBox(height: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _timeLabel(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) {
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final m = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ap';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2),
              ],
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: Colors.white, size: 38),
          ),
          const SizedBox(height: 16),
          const Text('No chats yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Tap + to start a conversation',
              style: TextStyle(color: Colors.white.withOpacity(0.55))),
        ],
      ),
    );
  }
}

class _PickFriendPage extends StatelessWidget {
  const _PickFriendPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0B2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Start a Chat',
            style: TextStyle(color: Colors.white)),
      ),
      body: const FriendsTab(),
    );
  }
}
