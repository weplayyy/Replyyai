import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../chat_screen.dart';
import 'friends_tab.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});
  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  int _category = 0;
  int _period = 1;

  static const _categories = <(String, IconData)>[
    ('Popularity', Icons.local_fire_department),
    ('VIP', Icons.diamond_outlined),
    ('Couple', Icons.favorite_border),
    ('Room', Icons.home_outlined),
    ('BFF', Icons.people_alt_outlined),
    ('Family', Icons.family_restroom),
  ];

  static const _periods = ['Today', 'Yesterday', 'Celebrity', 'Annual'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1147), Color(0xFF0F0A1F)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 8),
            _categoryRow(),
            const SizedBox(height: 14),
            _periodRow(),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('charms', descending: true)
                    .limit(50)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snap.data!.docs
                      .map((d) => AppUser.fromMap(d.data()))
                      .toList();
                  return _rankingContent(users);
                },
              ),
            ),
            _selfBar(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const _SelectFriendPage())),
            child: _circleBtn(Icons.person_add_alt_1_rounded),
          ),
          const Spacer(),
          const Text('Ranking',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          _circleBtn(Icons.help_outline_rounded),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _categoryRow() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (_, i) {
          final selected = i == _category;
          final (label, icon) = _categories[i];
          return GestureDetector(
            onTap: () => setState(() => _category = i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon,
                        size: 16,
                        color: selected
                            ? const Color(0xFFB794F6)
                            : Colors.white60),
                    const SizedBox(width: 4),
                    Text(label,
                        style: TextStyle(
                            color: selected ? Colors.white : Colors.white60,
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: selected ? 20 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB794F6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _periodRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_periods.length, (i) {
                  final selected = i == _period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _period = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF8B5CF6)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(_periods[i],
                            style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500)),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: const [
                Icon(Icons.public, size: 14, color: Colors.white70),
                SizedBox(width: 4),
                Text('Global',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Icon(Icons.arrow_drop_down, size: 18, color: Colors.white70),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankingContent(List<AppUser> users) {
    if (users.isEmpty) {
      return Center(
        child: Text('No ranking yet.\nSend a gift to get on the board!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6))),
      );
    }

    final hasPodium = users.length >= 3;
    final rest = hasPodium ? users.sublist(3) : users;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        if (hasPodium) _podium(users[0], users[1], users[2]),
        if (hasPodium) const SizedBox(height: 16),
        if (rest.isNotEmpty) _restList(rest, hasPodium ? 4 : 1),
      ],
    );
  }

  Widget _podium(AppUser first, AppUser second, AppUser third) {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                  child: _podiumCard(second,
                      rank: 2,
                      borderColor: const Color(0xFF60A5FA),
                      sparkColor: const Color(0xFF60A5FA))),
              const SizedBox(width: 8),
              Expanded(
                  child: _podiumCard(first,
                      rank: 1,
                      borderColor: const Color(0xFFFBBF24),
                      sparkColor: const Color(0xFFFBBF24),
                      featured: true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _podiumCard(third,
                      rank: 3,
                      borderColor: const Color(0xFFEC4899),
                      sparkColor: const Color(0xFFEC4899))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _podiumCard(
    AppUser u, {
    required int rank,
    required Color borderColor,
    required Color sparkColor,
    bool featured = false,
  }) {
    return GestureDetector(
      onTap: () => _openChat(u),
      child: Container(
        height: featured ? 232 : 208,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: featured
                ? [const Color(0xFF3B2517), const Color(0xFF1F1430)]
                : [borderColor.withOpacity(0.18), const Color(0xFF1F1430)],
          ),
          border: Border.all(
              color: borderColor.withOpacity(featured ? 0.9 : 0.5),
              width: featured ? 1.6 : 1.2),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        child: Column(
          children: [
            _rankBadge(rank, borderColor),
            const SizedBox(height: 8),
            _avatarRing(u, borderColor, featured),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(u.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: featured ? 15 : 13,
                          fontWeight: FontWeight.bold)),
                ),
                if (rank == 1) const Text(' 🔥', style: TextStyle(fontSize: 13)),
                if (rank == 2) const Text(' 🌙', style: TextStyle(fontSize: 13)),
                if (rank == 3) const Text(' 🐝', style: TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star,
                    color: featured
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFB794F6),
                    size: 14),
                const SizedBox(width: 3),
                Text(_fmt(u.charms),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: featured ? 14 : 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _Sparkline(
                    color: sparkColor.withOpacity(0.85),
                    seed: u.uid.hashCode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rankBadge(int rank, Color color) {
    if (rank == 1) {
      return const Text('👑', style: TextStyle(fontSize: 22));
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)]),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      alignment: Alignment.center,
      child: Text('$rank',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }

  Widget _avatarRing(AppUser u, Color borderColor, bool featured) {
    final size = featured ? 78.0 : 66.0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 2),
            gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
            boxShadow: [
              BoxShadow(
                  color: borderColor.withOpacity(0.4),
                  blurRadius: 14,
                  spreadRadius: 1),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : '?',
            style: TextStyle(
                color: Colors.white,
                fontSize: featured ? 30 : 26,
                fontWeight: FontWeight.bold),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [borderColor, borderColor.withOpacity(0.7)]),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1F1430), width: 2),
            ),
            child: const Icon(Icons.workspace_premium,
                size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _restList(List<AppUser> users, int startRank) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('$rank',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
            const SizedBox(width: 6),
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    u.displayName.isNotEmpty
                        ? u.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF1F1430), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(u.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFB794F6), size: 14),
                const SizedBox(width: 3),
                Text(_fmt(u.charms),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selfBar() {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return const SizedBox.shrink();
    return StreamBuilder<AppUser>(
      stream: UserService().watchUser(me.uid),
      builder: (context, snap) {
        final u = snap.data;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D1B4E), Color(0xFF1F1430)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFFB794F6), size: 18),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                ),
                alignment: Alignment.center,
                child: Text(
                  (u?.displayName.isNotEmpty ?? false)
                      ? u!.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                              (u?.displayName ?? '...').toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFF06B6D4),
                              Color(0xFF22D3EE),
                            ]),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('💎${u?.level ?? 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Charm ${u?.charms ?? 0}',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const _SelectFriendPage())),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.card_giftcard,
                          color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Send Gift',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openChat(AppUser u) {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || u.uid == me.uid) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => ChatScreen(other: u)));
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _SelectFriendPage extends StatelessWidget {
  const _SelectFriendPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0B2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Pick a Friend',
            style: TextStyle(color: Colors.white)),
      ),
      body: const FriendsTab(),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final Color color;
  final int seed;
  const _Sparkline({required this.color, required this.seed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: CustomPaint(painter: _SparkPainter(color: color, seed: seed)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final Color color;
  final int seed;
  _SparkPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(seed);
    final pts = List<double>.generate(8, (_) => 0.15 + rand.nextDouble() * 0.85);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      final x = i * size.width / (pts.length - 1);
      final y = size.height - pts[i] * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final px = (i - 1) * size.width / (pts.length - 1);
        final py = size.height - pts[i - 1] * size.height;
        final cx = (px + x) / 2;
        path.cubicTo(cx, py, cx, y, x, y);
      }
    }
    canvas.drawPath(path, stroke);

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fill);
  }

  @override
  bool shouldRepaint(_) => false;
}
