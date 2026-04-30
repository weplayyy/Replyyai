import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';
import '../services/room_service.dart';
import '../services/active_room_service.dart';

class RoomScreen extends StatefulWidget {
  final Room room;
  const RoomScreen({super.key, required this.room});
  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _msgC = TextEditingController();
  final _svc = RoomService();
  final _scroll = ScrollController();

    @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ActiveRoomService.instance.enter(widget.room);
      ActiveRoomService.instance.setFullscreen(true);
    });
  }

    Future<void> _showRoomMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF14092B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.minimize_rounded,
                  color: Colors.white70),
              title: const Text('Minimize',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                  'Stay in room — show as floating bubble',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () => Navigator.pop(context, 'minimize'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.logout, color: Color(0xFFEC4899)),
              title: const Text('Exit room',
                  style: TextStyle(color: Color(0xFFEC4899))),
              subtitle: const Text('Leave completely',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () => Navigator.pop(context, 'exit'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'minimize') {
      Navigator.of(context).pop();
    } else if (action == 'exit') {
      await ActiveRoomService.instance.exit();
      if (mounted) Navigator.of(context).pop();
    }
    }
  
  @override
  void dispose() {
    _tab.dispose();
    _msgC.dispose();
    _scroll.dispose();
    // Leaving the screen makes the bubble re-appear; membership is kept.
    ActiveRoomService.instance.setFullscreen(false);
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgC.text.trim();
    if (text.isEmpty) return;
    _msgC.clear();
    final me = FirebaseAuth.instance.currentUser!;
    await _svc.sendMessage(roomId: widget.room.id, senderId: me.uid, text: text);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
  canPop: true,
  onPopInvoked: (didPop) async {
    if (didPop) await ActiveRoomService.instance.minimize();
  },
  child: Scaffold(
    backgroundColor: const Color(0xFF0F0A1F),
    body: SafeArea(
      child: Column(
          children: [
            _header(),
            _pinnedBanner(),
            _tabBar(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _chatTab(),
                  _aboutTab(),
                  _membersTab(),
                  _leaderboardTab(),
                ],
              ),
            ),
            _inputBar(),
            _bottomToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.5),
                    blurRadius: 14),
              ],
            ),
            alignment: Alignment.center,
            child: Text(widget.room.emoji,
                style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(widget.room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                        'ID: ${widget.room.id.isEmpty ? "—" : widget.room.id.substring(0, widget.room.id.length.clamp(0, 6))}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11)),
                    const SizedBox(width: 6),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white24, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('${widget.room.onlineCount} Online',
                        style: const TextStyle(
                            color: Color(0xFF22C55E), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          _iconBtn(Icons.share_rounded, () {}),
          const SizedBox(width: 6),
          _iconBtn(Icons.notifications_outlined, () {}, dot: true),
          const SizedBox(width: 6),
          _iconBtn(Icons.more_horiz, () => _showRoomMenu()),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData ic, VoidCallback onTap, {bool dot = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(ic, color: Colors.white, size: 16),
          ),
          if (dot)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pinnedBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Text('📌', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('Pinned',
                          style: TextStyle(
                              color: Color(0xFFB794F6),
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.verified,
                          color: Color(0xFF8B5CF6), size: 12),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.room.description.isEmpty
                        ? 'Be kind, be real, and respect everyone here 💜'
                        : widget.room.description,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: TabBar(
        controller: _tab,
        isScrollable: true,
        indicatorColor: const Color(0xFF8B5CF6),
        indicatorWeight: 2.5,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: [
          const Tab(text: 'Chat'),
          const Tab(text: 'About'),
          Tab(text: 'Members ${widget.room.onlineCount}'),
          const Tab(text: 'Leaderboard'),
        ],
      ),
    );
  }

  Widget _chatTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _svc.watchMessages(widget.room.id),
      builder: (_, snap) {
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.white70)));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final msgs = snap.data!;
        if (msgs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No messages yet.\nBe the first to say hi 👋',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
            ),
          );
        }
        return ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          itemCount: msgs.length,
          itemBuilder: (_, i) => _messageBubble(msgs[i]),
        );
      },
    );
  }

  Widget _messageBubble(Map<String, dynamic> m) {
    final senderId = m['senderId'] as String? ?? '';
    final text = m['text'] as String? ?? '';
    final ts = m['createdAt'] as Timestamp?;

    final me = FirebaseAuth.instance.currentUser?.uid;
    final isMe = senderId == me;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get(),
      builder: (context, snap) {
        final user = snap.data?.data();
        final name = user?['name'] ?? 'User';
        final avatar = user?['avatar'] ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe) _avatar(avatar),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFF8B5CF6)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(text,
                          style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ts != null
                          ? TimeOfDay.fromDateTime(ts.toDate())
                              .format(context)
                          : '',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (isMe) const SizedBox(width: 8),
              if (isMe) _avatar(avatar),
            ],
          ),
        );
      },
    );
  }

  Widget _avatar(String url) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.white24,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? const Icon(Icons.person, size: 14, color: Colors.white)
          : null,
    );
  }

  Widget _aboutTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        widget.room.description.isEmpty
            ? 'No description available'
            : widget.room.description,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _membersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.room.id)
          .collection('members')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data();
            final name = data['name'] ?? 'User';

            return ListTile(
              title: Text(name,
                  style: const TextStyle(color: Colors.white)),
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            );
          },
        );
      },
    );
  }

  Widget _leaderboardTab() {
    return const Center(
      child: Text(
        'Leaderboard coming soon',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      color: const Color(0xFF140D2A),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgC,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF8B5CF6)),
            onPressed: _send,
          ),
        ],
      ),
    );
  }

  Widget _bottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF0F0A1F),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tool(Icons.mic),
          _tool(Icons.card_giftcard),
          _tool(Icons.emoji_emotions),
          _tool(Icons.more_horiz),
        ],
      ),
    );
  }

  Widget _tool(IconData icon) {
    return Icon(icon, color: Colors.white70, size: 22);
  }
}
