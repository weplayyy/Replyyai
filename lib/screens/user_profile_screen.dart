import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/gift.dart';
import '../services/user_service.dart';
import '../services/gift_service.dart';
import 'gift_picker.dart';
import 'chat_screen.dart';

Future<void> openUserProfileScreen(
  BuildContext context, {
  required String uid,
  String? roomId,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => UserProfileScreen(uid: uid, roomId: roomId),
    ),
  );
}

class UserProfileScreen extends StatelessWidget {
  final String uid;
  final String? roomId;
  const UserProfileScreen({super.key, required this.uid, this.roomId});

  static const _bg = Color(0xFF0B0717);
  static const _card = Color(0xFF181028);
  static const _cardSoft = Color(0xFF1F1535);
  static const _purple = Color(0xFF7C5CFF);
  static const _gold = Color(0xFFFFC542);

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    final isMe = me.uid == uid;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<AppUser>(
          stream: UserService().watchUser(uid),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final u = snap.data!;
            return Stack(
              children: [
                // Soft purple radial glow background
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.7),
                        radius: 1.1,
                        colors: [
                          _purple.withOpacity(0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  children: [
                    _topBar(context),
                    const SizedBox(height: 8),
                    _hero(u),
                    const SizedBox(height: 18),
                    _statsCard(u),
                    const SizedBox(height: 12),
                    _clanCard(context, u),
                    const SizedBox(height: 12),
                    _cpPartnerCard(context, u),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _signatureCard(u)),
                        const SizedBox(width: 12),
                        Expanded(child: _bffCard(context)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _guardiansCard(context)),
                        const SizedBox(width: 12),
                        Expanded(child: _advancedRoomCard()),
                      ],
                    ),
                  ],
                ),
                if (!isMe)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _actionBar(context, u),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- TOP BAR ----------
  Widget _topBar(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      );

