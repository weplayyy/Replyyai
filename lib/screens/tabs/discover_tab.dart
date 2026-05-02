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
import '../discover/ranking_page.dart';
import '../discover/clan_page.dart';
import '../discover/moments_page.dart';
import '../discover/events_page.dart';

class DiscoverTab extends StatefulWidget {
  const DiscoverTab({super.key});
  @override
  State<DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  int _bannerPage = 0;
  final _pageCtrl = PageController();
  Timer? _bannerTimer;

  // Tab definitions — All is always index 0
  static const _tabs = [
    _TabDef('All',      '🌟', null),
    _TabDef('Ranking',  '🏆', RankingPage()),
    _TabDef('Clan',     '🛡️', ClanPage()),
    _TabDef('Moments',  '📸', MomentsPage()),
    _TabDef('Events',   '🎁', EventsPage()),
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

  void _navigate(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
        child: Column(children: [
          _header(),
          _tabBar(),
          Expanded(child: _allBody()),
        ]),
      ),
    );
  }

    // ── HEADER ───────────────────────────────────────────────────────────────

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 12)),
        ]),
        const Spacer(),
        _circleBtn(Icons.search_rounded),
        const SizedBox(width: 10),
        Stack(clipBehavior: Clip.none, children: [
          _circleBtn(Icons.notifications_outlined),
          Positioned(
            right: -3, top: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
      ]),
    );
  }

  Widget _circleBtn(IconData icon) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // ── TAB BAR ──────────────────────────────────────────────────────────────

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabs.length, (i) {
          final isAll = i == 0;
          final tab = _tabs[i];
          return GestureDetector(
            onTap: () {
              if (isAll) return;
              _navigate(tab.page!);
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 54, height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: isAll
                      ? const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isAll ? null : const Color(0xFF1C1040),
                  border: Border.all(
                    color: isAll
                        ? const Color(0xFFA78BFA)
                        : Colors.white.withOpacity(0.09),
                    width: 1.2,
                  ),
                  boxShadow: isAll
                      ? [BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 1)]
                      : null,
                ),
                child: Center(
                    child: Text(tab.emoji,
                        style: TextStyle(fontSize: isAll ? 26 : 22))),
              ),
              const SizedBox(height: 5),
              Text(tab.label,
                  style: TextStyle(
                      color: isAll ? Colors.white : Colors.white54,
                      fontSize: 11,
                      fontWeight:
                          isAll ? FontWeight.bold : FontWeight.normal)),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(top: 3),
                height: 2,
                width: isAll ? 22 : 0,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  // ── ALL BODY ─────────────────────────────────────────────────────────────

  Widget _allBody() {
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
            _sectionHeader('🔥 Top Charm Ranking',
                onViewAll: () => _navigate(const RankingPage())),
            const SizedBox(height: 14),
            _podiumSection(users),
            const SizedBox(height: 26),
            _sectionHeader('📸 Trending Moments',
                onViewAll: () => _navigate(const MomentsPage())),
            const SizedBox(height: 12),
            _trendingMoments(),
            const SizedBox(height: 26),
            _sectionHeader('🎁 Upcoming Events',
                onViewAll: () => _navigate(const EventsPage())),
            const SizedBox(height: 12),
            _upcomingEventsPreview(),
            const SizedBox(height: 16),
            _selfBar(),
          ],
        );
      },
    );
  }

  // ── ADVENTURE BANNER ─────────────────────────────────────────────────────

  Widget _adventureBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 158,
          child: Stack(children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A0060), Color(0xFF45009A), Color(0xFF1A0045)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
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
            const Positioned(right: 18, top: 14,
                child: Text('⚡', style: TextStyle(fontSize: 24))),
            const Positioned(right: 64, top: 10,
                child: Text('💎', style: TextStyle(fontSize: 18))),
            const Positioned(right: 22, bottom: 34,
                child: Text('⭐', style: TextStyle(fontSize: 20))),
            const Positioned(right: 76, bottom: 16,
                child: Text('💛', style: TextStyle(fontSize: 16))),
            const Positioned(right: 30, top: 52,
                child: Text('🪙', style: TextStyle(fontSize: 28))),
            const Positioned(right: -14, bottom: -4,
                child: Text('📦', style: TextStyle(fontSize: 82))),
            Positioned(
              left: 20, top: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Adventure Awaits',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('Complete quests, earn rewards\nand become a legend!',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          height: 1.5)),
                  const SizedBox(height: 13),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)]),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        Text('Enter Adventure',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white, size: 12),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => AnimatedContainer(
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
                )),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── SECTION HEADER ───────────────────────────────────────────────────────

  Widget _sectionHeader(String title, {required VoidCallback onViewAll}) {
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
          onTap: onViewAll,
          child: Row(children: const [
            Text('View All',
                style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 13)),
            Icon(Icons.chevron_right_rounded,
                color: Color(0xFF8B5CF6), size: 18),
          ]),
        ),
      ]),
    );
  }

  // ── PODIUM PREVIEW ───────────────────────────────────────────────────────

  Widget _podiumSection(List<AppUser> users) {
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text('No ranking data yet',
                style:
                    TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
        ),
      );
    }
    final list = List<AppUser?>.from(users);
    while (list.length < 3) list.add(null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
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
        ]),
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
              colors: rc.bg),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.star, size: 12, color: Color(0xFFB794F6)),
              const SizedBox(width: 3),
              Text(_fmt(u?.charms ?? 0),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            if (u != null) RankBadge(charms: u.charms, scale: 0.82),
            const SizedBox(height: 4),
            SizedBox(
                height: 20,
                child: _Sparkline(color: rc.spark, seed: rank * 7)),
          ]),
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
                      fontWeight: FontWeight.bold))),
        ]),
      );
    }
    final color =
        rank == 2 ? const Color(0xFF7BB7FF) : const Color(0xFFE6926B);
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [color, color.withOpacity(0.7)]),
          shape: BoxShape.circle),
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
                              fontSize: 22))
                      : null,
                ))
            : Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                    border:
                        Border.all(color: ringColor.withOpacity(0.4))),
                child: const Icon(Icons.person,
                    color: Colors.white38, size: 28)),
        Positioned(
          right: -2, bottom: 2,
          child: Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: ringColor,
              shape: BoxShape.circle,
              border:
                  Border.all(color: const Color(0xFF1F1530), width: 2),
            ),
            child: const Icon(Icons.workspace_premium,
                color: Colors.white, size: 11),
          ),
        ),
      ],
    );
  }

  // ── TRENDING MOMENTS ─────────────────────────────────────────────────────

  Widget _trendingMoments() {
    final items = [
      _MomentData('Room vibes 💜',       '1.2K', 'Sweetie',     false, const Color(0xFF2D1B4E)),
      _MomentData('Epic party night 🔥', '892',  'KingLeo',     true,  const Color(0xFF1A2040)),
      _MomentData('Adventure squad! ⚔️', '1.6K', 'DreamChaser', true,  const Color(0xFF1A3040)),
      _MomentData("Chillin' 😎",         '743',  'GalaxyBoy',   true,  const Color(0xFF2D1B30)),
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
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7)
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
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
                          width: 16, height: 16,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF6D28D9)),
                          child: Center(
                              child: Text(m.user[0],
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 9))),
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

  // ── UPCOMING EVENTS PREVIEW ──────────────────────────────────────────────

  Widget _upcomingEventsPreview() {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: const [
          _EventPreviewCard(
            title: 'Clan War\nSeason',
            desc: 'Fight for glory!',
            emoji: '⚔️',
            timer: '2D 14:30:12',
            bg: Color(0xFF1C1A50),
            borderColor: Color(0xFF3730A3),
          ),
          SizedBox(width: 12),
          _EventPreviewCard(
            title: 'Love Couple\nFestival',
            desc: 'Get limited gifts!',
            emoji: '💕',
            timer: '5D 08:12:45',
            bg: Color(0xFF3D1A3A),
            borderColor: Color(0xFF9D174D),
          ),
          SizedBox(width: 12),
          _EventPreviewCard(
            title: 'Treasure\nHunt',
            desc: 'Win big prizes!',
            emoji: '💎',
            timer: '1D 06:45:20',
            bg: Color(0xFF162540),
            borderColor: Color(0xFF1E40AF),
          ),
        ],
      ),
    );
  }

  // ── SELF BAR ─────────────────────────────────────────────────────────────

  Widget _selfBar() {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              fontSize: 15))
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
              GestureDetector(
                onTap: () => _navigate(const RankingPage()),
                child: Container(
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
              ),
            ]),
          );
        },
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

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

