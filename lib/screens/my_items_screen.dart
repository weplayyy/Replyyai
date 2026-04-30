import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop_item.dart';
import '../models/app_user.dart';
import '../services/shop_service.dart';
import '../services/user_service.dart';
import 'use_item_picker_screen.dart';
import 'cp_propose_sheet.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0B0717);
  static const _card = Color(0xFF181028);
  static const _purple = Color(0xFF7C5CFF);
  static const _gold = Color(0xFFFFC542);

  final _uid = FirebaseAuth.instance.currentUser!.uid;

  // (label, type-key in inventory)
  static const _tabs = <(String, String?)>[
    ('All', null),
    ('Rings', 'ring'),
    ('Tags', 'tag'),
    ('Badges', 'badge'),
    ('Seats', 'seat'),
    ('Frames', 'frame'),
    ('Effects', 'effect'),
  ];

  late final TabController _tab = TabController(length: _tabs.length, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Items',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: _purple,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [for (final t in _tabs) Tab(text: t.$1)],
        ),
      ),
      body: StreamBuilder<AppUser>(
        stream: UserService().watchUser(_uid),
        builder: (_, userSnap) {
          final activeTags = userSnap.data?.activeTags ?? const <String>[];
          return TabBarView(
            controller: _tab,
            children: [
              for (final t in _tabs) _inventoryGrid(t.$2, activeTags),
            ],
          );
        },
      ),
    );
  }

  Widget _inventoryGrid(String? typeFilter, List<String> activeTags) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ShopService().watchInventory(_uid, type: typeFilter),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: _purple));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) return _empty(typeFilter);

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i];
            final item = shopItemById(d.id);
            if (item == null) return _unknownTile(d.id, d.data());
            final qty = (d.data()['quantity'] ?? 0) as int;
            final isWorn = activeTags.contains(item.id);
            return _itemCard(item, qty, isWorn);
          },
        );
      },
    );
  }

  Widget _itemCard(ShopItem item, int qty, bool isWorn) {
    return GestureDetector(
      onTap: () => _openActionSheet(item, qty, isWorn),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: isWorn
              ? Border.all(color: _gold, width: 2)
              : Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          item.gradient.first.withOpacity(0.4),
                          Colors.transparent,
                        ]),
                      ),
                      child: Center(
                        child: Text(item.emoji,
                            style: const TextStyle(fontSize: 50)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('x$qty',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (isWorn)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Wearing',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _purple.withOpacity(0.6)),
              ),
              child: const Text('Use',
                  style: TextStyle(
                      color: _purple,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unknownTile(String id, Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text('Unknown item\n$id',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 11)),
    );
  }

  Widget _empty(String? typeFilter) {
    final what = typeFilter == null ? 'items' : '${typeFilter}s';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text("You don't own any $what yet",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Buy items in the Shop to see them here',
                style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Shop',
                  style: TextStyle(color: _purple)),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // Action sheet — what you can DO with the item you own
  // ----------------------------------------------------------------
  void _openActionSheet(ShopItem item, int qty, bool isWorn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: item.gradient),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 12),
              Text(item.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Owned: x$qty',
                  style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 18),
              ..._actionsFor(item, isWorn),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actionsFor(ShopItem item, bool isWorn) {
    switch (item.type) {
      case ShopItemType.ring:
        return [
          _bigBtn(
            label: 'Propose with this ring 💍',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => UseItemPickerScreen(item: item),
              ));
            },
          ),
          const SizedBox(height: 8),
          _bigBtn(
            label: 'Quick propose to a specific user',
            outline: true,
            onTap: () async {
              Navigator.pop(context);
              await showCpProposeSheet(
                context,
                toUid: '', // empty → CP sheet falls back to its own ring picker
                toName: 'Choose recipient',
                preselectedRingId: item.id,
              );
            },
          ),
        ];

      case ShopItemType.tag:
        return [
          _bigBtn(
            label: isWorn ? 'Take off this tag' : 'Wear this tag 🏷️',
            onTap: () async {
              Navigator.pop(context);
              await _toggleWear(item.id);
            },
          ),
          const SizedBox(height: 8),
          _bigBtn(
            label: 'Send to a friend',
            outline: true,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => UseItemPickerScreen(item: item),
              ));
            },
          ),
        ];

      case ShopItemType.badge:
      case ShopItemType.seat:
      case ShopItemType.frame:
      case ShopItemType.effect:
      case ShopItemType.other:
        return [
          _bigBtn(
            label: 'Equip (coming soon)',
            disabled: true,
            onTap: () {},
          ),
        ];
    }
  }

  Future<void> _toggleWear(String tagId) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    final current = List<String>.from(
        (snap.data()?['activeTags'] as List?) ?? const []);
    if (current.contains(tagId)) {
      current.remove(tagId);
    } else {
      if (current.length >= 3) current.removeAt(0); // max 3, FIFO
      current.add(tagId);
    }
    await ShopService().setActiveTags(uid: _uid, tagIds: current);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(current.contains(tagId)
            ? 'Tag equipped 🏷️'
            : 'Tag removed'),
      ),
    );
  }

  Widget _bigBtn({
    required String label,
    required VoidCallback onTap,
    bool outline = false,
    bool disabled = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: outline ? Colors.transparent : _purple,
          disabledBackgroundColor: Colors.white12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: outline
                ? const BorderSide(color: _purple, width: 1.5)
                : BorderSide.none,
          ),
          elevation: outline ? 0 : 2,
        ),
        child: Text(label,
            style: TextStyle(
                color: outline ? _purple : Colors.white,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
