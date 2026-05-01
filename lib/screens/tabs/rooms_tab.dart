import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/room.dart';
import '../../services/room_service.dart';
import '../room_screen.dart';
import '../../data/room_presets.dart';

const List<Map<String, dynamic>> kRoomCategories = [
  {'name': 'All',         'icon': Icons.grid_view_rounded, 'emoji': null},
  {'name': 'Late Night',  'icon': null, 'emoji': '🌙'},
  {'name': 'Confessions', 'icon': null, 'emoji': '❤️'},
  {'name': 'Flirting',    'icon': null, 'emoji': '💓'},
  {'name': 'Memes',       'icon': null, 'emoji': '😂'},
  {'name': 'Debates',     'icon': null, 'emoji': '⚡'},
  {'name': 'More',        'icon': null, 'emoji': '👀'},
];

const List<List<Color>> kCardGradients = [
  [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  [Color(0xFFEC4899), Color(0xFFF43F5E)],
  [Color(0xFF22C55E), Color(0xFF10B981)],
  [Color(0xFFF59E0B), Color(0xFFEF4444)],
  [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
];

// ─────────────────────────────────────────────────────────────────────────────
// ROOMS TAB
// ─────────────────────────────────────────────────────────────────────────────

class RoomsTab extends StatefulWidget {
  const RoomsTab({super.key});
  @override
  State<RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<RoomsTab> {
  final _svc = RoomService();
  String _category  = 'All';
  String _subFilter = 'All Rooms';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _topBar(),
          _categoryRow(),
          _subFilterRow(),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Room>>(
              stream: _svc.watchRooms(),
              builder: (_, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Error: ${snap.error}',
                        style: const TextStyle(color: Colors.white70)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var rooms = snap.data!;
                if (_category != 'All') {
                  rooms = rooms.where((r) => r.category == _category).toList();
                }

                // Advanced rooms float to the top.
                rooms.sort((a, b) {
                  if (a.isAdvanced && !b.isAdvanced) return -1;
                  if (!a.isAdvanced && b.isAdvanced) return 1;
                  return 0;
                });

                if (rooms.isEmpty) return _emptyState();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  itemCount: rooms.length,
                  itemBuilder: (_, i) =>
                      _roomCard(rooms[i], kCardGradients[i % 5]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── top bar ──────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Chat ',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      ).createShader(b),
                      child: const Text('Rooms',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    const Text('✨', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Jump into live conversations ',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 12)),
                    const Text('💭', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon'))),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.search, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => CreateRoomSheet.show(context),
            child: Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── category row ─────────────────────────────────────────────────────────

  Widget _categoryRow() {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: kRoomCategories.length,
        itemBuilder: (_, i) {
          final c = kRoomCategories[i];
          final selected = _category == c['name'];
          return GestureDetector(
            onTap: () => setState(() => _category = c['name'] as String),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF8B5CF6).withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF8B5CF6)
                            : Colors.white.withOpacity(0.06),
                        width: selected ? 1.6 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: c['icon'] != null
                        ? Icon(c['icon'] as IconData,
                            color: selected
                                ? const Color(0xFFB794F6)
                                : Colors.white70,
                            size: 22)
                        : Text(c['emoji'] as String,
                            style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(height: 6),
                  Text(c['name'] as String,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white60,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── sub-filter row ───────────────────────────────────────────────────────

  Widget _subFilterRow() {
    final filters = ['All Rooms', 'Active Now', 'New', 'My Rooms'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (_, i) {
                  final f = filters[i];
                  final selected = _subFilter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _subFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFFEC4899)
                              ])
                            : null,
                        color: selected
                            ? null
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          if (f == 'Active Now') ...[
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(f,
                              style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(selected ? 1 : 0.7),
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Text('🔥', style: TextStyle(fontSize: 12)),
                SizedBox(width: 5),
                Text('Popular',
                    style:
                        TextStyle(color: Colors.white, fontSize: 12)),
                Icon(Icons.keyboard_arrow_down,
                    color: Colors.white70, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── room card ────────────────────────────────────────────────────────────

  Widget _roomCard(Room r, List<Color> btnGradient) {
    final isAdv = r.isAdvanced;

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => RoomScreen(room: r))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          // Gold shimmer border for advanced rooms.
          gradient: isAdv
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFBBF24),
                    Color(0xFFF59E0B),
                    Color(0xFFEC4899),
                    Color(0xFF8B5CF6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isAdv ? null : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: isAdv
              ? null
              : Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: isAdv
              ? [
                  BoxShadow(
                      color: const Color(0xFFFBBF24).withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
                ]
              : null,
        ),
        child: Container(
          margin: isAdv ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isAdv ? 18.5 : 20),
            gradient: isAdv
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1F0B3F), Color(0xFF2D0F5C)],
                  )
                : null,
            color: isAdv ? null : Colors.white.withOpacity(0.04),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ──────────────────────────────────────
              Stack(
                children: [
                  Container(
                    width: 78, height: 78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: isAdv
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFBBF24),
                                Color(0xFFF59E0B)
                              ])
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: btnGradient,
                            ),
                      boxShadow: [
                        BoxShadow(
                            color: (isAdv
                                    ? const Color(0xFFFBBF24)
                                    : btnGradient.last)
                                .withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child:
                        Text(r.emoji, style: const TextStyle(fontSize: 36)),
                  ),
                  // ADVANCED badge
                  if (isAdv)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            Color(0xFFFBBF24),
                            Color(0xFFF59E0B)
                          ]),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: const Text('💎',
                            style: TextStyle(fontSize: 11)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // ── Info ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: isAdv
                                      ? const Color(0xFFFBBF24)
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                        const SizedBox(width: 5),
                        Icon(Icons.verified,
                            color: isAdv
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFF8B5CF6),
                            size: 14),
                        if (isAdv) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFFBBF24),
                                Color(0xFFEC4899)
                              ]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Lv ${r.level}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                        const Spacer(),
                        const Icon(Icons.wifi,
                            color: Color(0xFF22C55E), size: 12),
                        const SizedBox(width: 3),
                        Text('${r.onlineCount} online',
                            style: const TextStyle(
                                color: Color(0xFF22C55E), fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.description.isEmpty
                          ? 'Tap to join the conversation'
                          : r.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: [
                              for (final t in r.tags.take(3))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isAdv
                                            ? const Color(0xFFFBBF24)
                                            : const Color(0xFF8B5CF6))
                                        .withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(t,
                                      style: TextStyle(
                                          color: isAdv
                                              ? const Color(0xFFFBBF24)
                                              : const Color(0xFFB794F6),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: isAdv
                                ? const LinearGradient(colors: [
                                    Color(0xFFFBBF24),
                                    Color(0xFFF59E0B)
                                  ])
                                : LinearGradient(colors: btnGradient),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: (isAdv
                                          ? const Color(0xFFFBBF24)
                                          : btnGradient.last)
                                      .withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAdv) ...[
                                const Icon(Icons.diamond,
                                    color: Colors.white, size: 11),
                                const SizedBox(width: 4),
                              ],
                              const Text('Enter Chat',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── empty state ──────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 2),
              ],
            ),
            child:
                const Icon(Icons.groups_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 18),
          const Text('No rooms yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Be the first — tap + to create one',
              style: TextStyle(color: Colors.white.withOpacity(0.55))),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => CreateRoomSheet.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Create Room',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE ROOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class CreateRoomSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14092B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CreateRoomBody(),
    );
  }
}

class _CreateRoomBody extends StatefulWidget {
  const _CreateRoomBody();
  @override
  State<_CreateRoomBody> createState() => _CreateRoomBodyState();
}

class _CreateRoomBodyState extends State<_CreateRoomBody> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _category  = 'Late Night';
  String _emoji     = '🌙';
  bool   _advanced  = false;
  bool   _busy      = false;
  int    _myCoins   = 0;

  static const int kAdvancedCost = 2000;

  static const _emojiChoices = [
    '🌙','❤️','💓','😂','⚡','👀','🎮','☕','🔥','💜','🎵','🎬'
  ];

  @override
  void initState() {
    super.initState();
    _loadCoins();
  }

  Future<void> _loadCoins() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) {
      setState(() => _myCoins = (doc.data()?['coins'] ?? 0) as int);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) return;
    if (_advanced && _myCoins < kAdvancedCost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Not enough coins — you need 2,000 coins for an Advanced Room.')));
      return;
    }

    setState(() => _busy = true);
    try {
      final me = FirebaseAuth.instance.currentUser!;
      final meDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(me.uid)
          .get();
      final m = meDoc.data() ?? {};

      final room = Room(
        id: '',
        name: _name.text.trim(),
        description: _desc.text.trim(),
        category: _category,
        tags: [_category],
        emoji: _emoji,
        photoUrl: RoomPresets.firstFor(_category),
        ownerId: me.uid,
        ownerName: (m['displayName'] ?? 'Owner') as String,
        ownerPhoto: m['photoURL'] as String?,
        ownerCharms: (m['charms'] ?? 0) as int,
        type: _advanced ? RoomType.advanced : RoomType.temporary,
      );

      if (_advanced) {
        await RoomService().createAdvancedRoom(room);
      } else {
        await RoomService().createRoom(room);
      }

      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${_advanced ? '💎 Advanced' : ''} Room "${_name.text.trim()}" created')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = kRoomCategories
        .where((c) => c['name'] != 'All' && c['name'] != 'More')
        .toList();
    final canAfford = _myCoins >= kAdvancedCost;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Title
          const Text('Create a Room',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),

          _input(_name, 'Room name', Icons.tag),
          const SizedBox(height: 10),
          _input(_desc, 'Description (optional)', Icons.notes, lines: 2),
          const SizedBox(height: 14),

          // ── Emoji picker
          Text('Pick an emoji',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (final e in _emojiChoices)
                GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _emoji == e
                          ? const Color(0xFF8B5CF6).withOpacity(0.25)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: _emoji == e
                            ? const Color(0xFF8B5CF6)
                            : Colors.transparent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Category
          Text('Category',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              for (final c in cats)
                GestureDetector(
                  onTap: () =>
                      setState(() => _category = c['name'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: _category == c['name']
                          ? const Color(0xFF8B5CF6).withOpacity(0.25)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: _category == c['name']
                            ? const Color(0xFF8B5CF6)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c['emoji'] as String,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(c['name'] as String,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Advanced Room toggle ─────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _advanced = !_advanced),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _advanced
                    ? const LinearGradient(
                        colors: [Color(0xFF2D1A00), Color(0xFF3D1F00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _advanced ? null : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _advanced
                      ? const Color(0xFFFBBF24)
                      : Colors.white.withOpacity(0.08),
                  width: _advanced ? 1.5 : 1,
                ),
                boxShadow: _advanced
                    ? [
                        BoxShadow(
                            color: const Color(0xFFFBBF24).withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _advanced
                          ? const LinearGradient(colors: [
                              Color(0xFFFBBF24),
                              Color(0xFFF59E0B)
                            ])
                          : null,
                      color: _advanced ? null : Colors.white.withOpacity(0.08),
                    ),
                    child: const Icon(Icons.diamond,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Labels
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Advanced Room',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFFFBBF24),
                                  Color(0xFFF59E0B)
                                ]),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('2,000 💰',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Never auto-deletes · Freezes when you leave · Premium UI',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 5),
                        // Balance row
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined,
                                color: Colors.white38, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Your balance: $_myCoins coins',
                              style: TextStyle(
                                  color: canAfford
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFFEF4444),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                            if (!canAfford) ...[
                              const SizedBox(width: 6),
                              const Text('(not enough)',
                                  style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 10)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Toggle switch
                  Switch(
                    value: _advanced,
                    onChanged: (v) => setState(() => _advanced = v),
                    activeColor: const Color(0xFFFBBF24),
                    trackColor: WidgetStateProperty.resolveWith((s) =>
                        s.contains(WidgetState.selected)
                            ? const Color(0xFFFBBF24).withOpacity(0.3)
                            : Colors.white12),
                  ),
                ],
              ),
            ),
          ),

                    if (_advanced) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFBBF24).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What you get:',
                    style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _perk('💎 Room never auto-deletes'),
                  _perk('❄️  Freezes (not deleted) when you leave'),
                  _perk('👑 Gold border & diamond badge in the list'),
                  _perk('🛡️  Any mod can unfreeze on your behalf'),
                  _perk('📈 XP & level system (coming soon)'),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // ── Create button ──────────────────────────────────────────────
          GestureDetector(
            onTap: _busy ? null : _create,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                gradient: _advanced
                    ? const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)])
                    : const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: (_advanced
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFEC4899))
                          .withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8)),
                ],
              ),
              alignment: Alignment.center,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_advanced) ...[
                          const Icon(Icons.diamond,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _advanced
                              ? 'Create Advanced Room (2,000 💰)'
                              : 'Create Room',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _perk(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }

  Widget _input(TextEditingController c, String hint, IconData icon,
      {int lines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: c,
        maxLines: lines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon:
              Icon(icon, color: Colors.white.withOpacity(0.5), size: 18),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
