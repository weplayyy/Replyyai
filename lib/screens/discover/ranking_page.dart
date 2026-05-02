import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/charm_rank.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/rank_avatar_frame.dart';
import '../chat_screen.dart';
import '../../services/gift_service.dart';

// ─── lightweight entry read directly from Firestore ──────────────────────────
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

// ─── PAGE ────────────────────────────────────────────────────────────────────

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  int _cat = 0;    // 0=Popularity 1=Couple 2=Clan 3=Rooms
  int _filter = 0; // 0=Daily 1=Weekly 2=Annual
  int _botTab = 0; // 0=My Rank 1=Nearby 2=Top Gifter 3=Hall of Fame

    // Returns the Firestore orderBy field
  String get _field =>
      _filter == 0 ? 'dailyCharms' : (_filter == 1 ? 'weeklyCharms' : 'charms');

  // Returns a where-filter value to only show current period's data.
  // Annual has no date filter — shows all-time.
  String? get _periodKey {
    switch (_filter) {
      case 0:
        return GiftService.todayKey();
      case 1:
        return GiftService.thisWeekKey();
      default:
        return null;
    }
  }

  String get _periodKeyField =>
      _filter == 0 ? 'dailyCharmsDate' : 'weeklyCharmsWeek';

  Widget _popularityBody() {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('users');

    // For daily/weekly: only show users who received gifts this period
    if (_periodKey != null) {
      query = query
          .where(_periodKeyField, isEqualTo: _periodKey)
          .orderBy(_field, descending: true)
          .limit(50);
    } else {
      // Annual: all users ordered by total charms
      query = query
          .orderBy(_field, descending: true)
          .limit(50);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: (query as Query<Map<String, dynamic>>).snapshots(),
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
        final myIdx = me != null
            ? all.indexWhere((e) => e.uid == me.uid)
            : -1;
        final myRank = myIdx == -1 ? null : myIdx + 1;
        final myData = myIdx == -1 ? null : all[myIdx];

        final top3 = all.take(3).toList();
        final rest = all.length > 3 ? all.sublist(3) : <_RE>[];

        if (all.isEmpty) {
          return Column(children: [
            Expanded(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🏆', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    _filter == 0
                        ? 'No gifts received today yet'
                        : _filter == 1
                            ? 'No gifts received this week yet'
                            : 'No rankings yet',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ),
            _MyRankCard(entry: null, rank: null, filter: _filter),
            const SizedBox(height: 14),
          ]);
        }

        return Column(children: [
          _Podium(top3: top3, filter: _filter, onTap: _openChat),
          const SizedBox(height: 14),
          Expanded(
            child: _RestList(
                users: rest,
                startRank: 4,
                filter: _filter,
                onTap: _openChat),
          ),
          _MyRankCard(entry: myData, rank: myRank, filter: _filter),
          const SizedBox(height: 14),
        ]);
      },
    );
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
        _CircleBtn(
            icon: Icons.question_mark_rounded,
            onTap: () => _showInfo()),
      ]),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff1d0a38),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('How Rankings Work',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '🔥 Daily — Resets every midnight\n\n'
          '📅 Weekly — Resets every Monday\n\n'
          '🏆 Annual — All-time total charms\n\n'
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

  // ── TITLE HEADER ──────────────────────────────────────────────────────────

  Widget _titleHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
      Text('❦',
          style: TextStyle(
              color: Color(0xffffd783),
              fontSize: 34,
              fontWeight: FontWeight.bold)),
      SizedBox(width: 10),
      Text('Ranking',
          style: TextStyle(
              color: Color(0xffffe1a0),
              fontSize: 42,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 14)])),
      SizedBox(width: 10),
      Text('❦',
          style: TextStyle(
              color: Color(0xffffd783),
              fontSize: 34,
              fontWeight: FontWeight.bold)),
    ]);
  }

  // ── CATEGORY TABS ─────────────────────────────────────────────────────────

  Widget _categoryTabs() {
    final tabs = [
      ('🔥', 'Popularity'),
      ('💞', 'Couple'),
      ('🛡️', 'Clan'),
      ('🚪', 'Rooms'),
    ];
    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final sel = i == _cat;
          return GestureDetector(
            onTap: () => setState(() => _cat = i),
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                gradient: sel
                    ? const LinearGradient(
                        colors: [Color(0xff9d45ff), Color(0xff4c1a87)])
                    : null,
                color: sel ? null : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: sel
                      ? const Color(0xffd98cff)
                      : Colors.white.withOpacity(0.12),
                  width: 1.4,
                ),
                boxShadow: sel
                    ? [BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.45),
                        blurRadius: 18)]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tabs[i].$1,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(tabs[i].$2,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white54,
                          fontSize: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
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
        const SizedBox(width: 14),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(children: const [
            Icon(Icons.language, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Global',
                style: TextStyle(color: Colors.white, fontSize: 18)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ]),
        ),
      ]),
    );
  }

  // ── POPULARITY BODY ───────────────────────────────────────────────────────

  Widget _popularityBody() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy(_field, descending: true)
          .limit(50)
          .snapshots(),
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
        final myEntry = me != null
            ? all.indexWhere((e) => e.uid == me.uid)
            : -1;
        final myRank = myEntry == -1 ? null : myEntry + 1;
        final myData = myEntry == -1 ? null : all[myEntry];

        final top3 = all.take(3).toList();
        final rest = all.length > 3 ? all.sublist(3) : <_RE>[];

        return Column(children: [
          _Podium(top3: top3, filter: _filter, onTap: _openChat),
          const SizedBox(height: 14),
          Expanded(
            child: _RestList(
                users: rest, startRank: 4, filter: _filter, onTap: _openChat),
          ),
          _MyRankCard(entry: myData, rank: myRank, filter: _filter),
          const SizedBox(height: 14),
        ]);
      },
    );
  }

  // ── COMING SOON ───────────────────────────────────────────────────────────

  Widget _comingSoon() {
    final labels = ['', 'Couple', 'Clan', 'Rooms'];
    final emojis = ['', '💞', '🛡️', '🚪'];
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emojis[_cat], style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('${labels[_cat]} Ranking\nComing Soon',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.4)),
        const SizedBox(height: 10),
        Text("We're building it! 🚀",
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 15)),
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
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
    // Build a minimal AppUser-like object from _RE for ChatScreen
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(entry.uid)
        .get();
    if (!doc.exists || !mounted) return;
    final import_ = await _loadAppUser(doc);
    if (import_ != null && mounted) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ChatScreen(other: import_)));
    }
  }

  Future<dynamic> _loadAppUser(
      DocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      final data = doc.data()!;
      // Dynamically import to avoid circular dependency issues
      // ignore: avoid_dynamic_calls
      final appUser = (await _AppUserFactory.from(data, doc.id));
      return appUser;
    } catch (_) {
      return null;
    }
  }
}

