import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/rank_avatar_frame.dart';
import '../chat_screen.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  int _period = 0; // 0=Weekly 1=Monthly 2=All Time

  static const _periods = ['Weekly', 'Monthly', 'All Time'];

  String get _orderField {
    switch (_period) {
      case 0:
        return 'weeklyCharms';
      case 1:
        return 'monthlyCharms';
      default:
        return 'charms';
    }
  }

  Future<void> _openChat(AppUser u) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || u.uid == me.uid) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ChatScreen(other: u)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      body: Column(
        children: [
          _topBar(),
          _periodSelector(),
          Expanded(child: _rankList()),
          _selfBar(),
        ],
      ),
    );
  }

  // ── TOP BAR ─────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0B2E), Color(0xFF0F0A1F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            const Text('🏆',
                style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            const Text('Charm Ranking',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.4)),
              ),
              child: Row(children: const [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFFB794F6), size: 14),
                SizedBox(width: 4),
                Text('How it works',
                    style: TextStyle(
                        color: Color(0xFFB794F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ── PERIOD SELECTOR ─────────────────────────────────────────────────────

  Widget _periodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1040),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: List.generate(_periods.length, (i) {
            final sel = i == _period;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _period = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)])
                        : null,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                                color:
                                    const Color(0xFF8B5CF6).withOpacity(0.4),
                                blurRadius: 8)
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(_periods[i],
                        style: TextStyle(
                            color:
                                sel ? Colors.white : Colors.white54,
                            fontSize: 13,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── RANK LIST ───────────────────────────────────────────────────────────

  Widget _rankList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy(_orderField, descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF8B5CF6)));
        }
        final users = snap.data!.docs
            .map((d) => AppUser.fromMap(d.data(), d.id))
            .toList();
        if (users.isEmpty) {
          return Center(
            child: Text('No ranking data yet',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5))));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (users.length >= 3) ...[
              _podiumSection(users),
              const SizedBox(height: 20),
            ],
            if (users.length > 3)
              _rankListSection(
                  users.sublist(3), 4),
          ],
        );
      },
    );
  }

  // ── PODIUM ──────────────────────────────────────────────────────────────

  Widget _podiumSection(List<AppUser> users) {
    final list = List<AppUser?>.from(users);
    while (list.length < 3) list.add(null);
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Top 3',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  letterSpacing: 1.5)),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: _rankCard(list[1], 2))),
              const SizedBox(width: 8),
              Expanded(child: _rankCard(list[0], 1, isFirst: true)),
              const SizedBox(width: 8),
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: _rankCard(list[2], 3))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rankCard(AppUser? u, int rank, {bool isFirst = false}) {
    final rc = _rankColors(rank);
    return GestureDetector(
      onTap: () { if (u != null) _openChat(u); },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: rc.bg,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: rc.border.withOpacity(isFirst ? 0.95 : 0.55),
              width: isFirst ? 2 : 1.2),
          boxShadow: isFirst
              ? [BoxShadow(
                  color: rc.glow.withOpacity(0.4),
                  blurRadius: 22,
                  spreadRadius: 1)]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _podiumBadge(rank),
              const SizedBox(height: 6),
              _podiumAvatar(u, rank, isFirst),
              const SizedBox(height: 8),
              Text(u?.displayName ?? '---',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isFirst ? 15 : 13)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star,
                      size: 12, color: Color(0xFFB794F6)),
                  const SizedBox(width: 3),
                  Text(_fmt(u?.charms ?? 0),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              if (u != null) RankBadge(charms: u.charms, scale: 0.82),
              const SizedBox(height: 4),
              SizedBox(
                  height: 20,
                  child: _Sparkline(
                      color: rc.spark, seed: rank * 7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _podiumBadge(int rank) {
    if (rank == 1) {
      return SizedBox(
        height: 30,
        child: Stack(alignment: Alignment.center, children: const [
          Icon(Icons.workspace_premium,
              color: Color(0xFFFFD24A), size: 32),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('1',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
      );
    }
    final color =
        rank == 2 ? const Color(0xFF7BB7FF) : const Color(0xFFE6926B);
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)]),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text('$rank',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }

  Widget _podiumAvatar(AppUser? u, int rank, bool isFirst) {
    final ringColor = rank == 1
        ? const Color(0xFFFFD24A)
        : (rank == 2
            ? const Color(0xFF7BB7FF)
            : const Color(0xFFE6926B));
    final radius = isFirst ? 36.0 : 30.0;
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        u != null
            ? RankAvatarFrame(
                charms: u.charms,
                size: radius * 2,
                child: CircleAvatar(
                  radius: radius,
                  backgroundColor: Colors.white12,
                  backgroundImage: (u.photoURL?.isNotEmpty == true)
                      ? NetworkImage(u.photoURL!)
                      : null,
                  child: (u.photoURL?.isNotEmpty != true)
                      ? Text(
                          u.displayName.isNotEmpty
                              ? u.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22),
                        )
                      : null,
                ),
              )
            : Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(
                        color: ringColor.withOpacity(0.4))),
                child: const Icon(Icons.person,
                    color: Colors.white38, size: 28),
              ),
        Positioned(
          right: -2, bottom: 2,
          child: Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: ringColor,
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xFF1F1530), width: 2),
            ),
            child: const Icon(Icons.workspace_premium,
                color: Colors.white, size: 11),
          ),
        ),
      ],
    );
  }

  // ── RANK LIST (4 onwards) ───────────────────────────────────────────────

  Widget _rankListSection(List<AppUser> users, int startRank) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Column(
        children: [
          for (int i = 0; i < users.length; i++)
            _listRow(users[i], startRank + i),
        ],
      ),
    );
  }

  Widget _listRow(AppUser u, int rank) {
    return InkWell(
      onTap: () => _openChat(u),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(children: [
          SizedBox(
            width: 28,
            child: rank <= 10
                ? Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: _rankNumColor(rank).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text('$rank',
                        style: TextStyle(
                            color: _rankNumColor(rank),
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  )
                : Text('$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
          ),
          const SizedBox(width: 8),
          RankAvatarFrame(
            charms: u.charms,
            size: 42,
            showCrown: false,
            child: CircleAvatar(
              radius: 21,
              backgroundColor: Colors.white12,
              backgroundImage: (u.photoURL?.isNotEmpty == true)
                  ? NetworkImage(u.photoURL!)
                  : null,
              child: (u.photoURL?.isNotEmpty != true)
                  ? Text(
                      u.displayName.isNotEmpty
                          ? u.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(u.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ),
                  if (u.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF60A5FA), size: 14),
                  ],
                ]),
                const SizedBox(height: 3),
                RankBadge(charms: u.charms, scale: 0.78),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                const Icon(Icons.star,
                    color: Color(0xFFB794F6), size: 14),
                const SizedBox(width: 3),
                Text(_fmt(u.charms),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ]),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white54, size: 16),
          ),
        ]),
      ),
    );
  }

  // ── SELF BAR ────────────────────────────────────────────────────────────

  Widget _selfBar() {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08))),
        color: const Color(0xFF1A0B2E),
      ),
      child: StreamBuilder<AppUser>(
        stream: UserService().watchUser(me.uid),
        builder: (context, snap) {
          final u = snap.data;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(children: [
              const Icon(Icons.bar_chart_rounded,
                  color: Color(0xFFB794F6), size: 22),
              const SizedBox(width: 10),
              RankAvatarFrame(
                charms: u?.charms ?? 0,
                size: 38,
                showCrown: false,
                child: CircleAvatar(
                  radius: 19,
                  backgroundColor: Colors.white12,
                  backgroundImage: (u?.photoURL?.isNotEmpty == true)
                      ? NetworkImage(u!.photoURL!)
                      : null,
                  child: (u?.photoURL?.isNotEmpty != true)
                      ? Text(
                          (u?.displayName.isNotEmpty == true)
                              ? u!.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u?.displayName ?? '...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.star,
                          color: Color(0xFFB794F6), size: 12),
                      const SizedBox(width: 3),
                      Text(_fmt(u?.charms ?? 0),
                          style: const TextStyle(
                              color: Color(0xFFB794F6),
                              fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              RankBadge(charms: u?.charms ?? 0, scale: 0.8),
            ]),
          );
        },
      ),
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────

  _RankColors _rankColors(int rank) {
    switch (rank) {
      case 1:
        return _RankColors(
          bg: const [Color(0xFF3A2A14), Color(0xFF1F1530)],
          border: const Color(0xFFFFD24A),
          glow: const Color(0xFFFFB347),
          spark: const Color(0xFFFFB347),
        );
      case 2:
        return _RankColors(
          bg: const [Color(0xFF1E2A4A), Color(0xFF181A38)],
          border: const Color(0xFF7BB7FF),
          glow: const Color(0xFF7BB7FF),
          spark: const Color(0xFF60A5FA),
        );
      default:
        return _RankColors(
          bg: const [Color(0xFF3A1F2A), Color(0xFF201430)],
          border: const Color(0xFFE6926B),
          glow: const Color(0xFFE6926B),
          spark: const Color(0xFFEF6F70),
        );
    }
  }

  Color _rankNumColor(int rank) {
    if (rank <= 3) {
      return [
        const Color(0xFFFFD24A),
        const Color(0xFF7BB7FF),
        const Color(0xFFE6926B)
      ][rank - 1];
    }
    if (rank <= 10) return const Color(0xFF8B5CF6);
    return Colors.white54;
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ── HELPERS ─────────────────────────────────────────────────────────────────

class _RankColors {
  final List<Color> bg;
  final Color border;
  final Color glow;
  final Color spark;
  const _RankColors(
      {required this.bg,
      required this.border,
      required this.glow,
      required this.spark});
}

class _Sparkline extends StatelessWidget {
  final Color color;
  final int seed;
  const _Sparkline({required this.color, required this.seed});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SparklinePainter(color: color, seed: seed));
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  final int seed;
  const _SparklinePainter({required this.color, required this.seed});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final points = List.generate(
      8,
      (i) => Offset(i / 7 * size.width,
          size.height * (0.2 + rng.nextDouble() * 0.6)),
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final cp = Offset(
          (points[i - 1].dx + points[i].dx) / 2, points[i - 1].dy);
      path.quadraticBezierTo(cp.dx, cp.dy, points[i].dx, points[i].dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_SparklinePainter o) => o.seed != seed;
}
