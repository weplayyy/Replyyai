import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../../models/app_user.dart';
import '../../models/charm_rank.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/rank_avatar_frame.dart';
import '../chat_screen.dart';
import '../../services/gift_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _RE {
  final String uid, name;
  final String? photo;
  final bool verified;
  final int charms, daily, weekly;
  _RE.fromMap(Map<String, dynamic> m, String id)
      : uid = id,
        name = (m['displayName'] ?? 'User') as String,
        photo = m['photoURL'] as String?,
        verified = (m['isVerified'] ?? false) as bool,
        charms = (m['charms'] ?? 0) as int,
        daily = (m['dailyCharms'] ?? 0) as int,
        weekly = (m['weeklyCharms'] ?? 0) as int;
  int score(int f) => f == 0 ? daily : (f == 1 ? weekly : charms);
}

class _CoupleEntry {
  final String coupleId, user1Name, user2Name;
  final String? user1Photo, user2Photo;
  final int heartPoints, dailyHearts, weeklyHearts;
  _CoupleEntry.fromMap(Map<String, dynamic> m, String id)
      : coupleId = id,
        user1Name = (m['user1Name'] ?? 'User') as String,
        user2Name = (m['user2Name'] ?? 'User') as String,
        user1Photo = m['user1Photo'] as String?,
        user2Photo = m['user2Photo'] as String?,
        heartPoints = (m['heartPoints'] ?? 0) as int,
        dailyHearts = (m['dailyHearts'] ?? 0) as int,
        weeklyHearts = (m['weeklyHearts'] ?? 0) as int;
  int score(int f) => f == 0 ? dailyHearts : (f == 1 ? weeklyHearts : heartPoints);
}

class _ClanEntry {
  final String clanId, name;
  final String? photo;
  final int members, coins, dailyCoins, weeklyCoins;
  _ClanEntry.fromMap(Map<String, dynamic> m, String id)
      : clanId = id,
        name = (m['name'] ?? 'Clan') as String,
        photo = m['photoURL'] as String?,
        members = (m['memberCount'] ?? 0) as int,
        coins = (m['clanCoins'] ?? 0) as int,
        dailyCoins = (m['dailyCoins'] ?? 0) as int,
        weeklyCoins = (m['weeklyCoins'] ?? 0) as int;
  int score(int f) => f == 0 ? dailyCoins : (f == 1 ? weeklyCoins : coins);
}

class _RoomEntry {
  final String roomId, name, ownerName;
  final String? photo;
  final int listeners;
  _RoomEntry.fromMap(Map<String, dynamic> m, String id)
      : roomId = id,
        name = (m['name'] ?? 'Room') as String,
        photo = m['coverPhoto'] as String?,
        listeners = (m['listenerCount'] ?? m['memberCount'] ?? 0) as int,
        ownerName = (m['ownerName'] ?? m['ownerDisplayName'] ?? '') as String;
}