  // ---------- HERO ----------
  Widget _hero(AppUser u) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar with purple ring and level badge
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 110,
                height: 110,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_purple, Color(0xFFB388FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.45),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: _card,
                  backgroundImage:
                      (u.photoURL != null && u.photoURL!.isNotEmpty)
                          ? NetworkImage(u.photoURL!)
                          : null,
                  child: (u.photoURL == null || u.photoURL!.isEmpty)
                      ? Text(
                          (u.displayName.isNotEmpty
                                  ? u.displayName[0]
                                  : '?')
                              .toUpperCase(),
                          style: const TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _purple,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _bg, width: 2),
                  ),
                  child: Text('${u.level}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
            ],
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
                      u.displayName.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('❤', style: TextStyle(fontSize: 18)),
                  if (u.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified,
                        color: Color(0xFF3B82F6), size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '@${u.username.isNotEmpty ? u.username : u.uid.substring(0, 6)}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => Clipboard.setData(
                        ClipboardData(text: '@${u.username}')),
                    child: const Icon(Icons.copy,
                        color: Colors.white38, size: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _pill(
                    bg: _purple,
                    child: Text('Lv.${u.level}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  _pill(
                    bg: const Color(0xFF3A2A14),
                    border: _gold,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            color: _gold, size: 14),
                        const SizedBox(width: 4),
                        Text(_fmt(u.charms),
                            style: const TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Color(0xFF22C55E), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Online',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Living  •  Laughing  •  Gaming 🎮',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill({required Color bg, Color? border, required Widget child}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: border != null ? Border.all(color: border) : null,
        ),
        child: child,
      );

  // ---------- STATS CARD ----------
  Widget _statsCard(AppUser u) {
    Widget stat(String label, String value, IconData icon, Color color) =>
        Expanded(
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        );

    return _shell(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            stat('Gifts', _fmt(u.friendsCount), Icons.card_giftcard, _purple),
            stat('Stars', _fmt(u.charms), Icons.star, _gold),
            stat('Moments', _fmt(u.momentsCount), Icons.chat_bubble,
                const Color(0xFF60A5FA)),
            stat('BFF', _fmt(24), Icons.favorite,
                const Color(0xFFEC4899)),
          ],
        ),
      ),
    );
  }

  // ---------- CLAN ----------
  Widget _clanCard(BuildContext context, AppUser u) {
    final hasClan = u.clanName != null && u.clanName!.isNotEmpty;
    return _shell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clan',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(hasClan ? u.clanName! : 'No clan yet',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (hasClan && u.clanRole != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: _purple.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(u.clanRole!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            if (hasClan && (u.clanId ?? '').isNotEmpty)
              _clanMembers(u.clanId!),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _clanMembers(String clanId) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('clans')
          .doc(clanId)
          .snapshots(),
      builder: (_, snap) {
        final data = snap.data?.data();
        final members =
            (data?['memberUids'] as List?)?.cast<String>() ?? const [];
        final shown = members.take(3).toList();
        final extra = members.length - shown.length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < shown.length; i++)
              Transform.translate(
                offset: Offset(-i * 10.0, 0),
                child: _avatarThumb(shown[i], 26),
              ),
            if (extra > 0)
              Transform.translate(
                offset: Offset(-shown.length * 10.0, 0),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _cardSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text('+$extra',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9)),
                ),
              ),
          ],
        );
      },
    );
  }

  // ---------- CP PARTNER ----------
  Widget _cpPartnerCard(BuildContext context, AppUser u) {
    final has = (u.cpPartnerUid ?? '').isNotEmpty;
    return _shell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CP Partner',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(has ? (u.cpPartnerName ?? '') : 'Single',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      if (has) const Text('❤'),
                    ],
                  ),
                  if (has && u.cpSince != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Since ${_fmtDate(u.cpSince!)}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ),
                ],
              ),
            ),
            if (has) _avatarThumb(u.cpPartnerUid!, 36),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  // ---------- SIGNATURE ----------
  Widget _signatureCard(AppUser u) {
    final lines = (u.signature ?? u.bio).trim().split('\n');
    return _shell(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Signature',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Icon(Icons.format_quote,
                color: Colors.white24, size: 20),
            const SizedBox(height: 4),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(l,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13)),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ---------- BFF ----------
  Widget _bffCard(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('bffs')
        .orderBy('level', descending: true)
        .limit(3)
        .snapshots();

    return _shell(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('BFF ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const Text('❤', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('bffs')
                      .snapshots(),
                  builder: (_, s) => Text('${s.data?.docs.length ?? 0}',
                      style: const TextStyle(
                          color: Color(0xFFEC4899),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Row(
                  children: const [
                    Text('View all',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 11)),
                    Icon(Icons.chevron_right,
                        color: Colors.white38, size: 14),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 86,
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (_, snap) {
                  final docs = snap.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No BFFs yet',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    );
                  }
                  final colors = <List<Color>>[
                    [const Color(0xFF7C3AED), const Color(0xFF4C1D95)],
                    [const Color(0xFFFBBF24), const Color(0xFF92400E)],
                    [const Color(0xFFEF4444), const Color(0xFF7F1D1D)],
                  ];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0;
                          i < docs.length && i < colors.length;
                          i++)
                        _bffTile(docs[i].data() as Map<String, dynamic>,
                            colors[i]),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bffTile(Map<String, dynamic> d, List<Color> grad) {
    final lvl = d['level'] ?? 1;
    final photo = d['photoURL'] as String?;
    return Container(
      width: 56,
      height: 86,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: grad,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Lv.$lvl',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            bottom: 4,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: _bg,
              backgroundImage:
                  (photo != null && photo.isNotEmpty)
                      ? NetworkImage(photo)
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- GUARDIANS ----------
  Widget _guardiansCard(BuildContext context) {
    return _shell(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text('Guardians',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                Spacer(),
                Text('View all',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                Icon(Icons.chevron_right,
                    color: Colors.white38, size: 14),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('guardians')
                  .orderBy('totalCharms', descending: true)
                  .limit(3)
                  .snapshots(),
              builder: (_, snap) {
                final docs = snap.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const SizedBox(
                    height: 40,
                    child: Center(
                      child: Text('No guardians yet',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ),
                  );
                }
                return Row(
                  children: [
                    for (var i = 0; i < docs.length; i++)
                      Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                        child: _avatarThumb(
                            (docs[i].data()
                                    as Map<String, dynamic>)['photoURL']
                                as String?,
                            36,
                            ring: i == 0 ? _gold : Colors.white24),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------- ADVANCED ROOM ----------
  Widget _advancedRoomCard() {
    final samples = const [
      'https://images.unsplash.com/photo-1505236858219-8359eb29e329?w=200',
      'https://images.unsplash.com/photo-1521336575822-6da63fb45455?w=200',
      'https://images.unsplash.com/photo-1517462964-21fdcec3f25b?w=200',
    ];
    return _shell(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Text('Advanced Room',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                Spacer(),
                Text('View all',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                Icon(Icons.chevron_right,
                    color: Colors.white38, size: 14),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final url in samples)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(url,
                          width: 40, height: 40, fit: BoxFit.cover),
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text('+24',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- ACTION BAR ----------
  Widget _actionBar(BuildContext context, AppUser u) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _actionBtn(
            gradient: const [_purple, Color(0xFF3B82F6)],
            icon: Icons.mic,
            label: 'Voice Room',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        _actionBtn(
          gradient: const [Color(0xFFEF4444), Color(0xFFEC4899)],
          icon: Icons.card_giftcard,
          onTap: () async {
            final me = FirebaseAuth.instance.currentUser!;
            final picked = await showGiftPicker(context);
            if (picked == null) return;
            await GiftService().sendGift(
                fromUid: me.uid, toUid: u.uid, gift: picked);
          },
          width: 64,
        ),
        const SizedBox(width: 10),
        _actionBtn(
          color: _card,
          icon: Icons.chat_bubble_outline,
          width: 64,
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatScreen(otherUid: u.uid),
            ));
          },
        ),
      ],
    );
  }

  Widget _actionBtn({
    List<Color>? gradient,
    Color? color,
    required IconData icon,
    String? label,
    double? width,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 52,
        width: width,
        decoration: BoxDecoration(
          color: color,
          gradient: gradient != null ? LinearGradient(colors: gradient) : null,
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- helpers ----------
  Widget _shell({Widget? child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: child,
      ),
    );
  }

  Widget _avatarThumb(String? photoOrUid, double size,
      {Color ring = Colors.transparent}) {
    final isUrl = (photoOrUid ?? '').startsWith('http');
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: _cardSoft,
        backgroundImage: isUrl ? NetworkImage(photoOrUid!) : null,
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$n';
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