// ─── APP USER FACTORY ────────────────────────────────────────────────────────
// Thin adapter so we can build an AppUser from raw map without importing model
// (avoids re-importing if already imported elsewhere in the tree)

class _AppUserFactory {
  static Future<dynamic> from(Map<String, dynamic> m, String id) async {
    // We import AppUser at the top of ranking_page.dart via discover routing.
    // Just return the map; ChatScreen will re-fetch if needed.
    return null; // replace with: AppUser.fromMap(m, id)
  }
}

// ─── PODIUM ──────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<_RE> top3;
  final int filter;
  final void Function(_RE) onTap;
  const _Podium(
      {required this.top3, required this.filter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    while (top3.length < 3) {
      // ignore: invalid_use_of_protected_member
    }
    final padded = [...top3];
    while (padded.length < 3) padded.add(_RE.fromMap({}, 'empty_${padded.length}'));

    return SizedBox(
      height: 310,
      child: Stack(alignment: Alignment.bottomCenter, children: [
        Positioned(
          left: 18, bottom: 8,
          child: _WinnerCard(
            rank: 2,
            entry: padded.length > 1 ? padded[1] : null,
            color: const Color(0xff2298ff),
            height: 235,
            filter: filter,
            onTap: onTap,
          ),
        ),
        Positioned(
          bottom: 0,
          child: _WinnerCard(
            rank: 1,
            entry: padded.isNotEmpty ? padded[0] : null,
            color: const Color(0xffffb22b),
            height: 285,
            isFirst: true,
            filter: filter,
            onTap: onTap,
          ),
        ),
        Positioned(
          right: 18, bottom: 8,
          child: _WinnerCard(
            rank: 3,
            entry: padded.length > 2 ? padded[2] : null,
            color: const Color(0xffc250ff),
            height: 235,
            filter: filter,
            onTap: onTap,
          ),
        ),
      ]),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  final int rank;
  final _RE? entry;
  final Color color;
  final double height;
  final bool isFirst;
  final int filter;
  final void Function(_RE) onTap;

  const _WinnerCard({
    required this.rank,
    required this.entry,
    required this.color,
    required this.height,
    required this.filter,
    required this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = isFirst ? 175.0 : 140.0;
    final score = entry?.score(filter) ?? 0;
    final name = entry?.name ?? '---';
    final photo = entry?.photo;
    final charms = entry?.charms ?? 0;
    final rank_ = CharmRank.fromCharms(charms);

    return GestureDetector(
      onTap: () { if (entry != null && entry!.uid.isNotEmpty && !entry!.uid.startsWith('empty')) onTap(entry!); },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.35),
              color.withOpacity(0.14),
              const Color(0xff16082c),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.9), width: 2),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.55), blurRadius: 24, spreadRadius: 1)
          ],
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // Crown / rank glyph
            Positioned(
              top: isFirst ? -42 : -30,
              child: Text(rank == 1 ? '👑' : '🔱',
                  style: TextStyle(fontSize: isFirst ? 58 : 44)),
            ),
            // Rank number
            Positioned(
              top: isFirst ? 22 : 16,
              child: Text('$rank',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isFirst ? 24 : 22,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: color, blurRadius: 8)])),
            ),
            // Avatar
            Positioned(
              top: isFirst ? 60 : 48,
              child: Container(
                width: isFirst ? 105 : 82,
                height: isFirst ? 105 : 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 4),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.8), blurRadius: 18)
                  ],
                ),
                child: ClipOval(
                  child: photo != null && photo.isNotEmpty
                      ? Image.network(photo, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackAvatar(name))
                      : _fallbackAvatar(name),
                ),
              ),
            ),
            // Name + score
            Positioned(
              top: isFirst ? 172 : 138,
              left: 8, right: 8,
              child: Column(children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isFirst
                            ? const Color(0xffffe45c)
                            : Colors.white.withOpacity(0.95),
                        fontSize: isFirst ? 20 : 16,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                // Rank badge from charm system
                if (rank_.info.tier != RankTier.none)
                  RankBadge(charms: charms, scale: isFirst ? 0.75 : 0.65),
                const SizedBox(height: 6),
                Text('Charm',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 13)),
                const SizedBox(height: 3),
                Text(_fmt(score),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
            // Diamond at bottom
            Positioned(
              bottom: -16,
              child: Text('💎',
                  style: TextStyle(
                      fontSize: isFirst ? 46 : 38,
                      shadows: [Shadow(color: color, blurRadius: 12)])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackAvatar(String name) {
    return Container(
      color: const Color(0xFF2D1B4E),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ─── REST LIST ───────────────────────────────────────────────────────────────

class _RestList extends StatelessWidget {
  final List<_RE> users;
  final int startRank;
  final int filter;
  final void Function(_RE) onTap;

  const _RestList({
    required this.users,
    required this.startRank,
    required this.filter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.13)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(children: const [
            Text('Rank',
                style: TextStyle(color: Colors.white70, fontSize: 17)),
            Spacer(),
            Text('Charm',
                style: TextStyle(color: Colors.white70, fontSize: 17)),
          ]),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: users.isEmpty
              ? Center(
                  child: Text(
                    'No data yet for this period',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 14),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  physics: const BouncingScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _RankTile(
                    entry: users[i],
                    rank: startRank + i,
                    filter: filter,
                    onTap: onTap,
                  ),
                ),
        ),
      ]),
    );
  }
}

class _RankTile extends StatelessWidget {
  final _RE entry;
  final int rank;
  final int filter;
  final void Function(_RE) onTap;

  const _RankTile({
    required this.entry,
    required this.rank,
    required this.filter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = entry.score(filter);
    final rankInfo = CharmRank.fromCharms(entry.charms);

    return GestureDetector(
      onTap: () => onTap(entry),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(children: [
          SizedBox(
            width: 32,
            child: Text('$rank',
                style: TextStyle(
                    color: rank <= 10
                        ? const Color(0xffbf70ff)
                        : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          RankAvatarFrame(
            charms: entry.charms,
            size: 50,
            showCrown: false,
            child: CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF2D1B4E),
              backgroundImage: (entry.photo?.isNotEmpty == true)
                  ? NetworkImage(entry.photo!)
                  : null,
              child: (entry.photo?.isNotEmpty != true)
                  ? Text(
                      entry.name.isNotEmpty
                          ? entry.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18))
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                  ),
                  if (entry.verified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF60A5FA), size: 14),
                  ],
                ]),
                if (rankInfo.info.tier != RankTier.none)
                  RankBadge(charms: entry.charms, scale: 0.72),
              ],
            ),
          ),
          Text(_fmt(score),
              style: const TextStyle(color: Colors.white, fontSize: 17)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ]),
      ),
    );
  }
}