// ── Page ─────────────────────────────────────────────────────────────────────

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  int _cat = 0;
  int _filter = 0;
  int _botTab = 0;

  String get _field => _filter == 0 ? 'dailyCharms' : (_filter == 1 ? 'weeklyCharms' : 'charms');
  String? get _periodKey => _filter == 0 ? GiftService.todayKey() : _filter == 1 ? GiftService.thisWeekKey() : null;
  String get _periodKeyField => _filter == 0 ? 'dailyCharmsDate' : 'weeklyCharmsWeek';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff080014),
      body: SafeArea(
        child: Stack(children: [
          _BgGlow(),
          Column(children: [
            _topBar(),
            _titleHeader(),
            const SizedBox(height: 6),
            _categoryTabs(),
            const SizedBox(height: 6),
            _timeFilter(),
            const SizedBox(height: 8),
            Expanded(child: _body()),
            _bottomNav(),
            const SizedBox(height: 8),
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

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        _CircleBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
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
        title: const Text('How Rankings Work', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '🔥 Daily — Resets every midnight\n\n📅 Weekly — Resets every Monday\n\n🏆 Annual — All-time total\n\nEarn charms by receiving gifts in rooms!',
          style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.6),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it', style: TextStyle(color: Color(0xffbf70ff))))],
      ),
    );
  }

  // ── Title header ───────────────────────────────────────────────────────────

  Widget _titleHeader() {
    return SizedBox(
      height: 60,
      child: Stack(alignment: Alignment.center, children: [
        // Sparkles
        Positioned(left: 55, top: 8, child: _SparkleWidget(size: 8)),
        Positioned(left: 42, top: 38, child: _SparkleWidget(size: 6)),
        Positioned(right: 55, top: 10, child: _SparkleWidget(size: 9)),
        Positioned(right: 44, top: 40, child: _SparkleWidget(size: 7)),
        Positioned(left: 90, top: 4, child: _SparkleWidget(size: 6)),
        Positioned(right: 90, top: 5, child: _SparkleWidget(size: 6)),
        // Wreaths
        Positioned(left: 20, child: _LaurelWreath(mirrored: false)),
        Positioned(right: 20, child: _LaurelWreath(mirrored: true)),
        // Gold "Ranking" text
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFFE566), Color(0xFFFFC200), Color(0xFFFFE566), Color(0xFFB8860B)],
            stops: [0.0, 0.3, 0.6, 1.0],
          ).createShader(b),
          child: const Text('Ranking',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
        ),
      ]),
    );
  }

  // ── Category tabs ──────────────────────────────────────────────────────────

  Widget _categoryTabs() {
    final tabs = [
      ('🔥', 'Popularity', const Color(0xffFF6B35)),
      ('💞', 'Couple',     const Color(0xffFF4081)),
      ('🛡️', 'Clan',      const Color(0xff4FC3F7)),
      ('🚪', 'Rooms',      const Color(0xffCE93D8)),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final sel = i == _cat;
          final accent = tabs[i].$3;
          return GestureDetector(
            onTap: () => setState(() => _cat = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: sel ? LinearGradient(colors: [accent.withOpacity(0.7), const Color(0xff4c1a87)]) : null,
                color: sel ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? accent : Colors.white.withOpacity(0.12), width: sel ? 1.5 : 1.0),
                boxShadow: sel ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 10)] : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(tabs[i].$1, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                Text(tabs[i].$2,
                    style: TextStyle(color: sel ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Time filter (no Global button) ────────────────────────────────────────

  Widget _timeFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(children: [
          _FilterBtn(text: 'Daily',  selected: _filter == 0, onTap: () => setState(() => _filter = 0)),
          _FilterBtn(text: 'Weekly', selected: _filter == 1, onTap: () => setState(() => _filter = 1)),
          _FilterBtn(text: 'Annual', selected: _filter == 2, hot: true, onTap: () => setState(() => _filter = 2)),
        ]),
      ),
    );
  }

  // ── Popularity body ────────────────────────────────────────────────────────

  Widget _popularityBody() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection('users');
    if (_periodKey != null) {
      q = q.where(_periodKeyField, isEqualTo: _periodKey).orderBy(_field, descending: true).limit(50);
    } else {
      q = q.orderBy(_field, descending: true).limit(50);
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xffbf70ff)));
        final all = snap.data!.docs.map((d) => _RE.fromMap(d.data(), d.id)).where((e) => e.score(_filter) > 0).toList();
        final me = FirebaseAuth.instance.currentUser;
        final myIdx = me != null ? all.indexWhere((e) => e.uid == me.uid) : -1;
        final myRank = myIdx == -1 ? null : myIdx + 1;
        final myData = myIdx == -1 ? null : all[myIdx];
        final top3 = all.take(3).toList();
        final rest = all.length > 3 ? all.sublist(3) : <_RE>[];
        if (all.isEmpty) return _emptyState(_filter == 0 ? 'No gifts received today yet' : _filter == 1 ? 'No gifts received this week yet' : 'No rankings yet');
        return Column(children: [
          _Podium(top3: top3, filter: _filter, onTap: _openChat),
          const SizedBox(height: 10),
          Expanded(child: _RestList(users: rest, startRank: 4, filter: _filter, onTap: _openChat)),
          _MyRankCard(entry: myData, rank: myRank, filter: _filter),
          const SizedBox(height: 10),
        ]);
      },
    );
  }

  // ── Couple body ────────────────────────────────────────────────────────────

  Widget _coupleBody() {
    final field = _filter == 0 ? 'dailyHearts' : _filter == 1 ? 'weeklyHearts' : 'heartPoints';
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('couples').orderBy(field, descending: true).limit(50).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xffFF4081)));
        final all = snap.data!.docs.map((d) => _CoupleEntry.fromMap(d.data(), d.id)).where((e) => e.score(_filter) > 0).toList();
        if (all.isEmpty) return _emptyState('No couple rankings yet\nBe the first couple! 💞');
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: all.length,
          itemBuilder: (_, i) => _CoupleRow(entry: all[i], rank: i + 1, filter: _filter),
        );
      },
    );
  }

  // ── Clan body ──────────────────────────────────────────────────────────────

  Widget _clanBody() {
    final field = _filter == 0 ? 'dailyCoins' : _filter == 1 ? 'weeklyCoins' : 'clanCoins';
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('clans').orderBy(field, descending: true).limit(50).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xff4FC3F7)));
        final all = snap.data!.docs.map((d) => _ClanEntry.fromMap(d.data(), d.id)).where((e) => e.score(_filter) > 0).toList();
        if (all.isEmpty) return _emptyState('No clan rankings yet\nCreate a clan to compete! 🛡️');
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: all.length,
          itemBuilder: (_, i) => _ClanRow(entry: all[i], rank: i + 1, filter: _filter),
        );
      },
    );
  }

  // ── Rooms body — fixed: no composite index needed ─────────────────────────

  Widget _roomsBody() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _emptyState('Error loading rooms\n${snap.error}');
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xffCE93D8)));
        final all = snap.data!.docs
            .map((d) => _RoomEntry.fromMap(d.data(), d.id))
            .where((r) {
              final data = snap.data!.docs.firstWhere((d) => d.id == r.roomId).data();
              final status = data['status'] as String?;
              return status == 'live' || status == null;
            })
            .toList();
        if (all.isEmpty) return _emptyState('No live rooms right now\nStart a room to appear here! 🚪');
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: all.length,
          itemBuilder: (_, i) => _RoomRow(entry: all[i], rank: i + 1),
        );
      },
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🏆', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 14),
        Text(msg, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15, height: 1.5)),
      ]),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────

  Widget _bottomNav() {
    final items = [
      (Icons.person, 'My Rank'),
      (Icons.location_on, 'Nearby'),
      (Icons.card_giftcard, 'Top Gifter'),
      (Icons.emoji_events, 'Hall of Fame'),
    ];
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(items[i].$1, color: sel ? const Color(0xffbf70ff) : Colors.white.withOpacity(0.35), size: 24),
              const SizedBox(height: 4),
              Text(items[i].$2,
                  style: TextStyle(color: sel ? Colors.white : Colors.white.withOpacity(0.38), fontSize: 11)),
            ]),
          );
        }),
      ),
    );
  }

  Future<void> _openChat(_RE entry) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || entry.uid == me.uid) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(entry.uid).get();
    if (!doc.exists || !mounted) return;
    final u = AppUser.fromMap(doc.data()!, doc.id);
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(other: u)));
  }
}

