import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../friends/services/friend_service.dart';
import '../../friends/models/friendship.dart';
import '../../../models/room.dart';
import '../../../services/room_service.dart';
import '../../../services/chat_service.dart';

class ShareToFriendsSheet extends StatefulWidget {
  final Room room;
  const ShareToFriendsSheet({super.key, required this.room});

  static const int maxFriendsPerShare = 9;

  static Future<void> show(BuildContext context, Room room) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: ShareToFriendsSheet(room: room),
        ),
      ),
    );
  }

  @override
  State<ShareToFriendsSheet> createState() => _ShareToFriendsSheetState();
}

class _ShareToFriendsSheetState extends State<ShareToFriendsSheet> {
  final _selected = <String>{};
  final _svc = FriendService();
  final _chat = ChatService();
  bool _busy = false;

  void _toggle(String uid) {
    setState(() {
      if (_selected.contains(uid)) {
        _selected.remove(uid);
      } else if (_selected.length <
          ShareToFriendsSheet.maxFriendsPerShare) {
        _selected.add(uid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 9 friends per share')),
        );
      }
    });
  }

  Future<void> _share() async {
    if (_selected.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final me = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;

      // 1) Write a roomInvite doc to each friend (for an "invites" badge later).
      final batch = db.batch();
      for (final friendUid in _selected) {
        final ref = db
            .collection('users')
            .doc(friendUid)
            .collection('roomInvites')
            .doc();
        batch.set(ref, {
          'roomId': widget.room.id,
          'roomName': widget.room.name,
          'roomCategory': widget.room.category,
          'roomEmoji': widget.room.emoji,
          'roomPhoto': widget.room.photoUrl,
          'fromUid': me.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'seen': false,
        });
      }
      await batch.commit();

      // 2) Send a real DM to each friend via existing ChatService.
      final inviteText =
          '🌙 Join my room "${widget.room.name}" — id: ${widget.room.id}';
      for (final friendUid in _selected) {
        await _chat.sendMessage(
          fromUid: me.uid,
          toUid: friendUid,
          text: inviteText,
        );
      }

      // 3) Drop a system note in the room.
      await RoomService().postSystemMessage(
        widget.room.id,
        '✨ Shared this room with ${_selected.length} friend(s)',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Shared with ${_selected.length} friend(s)')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF14092B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text('Share to Friends',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_selected.length}/9',
                    style: const TextStyle(
                        color: Color(0xFFB794F6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<Friendship>>(
              stream: _svc.watchMyFriends(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return const Center(
                    child: Text('No friends yet to share with',
                        style: TextStyle(color: Colors.white54)),
                  );
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final f = list[i];
                    final picked = _selected.contains(f.uid);
                    return GestureDetector(
                      onTap: () => _toggle(f.uid),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: picked
                              ? const Color(0xFF8B5CF6).withOpacity(0.18)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: picked
                                ? const Color(0xFF8B5CF6)
                                : Colors.white.withOpacity(0.06),
                            width: picked ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFFEC4899)
                                ]),
                                image: f.photoUrl != null &&
                                        f.photoUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(f.photoUrl!),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: f.photoUrl == null ||
                                      f.photoUrl!.isEmpty
                                  ? Center(
                                      child: Text(
                                        f.displayName.isNotEmpty
                                            ? f.displayName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.bold),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(f.displayName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: picked
                                    ? const Color(0xFF8B5CF6)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: picked
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.white38,
                                  width: 2,
                                ),
                              ),
                              child: picked
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selected.isEmpty ? null : _share,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: _selected.isEmpty
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                color: _selected.isEmpty ? Colors.white12 : null,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _selected.isEmpty
                          ? 'Select friends to share'
                          : 'Share with ${_selected.length} friend(s)',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
