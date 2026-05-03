import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../models/charm_rank.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/rank_avatar_frame.dart';
import '../chat_screen.dart';
import '../../services/gift_service.dart';
import 'dart:math' as math;

// ─── Lightweight Firestore entry (Popularity) ────────────────────────────────

class _RE {
  final String uid;
  final String name;
  final String? photo;
  final bool verified;
  final int charms;
  final int daily;
  final int weekly;

  _RE.fromMap(Map<String, dynamic> m, String id)
      : uid = id,
        name = (m['displayName'] ?? 'User') as String,
        photo = m['photoURL'] as String?,
        verified = (m['isVerified'] ?? false) as bool,
        charms = (m['charms'] ?? 0) as int,
        daily = (m['dailyCharms'] ?? 0) as int,
        weekly = (m['weeklyCharms'] ?? 0) as int;

  int score(int filter) =>
      filter == 0 ? daily : (filter == 1 ? weekly : charms);
}

// ─── Lightweight Couple entry ─────────────────────────────────────────────────

class _CoupleEntry {
  final String coupleId;
  final String user1Name;
  final String user2Name;
  final String? user1Photo;
  final String? user2Photo;
  final int heartPoints;
  final int dailyHearts;
  final int weeklyHearts;

  _CoupleEntry.fromMap(Map<String, dynamic> m, String id)
      : coupleId = id,
        user1Name = (m['user1Name'] ?? 'User') as String,
        user2Name = (m['user2Name'] ?? 'User') as String,
        user1Photo = m['user1Photo'] as String?,
        user2Photo = m['user2Photo'] as String?,
        heartPoints = (m['heartPoints'] ?? 0) as int,
        dailyHearts = (m['dailyHearts'] ?? 0) as int,
        weeklyHearts = (m['weeklyHearts'] ?? 0) as int;

  int score(int filter) =>
      filter == 0 ? dailyHearts : (filter == 1 ? weeklyHearts : heartPoints);
}

// ─── Lightweight Clan entry ───────────────────────────────────────────────────

class _ClanEntry {
  final String clanId;
  final String name;
  final String? photo;
  final int members;
  final int coins;
  final int dailyCoins;
  final int weeklyCoins;

  _ClanEntry.fromMap(Map<String, dynamic> m, String id)
      : clanId = id,
        name = (m['name'] ?? 'Clan') as String,
        photo = m['photoURL'] as String?,
        members = (m['memberCount'] ?? 0) as int,
        coins = (m['clanCoins'] ?? 0) as int,
        dailyCoins = (m['dailyCoins'] ?? 0) as int,
        weeklyCoins = (m['weeklyCoins'] ?? 0) as int;

  int score(int filter) =>
      filter == 0 ? dailyCoins : (filter == 1 ? weeklyCoins : coins);
}

// ─── Lightweight Room entry ───────────────────────────────────────────────────

class _RoomEntry {
  final String roomId;
  final String name;
  final String? photo;
  final int listeners;
  final int totalGifts;
  final String ownerName;

  _RoomEntry.fromMap(Map<String, dynamic> m, String id)
      : roomId = id,
        name = (m['name'] ?? 'Room') as String,
        photo = m['coverPhoto'] as String?,
        listeners = (m['listenerCount'] ?? 0) as int,
        totalGifts = (m['totalGifts'] ?? 0) as int,
        ownerName = (m['ownerName'] ?? '') as String;
}