// ── Laurel wreath ─────────────────────────────────────────────────────────────

class _LaurelWreath extends StatelessWidget {
  final bool mirrored;
  const _LaurelWreath({required this.mirrored});
  @override
  Widget build(BuildContext context) {
    Widget w = CustomPaint(size: const Size(50, 50), painter: _LaurelPainter());
    if (mirrored) w = Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: w);
    return w;
  }
}

class _LaurelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill;
    final stem = Paint()..color = const Color(0xFFB8860B)..style = PaintingStyle.stroke..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()
      ..moveTo(size.width * 0.7, size.height * 0.95)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.7, size.width * 0.05, size.height * 0.1), stem);
    for (final l in [[0.62, 0.85, -0.3], [0.5, 0.68, -0.5], [0.38, 0.52, -0.7], [0.25, 0.36, -0.9], [0.14, 0.22, -1.1]]) {
      canvas.save();
      canvas.translate(size.width * l[0], size.height * l[1]);
      canvas.rotate(l[2]);
      canvas.drawPath(Path()..moveTo(0, 0)..quadraticBezierTo(-9, -7, -16, -3)..quadraticBezierTo(-9, 2, 0, 0), fill);
      canvas.restore();
    }
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.08), 3, Paint()..color = const Color(0xFFFFEE88)..style = PaintingStyle.fill);
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Sparkle ───────────────────────────────────────────────────────────────────

