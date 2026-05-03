import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room.dart';
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
import '../features/rooms/widgets/manage_member_sheet.dart';
import '../models/gift.dart

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

    // ── Combo gift state ────────────────────────────────────────────────────
  Gift? _comboGift;
  String? _comboToUid;
  String? _comboToName;
  int _comboCount = 0;
  int _comboSecsLeft = 5;
  Timer? _comboTimer;

    @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ActiveRoomService.instance.enter(widget.room);
      ActiveRoomService.instance.setFullscreen(true);
      // Any moderator (owner / co_owner / admin) returning unfreezes
      // the room or cancels the 3-min owner-leave countdown.
      try {
        await _svc.modReturnRoom(widget.room.id);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _msgC.dispose();
    _scroll.dispose();
    _comboTimer?.cancel();
    ActiveRoomService.instance.setFullscreen(false);
    super.dispose();
  }

  String get _meUid => FirebaseAuth.instance.currentUser!.uid;
  
    Future<void> _send() async {
    final text = _msgC.text.trim();
    if (text.isEmpty) return;
    _msgC.clear();
    try {
      await _svc.sendTextMessage(widget.room.id, text);
    } catch (e) {
      if (mounted) {
        final raw = e.toString();
        final clean = raw.startsWith('Exception: ')
            ? raw.substring('Exception: '.length)
            : raw;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(clean)));
      }
    }
    }

  void _openProfile(String uid) {
    if (uid.isEmpty || uid == 'system') return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(uid: uid)),
    );
  }

  /// One single gift flow used everywhere. Pass a recipient or null
  /// to first prompt for a recipient via the picker.
    Future<void> _giftFlow({String? toUid, String? toName}) async {
    if (toUid == null) {
      final picked = await RecipientPickerSheet.show(context, widget.room.id);
      if (picked == null || !mounted) return;
      toUid = picked.uid;
      toName = picked.displayName;
    }

    final me = await _userSvc.getUser(_meUid);
    final balance = me?.coins ?? 0;
    if (!mounted) return;

    final gift = await showGiftPicker(context, balance);
    if (gift == null || !mounted) return;

    try {
      final result = await _giftSvc.sendGiftInRoom(
        fromUid: _meUid,
        toUid: toUid,
        roomId: widget.room.id,
        gift: gift,
      );

      if (gift.videoAsset != null && gift.videoAsset!.isNotEmpty) {
        if (mounted) await playGiftAnimation(context, gift.videoAsset!);
      }

      if (!mounted) return;
      _startCombo(gift, toUid, toName ?? 'them');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.jackpot
            ? '🎉 JACKPOT! +${result.luckyCoins} lucky coins to ${toName ?? "them"}'
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

    void _startCombo(Gift gift, String toUid, String toName) {
    _comboTimer?.cancel();
    setState(() {
      _comboGift = gift;
      _comboToUid = toUid;
      _comboToName = toName;
      _comboCount = 1;
      _comboSecsLeft = 5;
    });
    _comboTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _comboSecsLeft--);
      if (_comboSecsLeft <= 0) {
        t.cancel();
        if (mounted) setState(() => _comboGift = null);
      }
    });
  }

  Future<void> _comboResend() async {
    final gift = _comboGift;
    final toUid = _comboToUid;
    final toName = _comboToName;
    if (gift == null || toUid == null) return;
    _comboTimer?.cancel();
    setState(() { _comboCount++; _comboSecsLeft = 5; });
    _comboTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _comboSecsLeft--);
      if (_comboSecsLeft <= 0) {
        t.cancel();
        if (mounted) setState(() => _comboGift = null);
      }
    });
    try {
      final result = await _giftSvc.sendGiftInRoom(
        fromUid: _meUid, toUid: toUid,
        roomId: widget.room.id, gift: gift,
      );
      if (!mounted) return;
      if (result.jackpot) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎉 JACKPOT! +${result.luckyCoins} lucky coins!'),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('Not enough coins')
          ? 'Not enough coins!'
          : 'Error: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      _comboTimer?.cancel();
      setState(() => _comboGift = null);
    }
  }

  Widget _comboOverlay() {
    final gift = _comboGift;
    if (gift == null) return const SizedBox.shrink();
    return Positioned(
      right: 16,
      bottom: 80,
      child: GestureDetector(
        onTap: _comboResend,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: _comboSecsLeft / 5.0,
                  color: const Color(0xFFEC4899),
                  backgroundColor: Colors.white12,
                  strokeWidth: 3.5,
                ),
              ),
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
                  ),
                ),
                child: Center(
                  child: Text(gift.icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              if (_comboCount > 1)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '×$_comboCount',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Positioned(
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_comboSecsLeft}s',
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        _openProfile(m.senderId);
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
      final isOwner = _meUid == widget.room.ownerId;
      if (isOwner) {
        try {
          await _svc.ownerLeaveRoom(widget.room.id);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to exit: $e')));
          }
        }
        await ActiveRoomService.instance.clear();
      } else {
        await ActiveRoomService.instance.exit();
      }
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
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A0B33),
            Color(0xFF0F0A1F),
            Color(0xFF080414),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
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

                _ownerLeftBanner(),
                _inputBar(),
              ],
            ),

            _comboOverlay(),
          ],
        ),
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
    final pin = widget.room.pinnedMessage;
    if (pin == null || pin.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF9333EA).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.push_pin, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pin,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13),
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
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
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
      stream: _svc.watchMessagesTyped(widget.room.id),
      builder: (_, snap) {
        final messages = snap.data ?? const <RoomMessage>[];
        if (messages.isEmpty) {
          return Center(
            child: Text(
              'Say hi 👋',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          );
        }
        return ListView.builder(
          controller: _scroll,
          reverse: true, // newest at the bottom (orderBy desc + reverse)
          padding: const EdgeInsets.all(10),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            final m = messages[i];
            if (m.type == RoomMessageType.system) {
              return _systemBubble(m);
            }
            return _chatBubble(m);
          },
        );
      },
    );
  }

  Widget _systemBubble(RoomMessage m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            m.text,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildSenderName(RoomMessage m) {
  final partner = m.senderCpPartnerName;
  final status  = m.senderCpStatus;
  final showCp  = partner != null &&
      partner.isNotEmpty &&
      (status == 'engaged' || status == 'married');

  if (!showCp) {
    return Text(
      m.senderName,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  final icon = status == 'married' ? '💒' : '💍';

  return RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: m.senderName,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(
          text: ' $icon ',
          style: const TextStyle(fontSize: 10),
        ),
        TextSpan(
          text: partner,
          style: const TextStyle(
            color: Color(0xFFEC4899),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
  }

  Widget _chatBubble(RoomMessage m) {
    final isMe = m.senderId == _meUid;
    final isOwner = m.senderId == widget.room.ownerId;

    final avatar = GestureDetector(
      onTap: () => _openProfile(m.senderId),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isOwner
              ? const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)])
              : const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
          boxShadow: isOwner
              ? [
                  BoxShadow(
                      color: const Color(0xFFFBBF24).withOpacity(0.45),
                      blurRadius: 10),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(2),
        child: CircleAvatar(
          backgroundColor: const Color(0xFF1F0B3F),
          backgroundImage: (m.senderPhoto != null && m.senderPhoto!.isNotEmpty)
              ? NetworkImage(m.senderPhoto!)
              : null,
          child: (m.senderPhoto == null || m.senderPhoto!.isEmpty)
              ? Text(
                  m.senderName.isNotEmpty
                      ? m.senderName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                )
              : null,
        ),
      ),
    );

    final bubble = GestureDetector(
      onLongPress: () => _showMessageMenu(m),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.66,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                )
              : null,
          color: isMe ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // CP-aware sender name
      _buildSenderName(m),
      if (isOwner) ...[
        const SizedBox(width: 4),
        const Icon(Icons.workspace_premium,
            color: Color(0xFFFBBF24), size: 11),
      ],
    ],
  ),
            if (m.type == RoomMessageType.gift)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.card_giftcard,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Sent ${m.giftName ?? "a gift"}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              )
            else
              Text(
                m.text,
                style: const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe
            ? [bubble, const SizedBox(width: 8), avatar]
            : [avatar, const SizedBox(width: 8), bubble],
      ),
    );
  }

  // ================= ABOUT =================

  Widget _aboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aboutCard(
            icon: Icons.info_outline,
            title: 'Description',
            child: Text(
              widget.room.description.isEmpty
                  ? 'No description set.'
                  : widget.room.description,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          _aboutCard(
            icon: Icons.local_offer_outlined,
            title: 'Tags',
            child: widget.room.tags.isEmpty
                ? const Text('—', style: TextStyle(color: Colors.white54))
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.room.tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: Colors.white12),
                            ),
                            child: Text('#$t',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12)),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 12),
          _aboutCard(
            icon: Icons.workspace_premium,
            title: 'Owner',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: GestureDetector(
                onTap: () => _openProfile(widget.room.ownerId),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF1F0B3F),
                  backgroundImage: (widget.room.ownerPhoto != null &&
                          widget.room.ownerPhoto!.isNotEmpty)
                      ? NetworkImage(widget.room.ownerPhoto!)
                      : null,
                  child: (widget.room.ownerPhoto == null ||
                          widget.room.ownerPhoto!.isEmpty)
                      ? Text(widget.room.ownerName[0].toUpperCase(),
                          style:
                              const TextStyle(color: Colors.white))
                      : null,
                ),
              ),
              title: Text(widget.room.ownerName,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text('${widget.room.ownerCharms} charms',
                  style: const TextStyle(color: Colors.white54)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFEC4899), size: 16),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ================= MEMBERS =================

    Widget _membersTab() {
    return StreamBuilder<RoomMember?>(
      stream: _svc.watchMyMembership(widget.room.id),
      builder: (_, meSnap) {
        final me = meSnap.data;
        return StreamBuilder<List<RoomMember>>(
          stream: _svc.watchMembers(widget.room.id),
          builder: (_, snap) {
            final members = [...(snap.data ?? const <RoomMember>[])];
            members.sort((a, b) {
              final r = a.role.index.compareTo(b.role.index);
              if (r != 0) return r;
              return b.charms.compareTo(a.charms);
            });

            if (members.isEmpty) {
              return const Center(
                child: Text('No members yet',
                    style: TextStyle(color: Colors.white54)),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final m = members[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () => _openProfile(m.uid),
                    onLongPress: () {
                      if (me == null || m.uid == _meUid) return;
                      ManageMemberSheet.show(
                        context: context,
                        room: widget.room,
                        me: me,
                        target: m,
                        svc: _svc,
                      );
                    },
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF1F0B3F),
                          backgroundImage:
                              (m.photoUrl != null && m.photoUrl!.isNotEmpty)
                                  ? NetworkImage(m.photoUrl!)
                                  : null,
                          child: (m.photoUrl == null || m.photoUrl!.isEmpty)
                              ? Text(
                                  m.displayName.isNotEmpty
                                      ? m.displayName[0].toUpperCase()
                                      : '?',
                                  style:
                                      const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        if (m.isPresent)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF0F0A1F),
                                    width: 2),
                              ),
                            ),
                          ),
                        if (m.isMuted)
                          const Positioned(
                            left: 0,
                            top: 0,
                            child: Icon(Icons.volume_off,
                                color: Colors.amber, size: 14),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(m.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 6),
                        _roleChip(m.role),
                      ],
                    ),
                    subtitle: Text('${m.charms} charms',
                        style: const TextStyle(color: Colors.white54)),
                    trailing: m.uid == _meUid
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.card_giftcard,
                                color: Color(0xFFEC4899)),
                            onPressed: () => _giftFlow(
                                toUid: m.uid, toName: m.displayName),
                          ),
                  ),
                );
              },
            );
          },
        );
      },
    );
    }
  
  Widget _roleChip(RoomRole role) {
    if (role == RoomRole.member) return const SizedBox.shrink();
    final colors = switch (role) {
      RoomRole.owner => const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      RoomRole.coOwner => const [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      RoomRole.admin => const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      RoomRole.member => const [Colors.transparent, Colors.transparent],
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(role.label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold)),
    );
  }

  // ================= LEADERBOARD =================

  Widget _leaderboardTab() {
    return Center(
      child: Text(
        "Leaderboard coming soon",
        style: TextStyle(color: Colors.white.withOpacity(0.6)),
      ),
    );
  }

  // ================= INPUT =================

    // ================= OWNER-LEFT / FROZEN BANNER =================

  Widget _ownerLeftBanner() {
    return StreamBuilder<Room?>(
      stream: _svc.watchRoom(widget.room.id),
      builder: (_, snap) {
        final room = snap.data;
        if (room == null) return const SizedBox.shrink();

        // Auto-delete trigger for expired temporary rooms.
        if (room.isPendingDelete &&
            room.deleteAt != null &&
            room.deleteAt!.isBefore(DateTime.now())) {
          _svc.autoDeleteIfExpired(room.id).then((deleted) async {
            if (deleted && mounted) {
              await ActiveRoomService.instance.clear();
              if (mounted) Navigator.of(context).pop();
            }
          });
        }

        if (room.isPendingDelete && room.deleteAt != null) {
          final amOwner = _meUid == room.ownerId;
          return _CountdownBanner(
            deleteAt: room.deleteAt!,
            showReturnButton: amOwner,
            onReturn: () async {
              try {
                await _svc.modReturnRoom(room.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')));
                }
              }
            },
          );
        }

        if (room.isFrozen) {
          return _FrozenBanner(
            onUnfreeze: () async {
              try {
                await _svc.modReturnRoom(room.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to unfreeze: $e')));
                }
              }
            },
          );
        }

        return const SizedBox.shrink();
      },
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _msgC,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.card_giftcard,
                color: Color(0xFFEC4899)),
            onPressed: () => _giftFlow(),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _send,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM TOOLBAR =================


class _CountdownBanner extends StatefulWidget {
  final DateTime deleteAt;
  final bool showReturnButton;
  final VoidCallback onReturn;

  const _CountdownBanner({
    required this.deleteAt,
    required this.showReturnButton,
    required this.onReturn,
  });

  @override
  State<_CountdownBanner> createState() => _CountdownBannerState();
}

class _CountdownBannerState extends State<_CountdownBanner> {
  late final Stream<DateTime> _tick;

  @override
  void initState() {
    super.initState();
    _tick = Stream<DateTime>.periodic(
        const Duration(seconds: 1), (_) => DateTime.now());
  }

  String _fmt(Duration d) {
    if (d.isNegative) return '0:00';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _tick,
      initialData: DateTime.now(),
      builder: (_, snap) {
        final remaining = widget.deleteAt.difference(snap.data!);
        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            ),
            border: Border(
              top: BorderSide(color: Colors.black26),
              bottom: BorderSide(color: Colors.black26),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.showReturnButton
                      ? 'You exited the room — closing in ${_fmt(remaining)}'
                      : 'Owner has exited — room ends in ${_fmt(remaining)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (widget.showReturnButton) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onReturn,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Stay',
                      style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FrozenBanner extends StatelessWidget {
  final VoidCallback onUnfreeze;
  const _FrozenBanner({required this.onUnfreeze});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)],
        ),
        border: Border(
          top: BorderSide(color: Colors.black26),
          bottom: BorderSide(color: Colors.black26),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.ac_unit, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Room is frozen — waiting for owner / admin / co-owner',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: onUnfreeze,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Unfreeze',
                style: TextStyle(
                    color: Color(0xFF1E40AF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