// ─── PAGE ────────────────────────────────────────────────────────────────────

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  int _cat = 0;    // 0=Popularity 1=Couple 2=Clan 3=Rooms
  int _filter = 0; // 0=Daily 1=Weekly 2=Annual
  int _botTab = 0;
  String _region = 'Global';

  String get _field =>
      _filter == 0 ? 'dailyCharms' : (_filter == 1 ? 'weeklyCharms' : 'charms');

  String? get _periodKey {
    if (_filter == 0) return GiftService.todayKey();
    if (_filter == 1) return GiftService.thisWeekKey();
    return null;
  }

  String get _periodKeyField =>
      _filter == 0 ? 'dailyCharmsDate' : 'weeklyCharmsWeek';

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff080014),
      body: SafeArea(
        child: Stack(children: [
          const _BgGlow(),
          Column(children: [
            _topBar(),
            const SizedBox(height: 4),
            _titleHeader(),
            const SizedBox(height: 10),
            _categoryTabs(),
            const SizedBox(height: 10),
            _timeFilter(),
            const SizedBox(height: 10),
            Expanded(child: _body()),
            _bottomNav(),
            const SizedBox(height: 10),
          ]),
        ]),
      ),
    );
  }

  Widget _body() {
    switch (_cat) {
      case 0: return _popularityBody();
      case 1: return _coupleBody();
      case 2: return _clanBody();
      case 3: return _roomsBody();
      default: return _popularityBody();
    }
  }

  // ── TOP BAR ────────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(children: [
        _CircleBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context)),
        const Spacer(),
        _CircleBtn(icon: Icons.question_mark_rounded, onTap: _showInfo),
      ]),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff1d0a38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('How Rankings Work',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '🔥 Daily — Resets every midnight\n\n'
          '📅 Weekly — Resets every Monday\n\n'
          '🏆 Annual — All-time total\n\n'
          'Earn charms by receiving gifts in rooms!',
          style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.6),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it',
                  style: TextStyle(color: Color(0xffbf70ff)))),
        ],
      ),
    );
  }

  // ── TITLE HEADER (image-style golden banner) ───────────────────────────────

  Widget _titleHeader() {
    return SizedBox(
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sparkle stars
          ..._sparkles(),
          // Left laurel wreath
          Positioned(
            left: 30,
            child: _LaurelWreath(mirrored: false),
          ),
          // Right laurel wreath
          Positioned(
            right: 30,
            child: _LaurelWreath(mirrored: true),
          ),
          // Golden "Ranking" text
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFE566),
                Color(0xFFFFC200),
                Color(0xFFFFE566),
                Color(0xFFB8860B),
              ],
              stops: [0.0, 0.3, 0.6, 1.0],
            ).createShader(bounds),
            child: const Text(
              'Ranking',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Color(0xFFFFAA00),
                    blurRadius: 20,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _sparkles() {
    final positions = [
      (0.15, 0.1, 10.0),
      (0.12, 0.8, 8.0),
      (0.82, 0.15, 9.0),
      (0.85, 0.75, 11.0),
      (0.5, 0.05, 7.0),
      (0.35, 0.9, 6.0),
      (0.65, 0.85, 8.0),
    ];
    return positions.map((p) {
      return Positioned(
        left: MediaQuery.of(context).size.width * p.$1,
        top: 72 * p.$2,
        child: _Sparkle(size: p.$3),
      );
    }).toList();
  }

  // ── CATEGORY TABS ─────────────────────────────────────────────────────────

  Widget _categoryTabs() {
    final tabs = [
      (Icons.local_fire_department, '🔥', 'Popularity', const Color(0xffFF6B35)),
      (Icons.favorite, '💞', 'Couple', const Color(0xffFF4081)),
      (Icons.shield, '🛡️', 'Clan', const Color(0xff4FC3F7)),
      (Icons.meeting_room, '🚪', 'Rooms', const Color(0xffCE93D8)),
    ];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sel = i == _cat;
          final accent = tabs[i].$4;
          return GestureDetector(
            onTap: () => setState(() => _cat = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 118,
              decoration: BoxDecoration(
                gradient: sel
                    ? LinearGradient(
                        colors: [
                          accent.withOpacity(0.7),
                          const Color(0xff4c1a87),
                        ],
                      )
                    : null,
                color: sel ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: sel ? accent : Colors.white.withOpacity(0.12),
                  width: sel ? 1.8 : 1.2,
                ),
                boxShadow: sel
                    ? [BoxShadow(
                        color: accent.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 1)]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tabs[i].$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 5),
                  Text(tabs[i].$3,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── TIME FILTER ───────────────────────────────────────────────────────────

  Widget _timeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(children: [
              _FilterBtn(
                  text: 'Daily',
                  selected: _filter == 0,
                  onTap: () => setState(() => _filter = 0)),
              _FilterBtn(
                  text: 'Weekly',
                  selected: _filter == 1,
                  onTap: () => setState(() => _filter = 1)),
              _FilterBtn(
                  text: 'Annual',
                  selected: _filter == 2,
                  hot: true,
                  onTap: () => setState(() => _filter = 2)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showRegionPicker,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(children: [
              const Icon(Icons.language, color: Colors.white70, size: 20),
              const SizedBox(width: 6),
              Text(_region,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 18),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showRegionPicker() {
    final regions = ['Global', 'Asia', 'Europe', 'Americas', 'Middle East', 'Africa'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1d0a38),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        const Text('Select Region',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...regions.map((r) => ListTile(
          leading: Icon(
            r == 'Global' ? Icons.language : Icons.location_on,
            color: _region == r ? const Color(0xffbf70ff) : Colors.white54,
          ),
          title: Text(r,
              style: TextStyle(
                  color: _region == r ? const Color(0xffbf70ff) : Colors.white,
                  fontWeight: _region == r ? FontWeight.bold : FontWeight.normal)),
          trailing: _region == r
              ? const Icon(Icons.check, color: Color(0xffbf70ff))
              : null,
          onTap: () {
            setState(() => _region = r);
            Navigator.pop(context);
          },
        )),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ── POPULARITY BODY ───────────────────────────────────────────────────────

  Widget _popularityBody() {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('users');

    if (_periodKey != null) {
      query = query
          .where(_periodKeyField, isEqualTo: _periodKey)
          .orderBy(_field, descending: true)
          .limit(50);
    } else {
      query = query.orderBy(_field, descending: true).limit(50);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xffbf70ff)));
        }
        final all = snap.data!.docs
            .map((d) => _RE.fromMap(d.data(), d.id))
            .where((e) => e.score(_filter) > 0)
            .toList();

        final me = FirebaseAuth.instance.currentUser;
        final myIdx = me != null ? all.indexWhere((e) => e.uid == me.uid) : -1;
        final myRank = myIdx == -1 ? null : myIdx + 1;
        final myData = myIdx == -1 ? null : all[myIdx];
        final top3 = all.take(3).toList();
        final rest = all.length > 3 ? all.sublist(3) : <_RE>[];

        if (all.isEmpty) {
          return _emptyState(
            _filter == 0 ? 'No gifts received today yet'
                : _filter == 1 ? 'No gifts received this week yet'
                : 'No rankings yet',
          );
        }
        return Column(children: [
          _Podium(top3: top3, filter: _filter, onTap: _openChat),
          const SizedBox(height: 14),
          Expanded(
              child: _RestList(
                  users: rest, startRank: 4, filter: _filter, onTap: _openChat)),
          _MyRankCard(entry: myData, rank: myRank, filter: _filter),
          const SizedBox(height: 14),
        ]);
      },
    );
  }

  // ── COUPLE BODY ───────────────────────────────────────────────────────────

  Widget _coupleBody() {
    final coupleField = _filter == 0 ? 'dailyHearts'
        : _filter == 1 ? 'weeklyHearts' : 'heartPoints';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('couples')
          .orderBy(coupleField, descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xffFF4081)));
        }
        final all = snap.data!.docs
            .map((d) => _CoupleEntry.fromMap(d.data(), d.id))
            .where((e) => e.score(_filter) > 0)
            .toList();

        if (all.isEmpty) {
          return _emptyState('No couple rankings yet\nBe the first couple! 💞');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: all.length,
          itemBuilder: (_, i) => _CoupleRow(entry: all[i], rank: i + 1, filter: _filter),
        );
      },
    );
  }

  // ── CLAN BODY ─────────────────────────────────────────────────────────────

  Widget _clanBody() {
    final clanField = _filter == 0 ? 'dailyCoins'
        : _filter == 1 ? 'weeklyCoins' : 'clanCoins';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('clans')
          .orderBy(clanField, descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xff4FC3F7)));
        }
        final all = snap.data!.docs
            .map((d) => _ClanEntry.fromMap(d.data(), d.id))
            .where((e) => e.score(_filter) > 0)
            .toList();

        if (all.isEmpty) {
          return _emptyState('No clan rankings yet\nCreate a clan to compete! 🛡️');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: all.length,
          itemBuilder: (_, i) => _ClanRow(entry: all[i], rank: i + 1, filter: _filter),
        );
      },
    );
  }

  // ── ROOMS BODY ────────────────────────────────────────────────────────────

  Widget _roomsBody() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('status', isEqualTo: 'live')
          .orderBy('listenerCount', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xffCE93D8)));
        }
        final all = snap.data!.docs
            .map((d) => _RoomEntry.fromMap(d.data(), d.id))
            .toList();

        if (all.isEmpty) {
          return _emptyState('No live rooms right now\nStart a room to appear here! 🚪');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: all.length,
          itemBuilder: (_, i) => _RoomRow(entry: all[i], rank: i + 1),
        );
      },
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🏆', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(msg,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 16, height: 1.5)),
      ]),
    );
  }

  // ── BOTTOM NAV ────────────────────────────────────────────────────────────

  Widget _bottomNav() {
    final items = [
      (Icons.person, 'My Rank'),
      (Icons.location_on, 'Nearby'),
      (Icons.card_giftcard, 'Top Gifter'),
      (Icons.emoji_events, 'Hall of Fame'),
    ];
    return Container(
      height: 78,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xff1d0a38).withOpacity(0.95),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final sel = i == _botTab;
          return GestureDetector(
            onTap: () {
              if (i == 0) {
                setState(() => _botTab = i);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${items[i].$2} coming soon!'),
                  backgroundColor: const Color(0xff3d1080),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[i].$1,
                      color: sel
                          ? const Color(0xffbf70ff)
                          : Colors.white.withOpacity(0.35),
                      size: 28),
                  const SizedBox(height: 5),
                  Text(items[i].$2,
                      style: TextStyle(
                          color: sel
                              ? Colors.white
                              : Colors.white.withOpacity(0.38),
                          fontSize: 13)),
                ]),
          );
        }),
      ),
    );
  }

  Future<void> _openChat(_RE entry) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || entry.uid == me.uid) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(entry.uid)
        .get();
    if (!doc.exists || !mounted) return;
    final u = AppUser.fromMap(doc.data()!, doc.id);
    if (mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ChatScreen(other: u)));
    }
  }
}