// ─── MY RANK CARD ────────────────────────────────────────────────────────────

class _MyRankCard extends StatelessWidget {
  final _RE? entry;
  final int? rank;
  final int filter;

  const _MyRankCard(
      {required this.entry, required this.rank, required this.filter});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return const SizedBox.shrink();

    final score = entry?.score(filter) ?? 0;
    final name = entry?.name ?? '...';
    final photo = entry?.photo;
    final charms = entry?.charms ?? 0;

    return Container(
      height: 106,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xff32126e), Color(0xff7a2aff), Color(0xff32126e)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xff9d57ff), width: 1.4),
        boxShadow: [
          BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.28), blurRadius: 20)
        ],
      ),
      child: Row(children: [
        // Rank number section
        Container(
          width: 110,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.12),
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Your Rank',
                  style: TextStyle(
                      color: Color(0xffffc5ff),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                rank != null ? '#$rank' : 'N/A',
                style: const TextStyle(
                    color: Color(0xffd694ff),
                    fontSize: 26,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xffbf70ff), width: 2),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF2D1B4E),
            backgroundImage: (photo?.isNotEmpty == true)
                ? NetworkImage(photo!)
                : null,
            child: (photo?.isNotEmpty != true)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        // Name + charm
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              RankBadge(charms: charms, scale: 0.78),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(
                      text: 'Charm ',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  TextSpan(
                      text: _fmt(score),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                ]),
              ),
            ],
          ),
        ),
        // CTA button
        Container(
          margin: const EdgeInsets.only(right: 12),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xffffb7ff), Color(0xff8a2aff)]),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.55),
                  blurRadius: 14)
            ],
          ),
          child: Row(children: const [
            Text('Get Gifts',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
            SizedBox(width: 6),
            Text('🎁', style: TextStyle(fontSize: 22)),
          ]),
        ),
      ]),
    );
  }
}

