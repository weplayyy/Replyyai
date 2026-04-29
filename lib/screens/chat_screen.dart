import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/gift.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/gift_service.dart';
import '../services/user_service.dart';
import 'gift_picker.dart';
import 'gift_animation_overlay.dart';
import 'user_profile_sheet.dart';

class ChatScreen extends StatefulWidget {
  final AppUser other;
  const ChatScreen({super.key, required this.other});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _textC = TextEditingController();
  final _chat = ChatService();
  final _gifts = GiftService();
  late final String _myUid;
  late final String _chatId;

  late final AnimationController _giftAC;
  String? _giftIcon;
  String? _giftName;
  int? _giftPrice;

  bool _initialized = false;
  String? _lastGiftMessageId;
  AppUser? _me;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser!.uid;
    _chatId = _chat.chatIdFor(_myUid, widget.other.uid);
    _giftAC = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));

    UserService().watchUser(_myUid).listen((u) {
      if (mounted) setState(() => _me = u);
    });
  }

  @override
  void dispose() {
    _giftAC.dispose();
    _textC.dispose();
    super.dispose();
  }

  Gift? _giftById(String? id) {
    if (id == null) return null;
    for (final g in kAllGifts) {
      if (g.id == id) return g;
    }
    return null;
  }

  Future<void> _send() async {
    final text = _textC.text.trim();
    if (text.isEmpty) return;
    _textC.clear();
    await _chat.sendMessage(
        fromUid: _myUid, toUid: widget.other.uid, text: text);
  }

  Future<void> _openGiftPicker() async {
    final balance = _me?.coins ?? 0;
    final gift = await showGiftPicker(context, balance);
    if (gift == null) return;
    try {
      final result = await _gifts.sendGift(
          fromUid: _myUid, toUid: widget.other.uid, gift: gift);
      if (!mounted) return;
      String msg = 'Sent ${gift.icon} ${gift.name}';
      if (result.luckyCoins > 0) {
        msg +=
            ' • ${widget.other.displayName} got 🪙${result.luckyCoins} lucky coins';
      }
      if (result.jackpot) msg += '  🎉 JACKPOT!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: result.jackpot
              ? const Color(0xFFFBBF24)
              : const Color(0xFF8B5CF6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _playGift(Message m) {
    final video = _giftById(m.giftId)?.videoAsset;
    if (video != null && video.isNotEmpty) {
      playGiftAnimation(context, video);
      return;
    }
    setState(() {
      _giftIcon = m.giftIcon ?? '🎁';
      _giftName = m.giftName ?? 'Gift';
      _giftPrice = m.giftPrice ?? 0;
    });
    _giftAC.forward(from: 0).then((_) {
      if (mounted) setState(() => _giftIcon = null);
    });
  }

  void _onMessages(List<Message> msgs) {
    if (msgs.isEmpty) {
      _initialized = true;
      return;
    }
    final newest = msgs.first;
    if (!_initialized) {
      _initialized = true;
      if (newest.type == 'gift') _lastGiftMessageId = newest.id;
      return;
    }
    if (newest.type == 'gift' && newest.id != _lastGiftMessageId) {
      _lastGiftMessageId = newest.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playGift(newest);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0B2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: GestureDetector(
          onTap: () => showUserProfileSheet(context, uid: widget.other.uid),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                ),
                child: Center(
                  child: Text(
                    widget.other.displayName.isNotEmpty
                        ? widget.other.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.other.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: _chat.watchMessages(_chatId),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Could not load messages.\n${snap.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final msgs = snap.data!;
                    _onMessages(msgs);
                    if (msgs.isEmpty) {
                      return Center(
                        child: Text(
                          'Say hi to ${widget.other.displayName}!',
                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(14),
                      itemCount: msgs.length,
                      itemBuilder: (_, i) {
                        final m = msgs[i];
                        final mine = m.senderId == _myUid;
                        if (m.type == 'gift') return _giftBubble(m, mine);
                        return _textBubble(m.text, mine);
                      },
                    );
                  },
                ),
              ),
              _composer(),
            ],
          ),
          if (_giftIcon != null) _giftAnimationOverlay(),
        ],
      ),
    );
  }

  Widget _giftAnimationOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _giftAC,
          builder: (_, __) {
            final t = _giftAC.value;
            double scale;
            double opacity;
            if (t < 0.25) {
              scale = Curves.elasticOut.transform(t / 0.25);
              opacity = 1.0;
            } else if (t < 0.85) {
              scale = 1.0;
              opacity = 1.0;
            } else {
              final f = (t - 0.85) / 0.15;
              scale = 1.0 + f * 0.4;
              opacity = 1.0 - f;
            }
            return Container(
              color: Colors.black.withOpacity(opacity * 0.35),
              alignment: Alignment.center,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0x88EC4899), Color(0x008B5CF6)],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(_giftIcon!,
                            style: const TextStyle(fontSize: 140)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _giftName ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      if ((_giftPrice ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '🪙 $_giftPrice',
                              style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _textBubble(String text, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: mine
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
              : null,
          color: mine ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _giftBubble(Message m, bool mine) {
    final priceText = '🪙 ${m.giftPrice ?? 0}';
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0x55EC4899), Color(0x558B5CF6)],
          ),
          border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.giftIcon ?? '🎁', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 4),
            Text(
              mine
                  ? 'You sent ${m.giftName}'
                  : '${widget.other.displayName} sent ${m.giftName}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              priceText,
              style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if ((m.luckyCoins ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🎰 Lucky +${m.luckyCoins} coins',
                  style: const TextStyle(
                    color: Color(0xFFFDE047),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      color: const Color(0xFF1A0B2E),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: _openGiftPicker,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFEC4899)]),
                ),
                child: const Icon(Icons.card_giftcard, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textC,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