// ─── LAUREL WREATH (drawn with Flutter) ──────────────────────────────────────

class _LaurelWreath extends StatelessWidget {
  final bool mirrored;
  const _LaurelWreath({required this.mirrored});

  @override
  Widget build(BuildContext context) {
    Widget wreath = CustomPaint(
      size: const Size(60, 60),
      painter: _LaurelPainter(),
    );
    if (mirrored) {
      wreath = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: wreath,
      );
    }
    return wreath;
  }
}

class _LaurelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final stemPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Curved stem
    final stemPath = Path()
      ..moveTo(size.width * 0.7, size.height * 0.95)
      ..quadraticBezierTo(
          size.width * 0.2, size.height * 0.7,
          size.width * 0.05, size.height * 0.1);
    canvas.drawPath(stemPath, stemPaint);

    // Leaves along the stem
    final leaves = [
      (0.62, 0.85, -0.3),
      (0.5, 0.68, -0.5),
      (0.38, 0.52, -0.7),
      (0.25, 0.36, -0.9),
      (0.14, 0.22, -1.1),
    ];
    for (final leaf in leaves) {
      canvas.save();
      canvas.translate(size.width * leaf.$1, size.height * leaf.$2);
      canvas.rotate(leaf.$3);
      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-10, -8, -18, -4)
        ..quadraticBezierTo(-10, 2, 0, 0);
      canvas.drawPath(leafPath, paint);
      canvas.restore();
    }

    // Small star/dot at top
    final dotPaint = Paint()
      ..color = const Color(0xFFFFEE88)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.05, size.height * 0.08), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── SPARKLE ─────────────────────────────────────────────────────────────────

