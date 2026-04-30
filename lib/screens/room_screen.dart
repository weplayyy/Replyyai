import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room.dart';
import '../models/gift.dart';
import '../models/app_user.dart';
import '../services/room_service.dart';
import '../services/active_room_service.dart';
import '../services/user_service.dart';
import '../services/gift_service.dart';
import '../data/room_presets.dart';
import '../features/rooms/models/room_message.dart';
import '../features/rooms/models/room_member.dart';
import '../features/rooms/models/room_role.dart';
import '../features/rooms/widgets/recipient_picker_sheet.dart';
import '../features/rooms/widgets/share_to_friends_sheet.dart';
import 'gift_picker.dart';
import 'gift_animation_overlay.dart';
import 'shop_screen.dart';
import 'user_profile_screen.dart';

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
  final _userSvc = UserService();
  final _giftSvc = GiftService();
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

  @override
  void dispose() {
    _tab.dispose();
    _msgC.dispose();
    _scroll.dispose();
    ActiveRoomService.instance.setFullscreen(false);
    super.dispose();
  }

  String get _meUid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _send() async {
    final text = _msgC.text.trim();
    if (text.isEmpty) return;
    _msgC.clear();
    await _svc.sendTextMessage(widget.room.id, text);
  }

  /// One single gift flow used everywhere. Pass a recipient or null
  /// to first prompt for a recipient via the picker.
  Future<void> _giftFlow({String? toUid, String? toName}) async {
    // 1) Resolve recipient
    if (toUid == null) {
      final picked =
          await RecipientPickerSheet.show(context, widget.room.id);
      if (picked == null || !mounted) return;
      toUid = picked.uid;
      toName = picked.displayName;
    }
    if (toUid == _meUid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can\'t gift yourself 😅')));
      return;
    }

    // 2) Fetch live coin balance
    final me = await _userSvc.getUser(_meUid);
    final balance = me?.coins ?? 0;

    if (!mounted) return;

    // 3) Open YOUR existing gift picker
    final gift = await showGiftPicker(context, balance);
    if (gift == null || !mounted) return;

    // 4) Send via YOUR existing gift service (coins/charms/lucky/jackpot/guardian)
    try {
      final result = await _giftSvc.sendGiftInRoom(
        fromUid: _meUid,
        toUid: toUid,
        roomId: widget.room.id,
        gift: gift,
      );

      // 5) Play fullscreen animation if the gift has a video
      if (gift.videoAsset != null && gift.videoAsset!.isNotEmpty) {
        if (mounted) await playGiftAnimation(context, gift.videoAsset!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.jackpot
            ? '🎉 JACKPOT! +${result.luckyCoins} lucky coins back to ${toName ?? "them"}'
            : 'Sent ${gift.name} to ${toName ?? "them"}'),
      ));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('Not enough coins')
          ? 'Not enough coins. Top up to keep gifting.'
          : 'Error: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _showMessageMenu(RoomMessage m) async {
    final isOwn = m.senderId == _meUid;
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            if (!isOwn && m.senderId.isNotEmpty && m.senderId != 'system')
              ListTile(
                leading: const Icon(Icons.card_giftcard,
                    color: Color(0xFFEC4899)),
                title: const Text('Send Gift',
                    style: TextStyle(color: Colors.white)),
                subtitle: Text('to ${m.senderName}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
                onTap: () => Navigator.pop(context, 'gift'),
              ),
            if (!isOwn && m.senderId.isNotEmpty && m.senderId != 'system')
              ListTile(
                leading:
                    const Icon(Icons.person_outline, color: Colors.white70),
                title: const Text('View Profile',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, 'profile'),
              ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined,
                  color: Colors.white70),
              title: const Text('Delete from my side',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Hide this message just for you',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () => Navigator.pop(context, 'hide'),
            ),
            if (!isOwn && m.senderId != 'system')
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: const Text('Report',
                    style: TextStyle(color: Colors.orange)),
                onTap: () => Navigator.pop(context, 'report'),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'gift':
        await _giftFlow(toUid: m.senderId, toName: m.senderName);
        break;
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => UserProfileScreen(uid: m.senderId)),
        );
        break;
      case 'hide':
        await _svc.hideMessageForMe(widget.room.id, m.id);
        break;
      case 'report':
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report sent. Thank you.')));
        }
        break;
    }
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading:
                  const Icon(Icons.minimize_rounded, color: Colors.white70),
              title: const Text('Minimize',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                  'Stay in room — show as floating bubble',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () => Navigator.pop(context, 'minimize'),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFEC4899)),
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
      ),
    );
  }

  Widget _header() {
    final photo =
        widget.room.photoUrl ?? RoomPresets.firstFor(widget.room.category);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.room.isAdvanced
              ? const [Color(0xFF1F0B3F), Color(0xFF3A0E5C)]
              : const [Color(0xFF14092B), Color(0xFF1F0B3F)],
        ),
        border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.5),
                    blurRadius: 14)
              ],
              image: DecorationImage(
                image: AssetImage(photo),
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
              border: widget.room.isAdvanced
                  ? Border.all(
                      color: const Color(0xFFFBBF24), width: 2)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
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
                    if (widget.room.isAdvanced) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFFFBBF24),
                            Color(0xFFF59E0B)
                          ]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.diamond,
                                color: Colors.white, size: 10),
                            const SizedBox(width: 3),
                            Text('Lv ${widget.room.level}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFF22C55E), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('${widget.room.onlineCount} online',
                        style: const TextStyle(
                            color: Color(0xFF22C55E), fontSize: 11)),
                    const SizedBox(width: 8),
                    Text('• ${widget.room.category}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          _coinPill(),
          const SizedBox(width: 6),
          _iconBtn(Icons.share_rounded,
              () => ShareToFriendsSheet.show(context, widget.room)),
          const SizedBox(width: 6),
          _iconBtn(Icons.more_horiz, _showRoomMenu),
        ],
      ),
    );
  }

  /// Live coin balance pill — taps to your existing shop.
  Widget _coinPill() {
    return StreamBuilder<AppUser>(
      stream: _userSvc.watchUser(_meUid),
      builder: (_, snap) {
        final coins = snap.data?.coins ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 5, 5, 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      Color(0xFFFFD86B),
                      Color(0xFFF59E0B)
                    ]),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '\$',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  coins.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.add, color: Colors.white70, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _pinnedBanner() {
    if (widget.room.pinnedMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.room.pinnedMessage!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return TabBar(
      controller: _tab,
      indicatorColor: const Color(0xFF8B5CF6),
      tabs: const [
        Tab(text: "Chat"),
        Tab(text: "About"),
        Tab(text: "Members"),
        Tab(text: "Top"),
      ],
    );
  }

  // ================= CHAT =================
 Widget _chatTab() {
  return StreamBuilder<List<RoomMessage>>(
    stream: _svc.watchMessages(widget.room.id),
    builder: (_, snap) {
      final messages = snap.data ?? [];

      return ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(10),
        itemCount: messages.length,
        itemBuilder: (_, i) {
          final m = messages[i];
          final isMe = m.senderId == _meUid;

          return GestureDetector(
            onLongPress: () => _showMessageMenu(m),
            child: Align(
              alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        )
                      : null,
                  color:
                      isMe ? null : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Text(
                        m.senderName ?? "User",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                    Text(
                      m.text ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
 }

  // ================= ABOUT =================

  Widget _aboutTab() {
    return Center(
      child: Text(
        "Room Info",
        style: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
    );
  }

  // ================= MEMBERS =================

  Widget _membersTab() {
    return StreamBuilder<List<RoomMember>>(
      stream: _svc.watchMembers(widget.room.id),
      builder: (_, snap) {
        final members = snap.data ?? [];

        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (_, i) {
            final m = members[i];

            return ListTile(
              leading: CircleAvatar(child: Text(m.name[0])),
              title: Text(m.name,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(m.role.name,
                  style: const TextStyle(color: Colors.white54)),
            );
          },
        );
      },
    );
  }

  // ================= LEADERBOARD =================

  Widget _leaderboardTab() {
    return Center(
      child: Text(
        "Leaderboard Coming Soon",
        style: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
    );
  }

  // ================= INPUT =================

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgC,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type message...",
                hintStyle:
                    TextStyle(color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.card_giftcard,
                color: Color(0xFFEC4899)),
            onPressed: () => _giftFlow(),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _send,
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM TOOLBAR =================

  Widget _bottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tool(Icons.mic, "Mic"),
          _tool(Icons.emoji_emotions, "Emoji"),
          _tool(Icons.games, "Games"),
          _tool(Icons.card_giftcard, "Gift"),
        ],
      ),
    );
  }

  Widget _tool(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}
