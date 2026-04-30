import 'package:flutter/material.dart';
import '../models/friendship.dart';
import '../services/friend_service.dart';
import '../widgets/friend_button.dart';
import '../../../screens/user_profile_screen.dart';
import '../../../widgets/rank_badge.dart';

/// Two-tab screen showing incoming + outgoing friend requests.
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _svc = FriendService();

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Friend Requests',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFF8B5CF6),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _list(_svc.watchIncomingRequests(), emptyText: 'No incoming requests'),
          _list(_svc.watchOutgoingRequests(),
              emptyText: 'No pending requests sent'),
        ],
      ),
    );
  }

  Widget _list(Stream<List<Friendship>> stream, {required String emptyText}) {
    return StreamBuilder<List<Friendship>>(
      stream: stream,
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return Center(
            child: Text(emptyText,
                style: const TextStyle(color: Colors.white54)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: list.length,
          itemBuilder: (_, i) => _tile(list[i]),
        );
      },
    );
  }

  Widget _tile(Friendship f) {
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
            child: _avatar(f),
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
          FriendButton(otherUid: f.uid, compact: true),
        ],
      ),
    );
  }

  Widget _avatar(Friendship f) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
        image: f.photoUrl != null && f.photoUrl!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(f.photoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: f.photoUrl == null || f.photoUrl!.isEmpty
          ? Center(
              child: Text(
                f.displayName.isNotEmpty
                    ? f.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            )
          : null,
    );
  }
}