class _Sparkle extends StatelessWidget {
  final double size;
  const _Sparkle({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(),
    );
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFE566).withOpacity(0.85)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final cy = size.height / 2;
    // 4-point star
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(angle) * cx, cy + math.sin(angle) * cy),
        paint,
      );
    }
    // Diagonal shorter lines
    final paint2 = Paint()
      ..color = const Color(0xFFFFE566).withOpacity(0.5)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 + math.pi / 4;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(angle) * cx * 0.6, cy + math.sin(angle) * cy * 0.6),
        paint2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── COUPLE ROW ───────────────────────────────────────────────────────────────

class _CoupleRow extends StatelessWidget {
  final _CoupleEntry entry;
  final int rank;
  final int filter;
  const _CoupleRow({required this.entry, required this.rank, required this.filter});

  @override
  Widget build(BuildContext context) {
    final score = entry.score(filter);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        _rankBadgeNum(rank),
        const SizedBox(width: 10),
        _twoAvatars(entry.user1Photo, entry.user2Photo),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${entry.user1Name} & ${entry.user2Name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            Text('💎 $score hearts',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
          ]),
        ),
        const Text('💞', style: TextStyle(fontSize: 20)),
      ]),
    );
  }

  Widget _twoAvatars(String? p1, String? p2) {
    return SizedBox(
      width: 56,
      height: 38,
      child: Stack(children: [
        Positioned(
          left: 0,
          child: _avatar(p1, 'A', const Color(0xffFF4081)),
        ),
        Positioned(
          left: 20,
          child: _avatar(p2, 'B', const Color(0xffE040FB)),
        ),
      ]),
    );
  }

  Widget _avatar(String? photo, String fallback, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: ClipOval(
        child: photo != null && photo.isNotEmpty
            ? Image.network(photo, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fb(fallback, color))
            : _fb(fallback, color),
      ),
    );
  }

  Widget _fb(String t, Color c) => Container(
    color: c.withOpacity(0.3),
    child: Center(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 14))),
  );
}

