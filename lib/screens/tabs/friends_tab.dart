import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../models/app_user.dart';
import '../../widgets/rank_badge.dart';
import '../chat_screen.dart';
import '../user_profile_screen.dart';
import '../../features/friends/services/friend_service.dart';
import '../../features/friends/models/friendship.dart';
import '../../features/friends/widgets/friend_button.dart';
import '../../features/friends/screens/friend_requests_screen.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _friends = FriendService();
  final _users = UserService();
  final _searchC = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _tab.dispose();
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _topBar(),
          _searchBar(),
          TabBar(
            controller: _tab,
            indicatorColor: const Color(0xFF8B5CF6),
            indicatorWeight: 2.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'My Friends'),
              Tab(text: 'Find People'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_myFriendsList(), _findPeopleList()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text('Friends',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
          ),
          // Pending requests bell (with badge)
          StreamBuilder<List<Friendship>>(
            stream: _friends.watchIncomingRequests(),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FriendRequestsScreen()),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20),
                    ),
                    if (count > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                              minWidth: 18, minHeight: 18),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEC4899),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _searchC,
          style: const TextStyle(color: Colors.white),
          onChanged: (v) =>
              setState(() => _query = v.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search by name…',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            prefixIcon:
                const Icon(Icons.search, color: Colors.white54, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ---------- TAB 1: MY FRIENDS ----------
  Widget _myFriendsList() {
    return StreamBuilder<List<Friendship>>(
      stream: _friends.watchMyFriends(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var list = snap.data!;
        if (_query.isNotEmpty) {
          list = list
              .where((f) => f.displayName.toLowerCase().contains(_query))
              .toList();
        }
        if (list.isEmpty) {
          return _empty(
            icon: Icons.people_alt_outlined,
            title: 'No friends yet',
            subtitle: 'Browse "Find People" and send some requests.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: list.length,
          itemBuilder: (_, i) => _friendTile(list[i]),
        );
      },
    );
  }

  Widget _friendTile(Friendship f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => UserProfileScreen(uid: f.uid)),
            ),
            child: _circleAvatar(f.displayName, f.photoUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                RankBadge(charms: f.charms, scale: 0.8, showName: false),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              // Pull a fresh AppUser so ChatScreen has full data.
              final u = await _users.getUser(f.uid);
              if (u != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(other: u)),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text('Message',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- TAB 2: FIND PEOPLE ----------
  Widget _findPeopleList() {
    final me = FirebaseAuth.instance.currentUser!;
    return StreamBuilder<List<AppUser>>(
      stream: _users.watchAllUsersExcept(me.uid),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var list = snap.data!;
        if (_query.isNotEmpty) {
          list = list
              .where((u) => u.displayName.toLowerCase().contains(_query))
              .toList();
        }
        if (list.isEmpty) {
          return _empty(
            icon: Icons.search_off_rounded,
            title: 'No users found',
            subtitle: 'Try a different name.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: list.length,
          itemBuilder: (_, i) => _findTile(list[i]),
        );
      },
    );
  }

  Widget _findTile(AppUser u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => UserProfileScreen(uid: u.uid)),
            ),
            child: _circleAvatar(u.displayName, u.photoURL),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite,
                        size: 11, color: Color(0xFFEC4899)),
                    const SizedBox(width: 4),
                    Text('${u.charms}',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 11)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: RankBadge(
                          charms: u.charms, scale: 0.8, showName: false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          FriendButton(otherUid: u.uid, compact: true),
        ],
      ),
    );
  }

  // ---------- shared helpers ----------
  Widget _circleAvatar(String name, String? photoUrl) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
        image: photoUrl != null && photoUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(photoUrl), fit: BoxFit.cover)
            : null,
      ),
      child: photoUrl == null || photoUrl.isEmpty
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            )
          : null,
    );
  }

  Widget _empty(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: Icon(icon, color: Colors.white54, size: 36),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}