class _SparkleWidget extends StatelessWidget {
  final double size;
  const _SparkleWidget({required this.size});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size), painter: _SparklePainter());
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = const Color(0xFFFFE566).withOpacity(0.85)..strokeWidth = 1.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final p2 = Paint()..color = const Color(0xFFFFE566).withOpacity(0.5)..strokeWidth = 1.0..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final cx = size.width / 2, cy = size.height / 2;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawLine(Offset(cx, cy), Offset(cx + math.cos(a) * cx, cy + math.sin(a) * cy), p1);
    }
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      canvas.drawLine(Offset(cx, cy), Offset(cx + math.cos(a) * cx * 0.6, cy + math.sin(a) * cy * 0.6), p2);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Couple row ────────────────────────────────────────────────────────────────

class _CoupleRow extends StatelessWidget {
  final _CoupleEntry entry;
  final int rank, filter;
  const _CoupleRow({required this.entry, required this.rank, required this.filter});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        _rankNum(rank), const SizedBox(width: 8),
        _twoAvatars(),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${entry.user1Name} & ${entry.user2Name}', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text('💎 ${entry.score(filter)} hearts', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
        ])),
        const Text('💞', style: TextStyle(fontSize: 18)),
      ]),
    );
  }
  Widget _twoAvatars() => SizedBox(width: 50, height: 34, child: Stack(children: [
    Positioned(left: 0, child: _av(entry.user1Photo, 'A', const Color(0xffFF4081))),
    Positioned(left: 18, child: _av(entry.user2Photo, 'B', const Color(0xffE040FB))),
  ]));
  Widget _av(String? p, String fb, Color c) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 2)),
    child: ClipOval(child: p != null && p.isNotEmpty ? Image.network(p, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fb(fb, c)) : _fb(fb, c)),
  );
  Widget _fb(String t, Color c) => Container(color: c.withOpacity(0.3), child: Center(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 12))));
}

// ── Clan row ──────────────────────────────────────────────────────────────────