// ─── CLAN ROW ─────────────────────────────────────────────────────────────────

class _ClanRow extends StatelessWidget {
  final _ClanEntry entry;
  final int rank;
  final int filter;
  const _ClanRow({required this.entry, required this.rank, required this.filter});

  @override
  Widget build(BuildContext context) {
    final score = entry.score(filter);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        _rankBadgeNum(rank),
        const SizedBox(width: 10),
        _avatar(entry.photo, entry.name, const Color(0xff4FC3F7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            Text('👥 ${entry.members} members · 💎 $score coins',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
          ]),
        ),
        const Text('🛡️', style: TextStyle(fontSize: 20)),
      ]),
    );
  }

  Widget _avatar(String? photo, String name, Color color) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2)),
      child: ClipOval(
        child: photo != null && photo.isNotEmpty
            ? Image.network(photo, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fb(name, color))
            : _fb(name, color),
      ),
    );
  }

  Widget _fb(String name, Color c) => Container(
    color: c.withOpacity(0.3),
    child: Center(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
  );
}

// ─── ROOM ROW ─────────────────────────────────────────────────────────────────

class _RoomRow extends StatelessWidget {
  final _RoomEntry entry;
  final int rank;
  const _RoomRow({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        _rankBadgeNum(rank),
        const SizedBox(width: 10),
        _avatar(entry.photo, entry.name, const Color(0xffCE93D8)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            Text('👤 ${entry.listeners} live · by ${entry.ownerName}',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('LIVE',
              style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _avatar(String? photo, String name, Color color) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: photo != null && photo.isNotEmpty
            ? Image.network(photo, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fb(name, color))
            : _fb(name, color),
      ),
    );
  }

  Widget _fb(String name, Color c) => Container(
    color: c.withOpacity(0.3),
    child: Center(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
  );
}

// ─── SHARED RANK BADGE NUMBER ─────────────────────────────────────────────────

Widget _rankBadgeNum(int rank) {
  const colors = [Color(0xffffb22b), Color(0xff2298ff), Color(0xffc250ff)];
  final color = rank <= 3 ? colors[rank - 1] : Colors.white54;
  return SizedBox(
    width: 32,
    child: Text('$rank',
        textAlign: TextAlign.center,
        style: TextStyle(
            color: color,
            fontSize: rank <= 3 ? 18 : 15,
            fontWeight: FontWeight.w900)),
  );
}

// ─── PODIUM ──────────────────────────────────────────────────────────────────
// (Keep your existing _Podium, _WinnerCard, _RestList, _MyRankCard,
//  _FilterBtn, _CircleBtn, _BgGlow widgets exactly as they are below)

class _Podium extends StatelessWidget {
  final List<_RE> top3;
  final int filter;
  final void Function(_RE) onTap;
  const _Podium({required this.top3, required this.filter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final padded = [...top3];
    while (padded.length < 3) {
      padded.add(_RE.fromMap({}, 'empty_${padded.length}'));
    }
    return SizedBox(
      height: 310,
      child: Stack(alignment: Alignment.bottomCenter, children: [
        Positioned(
          left: 18,
          bottom: 8,
          child: _WinnerCard(
            rank: 2, entry: padded[1], color: const Color(0xff2298ff),
            height: 235, filter: filter, onTap: onTap,
          ),
        ),
        Positioned(
          bottom: 0,
          child: _WinnerCard(
            rank: 1, entry: padded[0], color: const Color(0xffffb22b),
            height: 285, isFirst: true, filter: filter, onTap: onTap,
          ),
        ),
        Positioned(
          right: 18,
          bottom: 8,
          child: _WinnerCard(
            rank: 3, entry: padded[2], color: const Color(0xffc250ff),
            height: 235, filter: filter, onTap: onTap,
          ),
        ),
      ]),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  final int rank;
  final _RE entry;
  final Color color;
  final double height;
  final bool isFirst;
  final int filter;
  final void Function(_RE) onTap;

  const _WinnerCard({
    required this.rank, required this.entry, required this.color,
    required this.height, required this.filter, required this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = isFirst ? 175.0 : 140.0;
    final score = entry.score(filter);
    final name = entry.uid.startsWith('empty') ? '---' : entry.name;
    final photo = entry.uid.startsWith('empty') ? null : entry.photo;
    final charms = entry.charms;
    final rankInfo = CharmRank.fromCharms(charms);
    final isEmpty = entry.uid.startsWith('empty');

    return GestureDetector(
      onTap: () { if (!isEmpty) onTap(entry); },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(isEmpty ? 0.15 : 0.35),
              color.withOpacity(isEmpty ? 0.06 : 0.14),
              const Color(0xff16082c),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(isEmpty ? 0.3 : 0.9), width: 2),
          boxShadow: isEmpty ? [] : [
            BoxShadow(color: color.withOpacity(0.55), blurRadius: 24, spreadRadius: 1)
          ],
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: isFirst ? -42 : -30,
              child: Text(rank == 1 ? '👑' : '🔱',
                  style: TextStyle(fontSize: isFirst ? 58 : 44)),
            ),
            Positioned(
              top: isFirst ? 22 : 16,
              child: Text('$rank',
                  style: TextStyle(
                      color: Colors.white, fontSize: isFirst ? 24 : 22,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: color, blurRadius: 8)])),
            ),
            Positioned(
              top: isFirst ? 60 : 48,
              child: Container(
                width: isFirst ? 105 : 82, height: isFirst ? 105 : 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 4),
                  boxShadow: isEmpty ? [] : [
                    BoxShadow(color: color.withOpacity(0.8), blurRadius: 18)
                  ],
                ),
                child: ClipOval(
                  child: photo != null && photo.isNotEmpty
                      ? Image.network(photo, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallback(name))
                      : _fallback(name),
                ),
              ),
            ),
            Positioned(
              top: isFirst ? 172 : 138,
              left: 8, right: 8,
              child: Column(children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isFirst ? const Color(0xffffe45c) : Colors.white.withOpacity(0.95),
                        fontSize: isFirst ? 20 : 16,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                if (!isEmpty && rankInfo.info.tier != RankTier.none)
                  RankBadge(charms: charms, scale: isFirst ? 0.75 : 0.65),
                const SizedBox(height: 6),
                if (!isEmpty) ...[
                  Text('Charm',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(_fmt(score),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ]),
            ),

              Widget _fallback(String name) => Container(
    color: const Color(0xFF2D1B4E),
    child: Center(
      child: Text(
        name.isNotEmpty && name != '---' ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

// ─── REST LIST ────────────────────────────────────────────────────────────────

class _RestList extends StatelessWidget {
  final List<_RE> users;
  final int startRank;
  final int filter;
  final void Function(_RE) onTap;
  const _RestList({
    required this.users, required this.startRank,
    required this.filter, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final e = users[i];
        final rank = startRank + i;
        return GestureDetector(
          onTap: () => onTap(e),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
              _rankBadgeNum(rank),
              const SizedBox(width: 10),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xff8b5cf6), width: 2),
                ),
                child: ClipOval(
                  child: e.photo != null && e.photo!.isNotEmpty
                      ? Image.network(e.photo!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fb(e.name))
                      : _fb(e.name),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                    if (e.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Color(0xff60a5fa), size: 14),
                    ],
                  ]),
                  RankBadge(charms: e.charms, scale: 0.6),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_fmt(e.score(filter)),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text('charm',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45), fontSize: 11)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _fb(String name) => Container(
    color: const Color(0xFF2D1B4E),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

// ─── MY RANK CARD ─────────────────────────────────────────────────────────────

class _MyRankCard extends StatelessWidget {
  final _RE? entry;
  final int? rank;
  final int filter;
  const _MyRankCard({required this.entry, required this.rank, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xff8b5cf6).withOpacity(0.25),
            const Color(0xff4c1a87).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xff8b5cf6).withOpacity(0.5)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xff8b5cf6).withOpacity(0.3),
          ),
          child: Center(
            child: Text(
              rank != null ? '#$rank' : '--',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (entry != null) ...[
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xff8b5cf6), width: 2),
            ),
            child: ClipOval(
              child: entry!.photo != null && entry!.photo!.isNotEmpty
                  ? Image.network(entry!.photo!, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFF2D1B4E),
                      child: Center(
                        child: Text(
                          entry!.name.isNotEmpty
                              ? entry!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(entry!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          Text(_fmt(entry!.score(filter)),
              style: const TextStyle(
                  color: Color(0xffbf70ff),
                  fontSize: 15,
                  fontWeight: FontWeight.w900)),
        ] else
          Expanded(
            child: Text('You are not ranked yet',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14)),
          ),
      ]),
    );
  }
}

// ─── FILTER BUTTON ────────────────────────────────────────────────────────────

class _FilterBtn extends StatelessWidget {
  final String text;
  final bool selected;
  final bool hot;
  final VoidCallback onTap;
  const _FilterBtn({
    required this.text,
    required this.selected,
    required this.onTap,
    this.hot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xff8b5cf6), Color(0xff6d28d9)])
                  : null,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Center(
              child: Text(text,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.white54,
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w500)),
            ),
          ),
          if (hot)
            Positioned(
              top: -8,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xffFF4500),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Hot',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ─── CIRCLE BUTTON ────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── BACKGROUND GLOW ─────────────────────────────────────────────────────────

class _BgGlow extends StatelessWidget {
  const _BgGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(
        top: -80, left: -60,
        child: Container(
          width: 280, height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xff6d28d9).withOpacity(0.35),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 100, right: -80,
        child: Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xff7c3aed).withOpacity(0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─── HELPER ──────────────────────────────────────────────────────────────────

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