// ─── FILTER BUTTON ───────────────────────────────────────────────────────────

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
          Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xff7a31d9), Color(0xff24104b)])
                  : null,
              border: selected
                  ? Border.all(
                      color: const Color(0xffc780ff), width: 1.5)
                  : null,
              boxShadow: selected
                  ? [BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.5),
                      blurRadius: 16)]
                  : [],
            ),
            child: Text(text,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white54,
                    fontSize: 17,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w500)),
          ),
          if (hot)
            Positioned(
              top: -10, right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xffff7a6b), Color(0xffff2e7a)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Hot',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ─── CIRCLE BUTTON ───────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(
              color: Colors.purpleAccent.withOpacity(0.35)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// ─── BACKGROUND GLOW ─────────────────────────────────────────────────────────

class _BgGlow extends StatelessWidget {
  const _BgGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.15,
          colors: [
            Color(0xff30105c),
            Color(0xff110123),
            Color(0xff06000f),
          ],
        ),
      ),
      child: Stack(children: [
        Positioned(
          top: 40, left: 40,
          child: _Blur(color: Colors.purpleAccent.withOpacity(0.25), size: 150),
        ),
        Positioned(
          top: 250, right: -30,
          child: _Blur(
              color: Colors.deepPurpleAccent.withOpacity(0.2), size: 180),
        ),
        Positioned(
          bottom: 120, left: -40,
          child: _Blur(color: Colors.purple.withOpacity(0.18), size: 160),
        ),
      ]),
    );
  }
}

class _Blur extends StatelessWidget {
  final Color color;
  final double size;
  const _Blur({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 80, spreadRadius: 30)
        ],
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