// ── DATA CLASSES ─────────────────────────────────────────────────────────────

class _TabDef {
  final String label;
  final String emoji;
  final Widget? page;
  const _TabDef(this.label, this.emoji, this.page);
}

class _MomentData {
  final String caption, likes, user;
  final bool verified;
  final Color bg;
  const _MomentData(
      this.caption, this.likes, this.user, this.verified, this.bg);
}

class _RankColors {
  final List<Color> bg;
  final Color border, glow, spark;
  const _RankColors(
      {required this.bg,
      required this.border,
      required this.glow,
      required this.spark});
}

// ── EVENT PREVIEW CARD ────────────────────────────────────────────────────────

class _EventPreviewCard extends StatefulWidget {
  final String title, desc, emoji, timer;
  final Color bg, borderColor;
  const _EventPreviewCard({
    required this.title,
    required this.desc,
    required this.emoji,
    required this.timer,
    required this.bg,
    required this.borderColor,
  });
  @override
  State<_EventPreviewCard> createState() => _EventPreviewCardState();
}

class _EventPreviewCardState extends State<_EventPreviewCard> {
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
    try {
      final parts = s.split(' ');
      final days = int.parse(parts[0].replaceAll('D', ''));
      final tp = parts[1].split(':');
      return days * 86400 +
          int.parse(tp[0]) * 3600 +
          int.parse(tp[1]) * 60 +
          int.parse(tp[2]);
    } catch (_) {
      return 0;
    }
  }

  String get _display {
    final d = _seconds ~/ 86400;
    final h = (_seconds % 86400) ~/ 3600;
    final m = (_seconds % 3600) ~/ 60;
    final s = _seconds % 60;
    return '${d}D ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: widget.borderColor.withOpacity(0.65), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(widget.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(widget.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.2)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(widget.desc,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
                height: 1.4)),
        const Spacer(),
        Row(children: [
          const Icon(Icons.access_time_rounded,
              size: 11, color: Color(0xFFFBBF24)),
          const SizedBox(width: 4),
          Text(_display,
              style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}

// ── SPARKLINE ────────────────────────────────────────────────────────────────

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
    final pts = List.generate(
        8,
        (i) => Offset(i / 7 * size.width,
            size.height * (0.2 + rng.nextDouble() * 0.6)));
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp =
          Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      path.quadraticBezierTo(cp.dx, cp.dy, pts[i].dx, pts[i].dy);
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