class _ClanRow extends StatelessWidget {
  final _ClanEntry entry;
  final int rank, filter;
  const _ClanRow({required this.entry, required this.rank, required this.filter});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        _rankNum(rank), const SizedBox(width: 8),
        _av(entry.photo, entry.name, const Color(0xff4FC3F7)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text('👥 ${entry.members} · 💎 ${entry.score(filter)} coins',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
        ])),
        const Text('🛡️', style: TextStyle(fontSize: 18)),
      ]),
    );
  }
  Widget _av(String? p, String name, Color c) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 2)),
    child: ClipOval(child: p != null && p.isNotEmpty ? Image.network(p, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fb(name, c)) : _fb(name, c)),
  );
  Widget _fb(String n, Color c) => Container(color: c.withOpacity(0.3), child: Center(child: Text(n.isNotEmpty ? n[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
}

// ── Room row ──────────────────────────────────────────────────────────────────

class _RoomRow extends StatelessWidget {
  final _RoomEntry entry;
  final int rank;
  const _RoomRow({required this.entry, required this.rank});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(children: [
        _rankNum(rank), const SizedBox(width: 8),
        _av(entry.photo, entry.name, const Color(0xffCE93D8)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text('👤 ${entry.listeners} listening · ${entry.ownerName}',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
          child: const Text('LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
  Widget _av(String? p, String name, Color c) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: c, width: 2)),
    child: ClipRRect(borderRadius: BorderRadius.circular(8), child: p != null && p.isNotEmpty ? Image.network(p, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fb(name, c)) : _fb(name, c)),
  );
  Widget _fb(String n, Color c) => Container(color: c.withOpacity(0.3), child: Center(child: Text(n.isNotEmpty ? n[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
}

// ── Shared rank number ────────────────────────────────────────────────────────

Widget _rankNum(int rank) {
  const colors = [Color(0xffffb22b), Color(0xff2298ff), Color(0xffc250ff)];
  final color = rank <= 3 ? colors[rank - 1] : Colors.white54;
  return SizedBox(width: 28, child: Text('$rank', textAlign: TextAlign.center,
      style: TextStyle(color: color, fontSize: rank <= 3 ? 16 : 13, fontWeight: FontWeight.w900)));
}

// ── Podium — Row layout so cards NEVER overlap ────────────────────────────────

class _Podium extends StatelessWidget {
  final List<_RE> top3;
  final int filter;
  final void Function(_RE) onTap;
  const _Podium({required this.top3, required this.filter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final padded = [...top3];
    while (padded.length < 3) padded.add(_RE.fromMap({}, 'empty_${padded.length}'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place — left, shorter
          Expanded(child: Padding(
            padding: const EdgeInsets.only(bottom: 0, right: 4),
            child: _WinnerCard(rank: 2, entry: padded[1], color: const Color(0xff2298ff), cardHeight: 195, isFirst: false, filter: filter, onTap: onTap),
          )),
          // 1st place — center, tallest
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _WinnerCard(rank: 1, entry: padded[0], color: const Color(0xffffb22b), cardHeight: 240, isFirst: true, filter: filter, onTap: onTap),
          )),
          // 3rd place — right, shorter
          Expanded(child: Padding(
            padding: const EdgeInsets.only(bottom: 0, left: 4),
            child: _WinnerCard(rank: 3, entry: padded[2], color: const Color(0xffc250ff), cardHeight: 195, isFirst: false, filter: filter, onTap: onTap),
          )),
        ],
      ),
    );
  }
}

// ── Winner card ───────────────────────────────────────────────────────────────

class _WinnerCard extends StatelessWidget {
  final int rank, filter;
  final _RE entry;
  final Color color;
  final double cardHeight;
  final bool isFirst;
  final void Function(_RE) onTap;

  const _WinnerCard({
    required this.rank, required this.entry, required this.color,
    required this.cardHeight, required this.isFirst,
    required this.filter, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = entry.score(filter);
    final name = entry.uid.startsWith('empty') ? '---' : entry.name;
    final photo = entry.uid.startsWith('empty') ? null : entry.photo;
    final isEmpty = entry.uid.startsWith('empty');
    final rankInfo = CharmRank.fromCharms(entry.charms);
    final avatarSize = isFirst ? 72.0 : 58.0;

    return GestureDetector(
      onTap: () { if (!isEmpty) onTap(entry); },
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(isEmpty ? 0.12 : 0.30),
              color.withOpacity(isEmpty ? 0.04 : 0.10),
              const Color(0xff16082c),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(isEmpty ? 0.25 : 0.85), width: 1.5),
          boxShadow: isEmpty ? [] : [BoxShadow(color: color.withOpacity(0.4), blurRadius: 14, spreadRadius: 0)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text(rank == 1 ? '👑' : '🔱', style: TextStyle(fontSize: isFirst ? 26 : 20)),
            const SizedBox(height: 4),
            Text('$rank', style: TextStyle(
                color: Colors.white, fontSize: isFirst ? 16 : 14,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: color, blurRadius: 6)])),
            const SizedBox(height: 6),
            Container(
              width: avatarSize, height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
                boxShadow: isEmpty ? [] : [BoxShadow(color: color.withOpacity(0.6), blurRadius: 10)],
              ),
              child: ClipOval(
                child: photo != null && photo.isNotEmpty
                    ? Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fb(name))
                    : _fb(name),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isFirst ? const Color(0xffffe45c) : Colors.white.withOpacity(0.9),
                      fontSize: isFirst ? 13 : 11, fontWeight: FontWeight.w800)),
            ),
            if (!isEmpty && rankInfo.info.tier != RankTier.none)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: RankBadge(charms: entry.charms, scale: isFirst ? 0.6 : 0.5),
              ),
            if (!isEmpty) ...[
              const SizedBox(height: 4),
              Text('💎 ${_fmt(score)}',
                  style: TextStyle(color: Colors.white, fontSize: isFirst ? 12 : 10, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Widget _fb(String name) => Container(
    color: const Color(0xFF2D1B4E),
    child: Center(child: Text(
      name.isNotEmpty && name != '---' ? name[0].toUpperCase() : '?',
      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
    )),
  );
}

// ── Rest list ─────────────────────────────────────────────────────────────────

class _RestList extends StatelessWidget {
  final List<_RE> users;
  final int startRank, filter;
  final void Function(_RE) onTap;
  const _RestList({required this.users, required this.startRank, required this.filter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final e = users[i];
        final rank = startRank + i;
        return GestureDetector(
          onTap: () => onTap(e),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
              _rankNum(rank), const SizedBox(width: 8),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xff8b5cf6), width: 2)),
                child: ClipOval(child: e.photo != null && e.photo!.isNotEmpty
                    ? Image.network(e.photo!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fb(e.name))
                    : _fb(e.name)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
                  if (e.verified) ...[const SizedBox(width: 3), const Icon(Icons.verified, color: Color(0xff60a5fa), size: 12)],
                ]),
                RankBadge(charms: e.charms, scale: 0.55),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_fmt(e.score(filter)), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                Text('charm', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _fb(String name) => Container(
    color: const Color(0xFF2D1B4E),
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
  );
}

// ── My rank card ──────────────────────────────────────────────────────────────

class _MyRankCard extends StatelessWidget {
  final _RE? entry;
  final int? rank, filter;
  const _MyRankCard({required this.entry, required this.rank, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xff8b5cf6).withOpacity(0.25),
          const Color(0xff4c1a87).withOpacity(0.4),
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xff8b5cf6).withOpacity(0.5)),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xff8b5cf6).withOpacity(0.3)),
          child: Center(child: Text(rank != null ? '#$rank' : '--',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900))),
        ),
        const SizedBox(width: 10),
        if (entry != null) ...[
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xff8b5cf6), width: 2)),
            child: ClipOval(child: entry!.photo != null && entry!.photo!.isNotEmpty
                ? Image.network(entry!.photo!, fit: BoxFit.cover)
                : Container(color: const Color(0xFF2D1B4E), child: Center(child: Text(entry!.name.isNotEmpty ? entry!.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white))))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(entry!.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
          Text(_fmt(entry!.score(filter ?? 0)),
              style: const TextStyle(color: Color(0xffbf70ff), fontSize: 14, fontWeight: FontWeight.w900)),
        ] else
          Expanded(child: Text('You are not ranked yet',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13))),
      ]),
    );
  }
}

