import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/rank_avatar_frame.dart';
import '../chat_screen.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});
  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  int _tab = 0;
  int _bannerPage = 0;
  final _pageCtrl = PageController();
  Timer? _bannerTimer;

  static const _tabs = [
    _TabItem('Ranking',   '🏆'),
    _TabItem('Clan',      '🛡️'),
    _TabItem('Moments',   '📸'),
    _TabItem('Adventure', '⚔️'),
    _TabItem('Events',    '🎁'),
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerPage + 1) % 3;
      _pageCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _openChat(AppUser u) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || u.uid == me.uid) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChatScreen(other: u)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0B2E), Color(0xFF0F0A1F)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            _tabBar(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Text('Discover',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
                SizedBox(width: 6),
                Text('✨', style: TextStyle(fontSize: 18)),
              ]),
              Text('Explore, connect & grow together 💜',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55), fontSize: 12)),
            ],
          ),
          const Spacer(),
          _circleBtn(Icons.search_rounded),
          const SizedBox(width: 10),
          Stack(clipBehavior: Clip.none, children: [
            _circleBtn(Icons.notifications_outlined),
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('12',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // ─── TAB BAR ───────────────────────────────────────────────────────────────

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabs.length, (i) {
          final selected = i == _tab;
          final tab = _tabs[i];
          return GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selected ? null : const Color(0xFF1C1040),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFA78BFA)
                          : Colors.white.withOpacity(0.09),
                      width: 1.2,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(tab.emoji,
                        style: TextStyle(fontSize: selected ? 26 : 22)),
                  ),
                ),
                const SizedBox(height: 5),
                Text(tab.label,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.white54,
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(top: 3),
                  height: 2,
                  width: selected ? 22 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── BODY ──────────────────────────────────────────────────────────────────

  Widget _body() {
    switch (_tab) {
      case 0:
        return _rankingBody();
      case 1:
        return _comingSoon('Clan', '🛡️');
      case 2:
        return _momentsBody();
      case 3:
        return _adventureBody();
      case 4:
        return _comingSoon('Events', '🎁');
      default:
        return _comingSoon(_tabs[_tab].label, _tabs[_tab].emoji);
    }
  }

  // ─── RANKING BODY ──────────────────────────────────────────────────────────

  Widget _rankingBody() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('charms', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        final users = snap.hasData
            ? snap.data!.docs
                .map((d) => AppUser.fromMap(d.data(), d.id))
                .toList()
            : <AppUser>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 30),
          children: [
            _adventureBanner(),
            const SizedBox(height: 22),
            _sectionHeader('🔥 Top Charm Ranking', onTap: () {}),
            const SizedBox(height: 14),
            _podiumSection(users),
            if (users.length > 3) ...[
              const SizedBox(height: 16),
              _restList(users.sublist(3), 4),
            ],
            const SizedBox(height: 26),
            _sectionHeader('📸 Trending Moments', onTap: () {}),
            const SizedBox(height: 12),
            _trendingMoments(),
            const SizedBox(height: 26),
            _sectionHeader('🎁 Upcoming Events', onTap: () {}),
            const SizedBox(height: 12),
            _upcomingEvents(),
            const SizedBox(height: 16),
            _selfBar(),
          ],
        );
      },
    );
  }

  // ─── ADVENTURE BANNER ──────────────────────────────────────────────────────

  Widget _adventureBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 158,
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2A0060),
                      Color(0xFF45009A),
                      Color(0xFF1A0045),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Star particles
              ...List.generate(14, (i) {
                final rng = math.Random(i * 41);
                return Positioned(
                  left: rng.nextDouble() * 340,
                  top: rng.nextDouble() * 158,
                  child: Opacity(
                    opacity: 0.25 + rng.nextDouble() * 0.45,
                    child: Text(
                      ['✦', '·', '✧', '⋆', '∗'][i % 5],
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 7 + rng.nextDouble() * 9),
                    ),
                  ),
                );
              }),
              // Right-side decorative icons
              const Positioned(
                  right: 18, top: 14, child: Text('⚡', style: TextStyle(fontSize: 24))),
              const Positioned(
                  right: 64, top: 10, child: Text('💎', style: TextStyle(fontSize: 18))),
              const Positioned(
                  right: 22, bottom: 34, child: Text('⭐', style: TextStyle(fontSize: 20))),
              const Positioned(
                  right: 76, bottom: 16, child: Text('💛', style: TextStyle(fontSize: 16))),
              const Positioned(
                  right: 30, top: 52, child: Text('🪙', style: TextStyle(fontSize: 28))),
              // Treasure chest
              const Positioned(
                  right: -14,
                  bottom: -4,
                  child: Text('📦', style: TextStyle(fontSize: 82))),
              // Text content
              Positioned(
                left: 20,
                top: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Adventure Awaits',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(
                      'Complete quests, earn rewards\nand become a legend!',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          height: 1.5),
                    ),
                    const SizedBox(height: 13),
                    GestureDetector(
                      onTap: () => setState(() => _tab = 3),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)]),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('Enter Adventure',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Dots
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _bannerPage == i ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _bannerPage == i
                            ? const Color(0xFF8B5CF6)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SECTION HEADER ────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: Row(children: const [
            Text('View All',
                style:
                    TextStyle(color: Color(0xFF8B5CF6), fontSize: 13)),
            Icon(Icons.chevron_right_rounded,
                color: Color(0xFF8B5CF6), size: 18),
          ]),
        ),
      ]),
    );
  }

  // ─── PODIUM ────────────────────────────────────────────────────────────────

  Widget _podiumSection(List<AppUser> users) {
    final list = List<AppUser?>.from(users);
    while (list.length < 3) list.add(null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: _rankCard(list[1], 2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _rankCard(list[0], 1, isFirst: true)),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: _rankCard(list[2], 3),
              ),
            ),
          ],
        ),
      ),
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
            width: isFirst ? 2 : 1.2,
          ),
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
              Text(
                u?.displayName ?? '---',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isFirst ? 15 : 13),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 12, color: Color(0xFFB794F6)),
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
                child: _Sparkline(color: rc.spark, seed: rank * 7),
              ),
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
          Icon(Icons.workspace_premium, color: Color(0xFFFFD24A), size: 32),
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
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
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
        : (rank == 2 ? const Color(0xFF7BB7FF) : const Color(0xFFE6926B));
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
                    border: Border.all(color: ringColor.withOpacity(0.4))),
                child: const Icon(Icons.person, color: Colors.white38, size: 28),
              ),
        Positioned(
          right: -2,
          bottom: 2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: ringColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1F1530), width: 2),
            ),
            child: const Icon(Icons.workspace_premium,
                color: Colors.white, size: 11),
          ),
        ),
      ],
    );
  }

  // ─── REST LIST ─────────────────────────────────────────────────────────────

  Widget _restList(List<AppUser> users, int startRank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(children: [
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
          RankAvatarFrame(
            charms: u.charms,
            size: 40,
            showCrown: false,
            child: CircleAvatar(
              radius: 20,
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
                Text(u.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 3),
                RankBadge(charms: u.charms, scale: 0.78),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(children: [
            const Icon(Icons.star, color: Color(0xFFB794F6), size: 14),
            const SizedBox(width: 3),
            Text(_fmt(u.charms),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ]),
          const SizedBox(width: 6),
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
        ]),
      ),
    );
  }

  // ─── TRENDING MOMENTS ──────────────────────────────────────────────────────

  Widget _trendingMoments() {
    final items = [
      _MomentItem('Room vibes 💜',      '1.2K', 'Sweetie',      false, const Color(0xFF2D1B4E)),
      _MomentItem('Epic party night 🔥', '892',  'KingLeo',      true,  const Color(0xFF1A2040)),
      _MomentItem('Adventure squad! ⚔️', '1.6K', 'DreamChaser',  true,  const Color(0xFF1A3040)),
      _MomentItem("Chillin' 😎",         '743',  'GalaxyBoy',    true,  const Color(0xFF2D1B30)),
    ];
    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final m = items[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 110,
              color: m.bg,
              child: Stack(children: [
                // Gradient overlay bottom
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Play icon
                Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                // Likes top-right
                Positioned(
                  top: 8, right: 8,
                  child: Row(children: [
                    const Icon(Icons.favorite_rounded,
                        color: Color(0xFFEC4899), size: 12),
                    const SizedBox(width: 3),
                    Text(m.likes,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
                // Caption + user bottom
                Positioned(
                  left: 8, right: 8, bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF6D28D9)),
                          child: Center(
                            child: Text(m.user[0],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(m.user,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 10)),
                        ),
                        if (m.verified)
                          const Icon(Icons.verified_rounded,
                              color: Color(0xFF60A5FA), size: 12),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // ─── UPCOMING EVENTS ───────────────────────────────────────────────────────

  Widget _upcomingEvents() {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: const [
          _EventCard(
            title: 'Clan War\nSeason',
            desc: 'Fight for glory\nWin epic rewards!',
            emoji: '⚔️',
            timer: '2D 14:30:12',
            bg: Color(0xFF1C1A50),
            borderColor: Color(0xFF3730A3),
          ),
          SizedBox(width: 12),
          _EventCard(
            title: 'Love Couple\nFestival',
            desc: 'Share love\nGet limited gifts!',
            emoji: '💕',
            timer: '5D 08:12:45',
            bg: Color(0xFF3D1A3A),
            borderColor: Color(0xFF9D174D),
          ),
          SizedBox(width: 12),
          _EventCard(
            title: 'Treasure\nHunt',
            desc: 'Find treasures\nWin big prizes!',
            emoji: '💎',
            timer: '1D 06:45:20',
            bg: Color(0xFF162540),
            borderColor: Color(0xFF1E40AF),
          ),
        ],
      ),
    );
  }

  // ─── SELF BAR ──────────────────────────────────────────────────────────────

  Widget _selfBar() {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: StreamBuilder<AppUser>(
        stream: UserService().watchUser(me.uid),
        builder: (context, snap) {
          final u = snap.data;
          return Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2D1B4E), Color(0xFF1F1430)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
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
                    Row(children: [
                      Flexible(
                        child: Text(
                          (u?.displayName ?? '...').toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 4),
                      RankBadge(charms: u?.charms ?? 0, scale: 0.75),
                    ]),
                    const SizedBox(height: 2),
                    Text('Charm ${_fmt(u?.charms ?? 0)}',
                        style: const TextStyle(
                            color: Color(0xFFB794F6), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4)),
                ),
                child: const Text('My Rank',
                    style: TextStyle(
                        color: Color(0xFFB794F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ─── MOMENTS BODY ──────────────────────────────────────────────────────────

  Widget _momentsBody() {
    return _comingSoon('Moments', '📸',
        sub: 'Upload photos & videos — coming soon!');
  }

  // ─── ADVENTURE BODY ────────────────────────────────────────────────────────

  Widget _adventureBody() {
    return _comingSoon('Adventure', '⚔️',
        sub: 'Quests & games are on their way!');
  }

  // ─── COMING SOON ───────────────────────────────────────────────────────────

  Widget _comingSoon(String name, String emoji, {String? sub}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1040),
              shape: BoxShape.circle,
              border:
                  Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 42)),
            ),
          ),
          const SizedBox(height: 20),
          Text('$name Coming Soon',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            sub ?? "We're building something amazing! 🚀",
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

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

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─── DATA CLASSES ────────────────────────────────────────────────────────────

class _TabItem {
  final String label;
  final String emoji;
  const _TabItem(this.label, this.emoji);
}

class _MomentItem {
  final String caption;
  final String likes;
  final String user;
  final bool verified;
  final Color bg;
  const _MomentItem(
      this.caption, this.likes, this.user, this.verified, this.bg);
}

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

// ─── EVENT CARD (stateful for countdown) ─────────────────────────────────────

class _EventCard extends StatefulWidget {
  final String title;
  final String desc;
  final String emoji;
  final String timer;
  final Color bg;
  final Color borderColor;
  const _EventCard({
    required this.title,
    required this.desc,
    required this.emoji,
    required this.timer,
    required this.bg,
    required this.borderColor,
  });
  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  late int _seconds;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _seconds = _parse(widget.timer);
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds = (_seconds - 1).clamp(0, 1 << 30));
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  int _parse(String s) {
    // Format: "2D 14:30:12"
    try {
      final parts = s.split(' ');
      final days = int.parse( **...**

_This response is too long to display in full._
