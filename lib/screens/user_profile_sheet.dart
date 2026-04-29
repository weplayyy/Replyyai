import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/gift.dart';
import '../services/user_service.dart';
import '../services/gift_service.dart';
import 'gift_picker.dart';
import 'chat_screen.dart';

/// Show a user's mini-profile as a bottom sheet.
/// If [roomId] is provided, gifts are broadcast in that room feed.
/// If null, gifts go through the normal 1:1 chat flow.
Future<void> showUserProfileSheet(
  BuildContext context, {
  required String uid,
  String? roomId,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _UserProfileSheet(uid: uid, roomId: roomId),
  );
}

class _UserProfileSheet extends StatelessWidget {
  final String uid;
  final String? roomId;
  const _UserProfileSheet({required this.uid, this.roomId});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final isMe = me.uid == uid;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A0B2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: StreamBuilder<AppUser>(
          stream: UserService().watchUser(uid),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final u = snap.data!;
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _grabber(),
                const SizedBox(height: 14),
                _header(u),
                const SizedBox(height: 16),
                _idRow(context, u),
                const SizedBox(height: 14),
                _statsRow(u),
                const SizedBox(height: 14),
                _miniCounts(u),
                const SizedBox(height: 16),
                _bioCard(u),
                const SizedBox(height: 18),
                if (!isMe) _actions(context, u),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _grabber() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header(AppUser u) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
            ),
          ),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white12,
            backgroundImage: (u.photoURL ?? '').isNotEmpty
                ? NetworkImage(u.photoURL!)
                : null,
            child: (u.photoURL ?? '').isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 32)
                : null,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      u.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (u.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        color: Color(0xFF8B5CF6), size: 18),
                  ],
                ],
              ),
              if (u.username.isNotEmpty)
                Text('@${u.username}',
                    style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: u.isOnline
                        ? const Color(0xFF22C55E)
                        : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(u.isOnline ? 'Online now' : 'Offline',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _idRow(BuildContext context, AppUser u) {
    final shortId = u.uid.length > 8 ? u.uid.substring(0, 8) : u.uid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined,
              color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Text('ID: $shortId',
              style: const TextStyle(color: Colors.white, fontSize: 13)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: u.uid));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID copied')),
              );
            },
            child: const Icon(Icons.copy, color: Colors.white54, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(AppUser u) {
    Widget cell(String label, String value, List<Color> grad) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: grad.map((c) => c.withOpacity(0.18)).toList(),
              ),
              border: Border.all(color: grad.first.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 11)),
            ]),
          ),
        );
    return Row(children: [
      cell('Lv.', '${u.level}',
          const [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
      cell('Charms', _fmt(u.charms),
          const [Color(0xFFEC4899), Color(0xFFF472B6)]),
      cell('Coins', _fmt(u.coins),
          const [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
    ]);
  }

  Widget _miniCounts(AppUser u) {
    Widget mini(String label, int v) => Expanded(
          child: Column(children: [
            Text('$v',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 11)),
          ]),
        );
    return Row(children: [
      mini('Friends', u.friendsCount),
      mini('Following', u.followingCount),
      mini('Moments', u.momentsCount),
      mini('Visitors', u.visitorsCount),
    ]);
  }

  Widget _bioCard(AppUser u) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(u.bio,
              style: const TextStyle(color: Colors.white, height: 1.4)),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, AppUser u) {
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatScreen(other: u)),
            );
          },
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Message'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _onSendGift(context, u),
          icon: const Text('🎁', style: TextStyle(fontSize: 16)),
          label: const Text('Send Gift'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    ]);
  }

  Future<void> _onSendGift(BuildContext context, AppUser to) async {
    final me = FirebaseAuth.instance.currentUser!;
    final mySnap = await UserService().watchUser(me.uid).first;
    final Gift? gift = await showGiftPicker(context, mySnap.coins);
    if (gift == null) return;

    try {
      final res = roomId == null
          ? await GiftService()
              .sendGift(fromUid: me.uid, toUid: to.uid, gift: gift)
          : await GiftService().sendGiftInRoom(
              fromUid: me.uid,
              toUid: to.uid,
              roomId: roomId!,
              gift: gift,
            );

      if (!context.mounted) return;
      Navigator.pop(context); // close the profile sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              res.jackpot ? const Color(0xFFF