// ── Filter button ─────────────────────────────────────────────────────────────

class _FilterBtn extends StatelessWidget {
  final String text;
  final bool selected, hot;
  final VoidCallback onTap;
  const _FilterBtn({required this.text, required this.selected, required this.onTap, this.hot = false});

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
              gradient: selected ? const LinearGradient(colors: [Color(0xff8b5cf6), Color(0xff6d28d9)]) : null,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(child: Text(text, style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 13, fontWeight: selected ? FontWeight.w800 : FontWeight.w500))),
          ),
          if (hot)
            Positioned(top: -7, right: 2, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xffFF4500), borderRadius: BorderRadius.circular(7)),
              child: const Text('Hot', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            )),
        ]),
      ),
    );
  }
}

// ── Circle button ─────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08), border: Border.all(color: Colors.white.withOpacity(0.18))),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Background glow ───────────────────────────────────────────────────────────

class _BgGlow extends StatelessWidget {
  const _BgGlow();
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(top: -80, left: -60, child: Container(width: 260, height: 260,
          decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [const Color(0xff6d28d9).withOpacity(0.35), Colors.transparent])))),
      Positioned(bottom: 100, right: -80, child: Container(width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [const Color(0xff7c3aed).withOpacity(0.25), Colors.transparent])))),
    ]);
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
