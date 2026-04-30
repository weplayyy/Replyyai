import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop_item.dart';
import '../services/shop_service.dart';
import 'use_item_picker_screen.dart';
import 'my_items_screen.dart';
import 'cp_inbox_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final Map<ShopCategory, String> _activeSub = {};

  static const _bg = Color(0xFF0B0717);
  static const _card = Color(0xFF181028);
  static const _purple = Color(0xFF7C5CFF);
  static const _diamond = Color(0xFFA78BFA);
  static const _gold = Color(0xFFFFC542);

  static const _categories = [
    ShopCategory.relationship,
    ShopCategory.decorations,
    ShopCategory.voiceRoom,
    ShopCategory.effects,
    ShopCategory.other,
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _categories.length, vsync: this);
    for (final c in _categories) {
      _activeSub[c] = (kSubCategories[c] ?? const ['']).first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 8),
            _tabBar(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: _categories.map(_categoryView).toList(),
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  // -------------------- TOP BAR --------------------
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 4),
          const Text('Shop',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_uid)
                .snapshots(),
            builder: (_, s) {
              final d = s.data?.data() ?? const {};
              final coins = (d['coins'] ?? 0) as int;
              final clanCoins = (d['clanCoins'] ?? 0) as int;
              return Row(
                children: [
                  _balancePill(_diamond, '💎', clanCoins),
                  const SizedBox(width: 6),
                  _balancePill(_gold, '⭐', coins),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined,
                color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyItemsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _balancePill(Color color, String icon, int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(_fmt(n),
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(width: 4),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.add, color: color, size: 12),
          ),
        ],
      ),
    );
  }

  // -------------------- TAB BAR --------------------
  Widget _tabBar() {
    return TabBar(
      controller: _tab,
      isScrollable: true,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      labelStyle:
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      unselectedLabelStyle: const TextStyle(fontSize: 14),
      indicatorColor: _purple,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: _categories.map((c) => Tab(text: kCategoryLabels[c])).toList(),
    );
  }

  // -------------------- ONE CATEGORY VIEW --------------------
  Widget _categoryView(ShopCategory category) {
    final subs = kSubCategories[category] ?? const <String>[];
    return Column(
      children: [
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: subs.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return _chip('All',
                    selected: _activeSub[category] == '__all__',
                    onTap: () =>
                        setState(() => _activeSub[category] = '__all__'));
              }
              final id = subs[i - 1];
              return _chip(
                kSubCategoryLabels[id] ?? id,
                selected: _activeSub[category] == id,
                icon: id.contains('ring') ? '💍' : null,
                onTap: () => setState(() => _activeSub[category] = id),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _grid(category)),
      ],
    );
  }

  Widget _chip(String label,
      {required bool selected, String? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _purple.withOpacity(0.25) : Colors.white10,
          border: Border.all(
              color: selected ? _purple : Colors.transparent, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  // -------------------- ITEM GRID --------------------
  Widget _grid(ShopCategory category) {
    final sub = _activeSub[category];
    final items = shopItemsBy(
      category: category,
      subCategory: (sub == null || sub == '__all__') ? null : sub,
    );

    if (items.isEmpty) {
      return const Center(
        child: Text('Coming soon',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ShopService().watchInventory(_uid),
      builder: (_, invSnap) {
        final owned = <String, int>{
          for (final d in invSnap.data?.docs ?? const [])
            d.id: (d.data()['quantity'] ?? 0) as int
        };
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.82,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) =>
                  _itemCard(items[i], owned[items[i].id] ?? 0),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _purple.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('View More',
                        style: TextStyle(
                            color: _purple, fontWeight: FontWeight.w600)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: _purple),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _itemCard(ShopItem item, int ownedQty) {
    final isClan = item.currency == ShopCurrency.clanCoins;
    final currColor = isClan ? _diamond : _gold;
    final currIcon = isClan ? '💎' : '⭐';

    return GestureDetector(
      onTap: () => _openItemSheet(item, ownedQty),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            item.gradient.first.withOpacity(0.45),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(item.emoji,
                            style: const TextStyle(fontSize: 56)),
                      ),
                    ),
                  ),
                  if (item.badge != null)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: item.badge == 'Hot'
                                  ? const [
                                      Color(0xFFEC4899),
                                      Color(0xFFEF4444)
                                    ]
                                  : const [
                                      Color(0xFF7C5CFF),
                                      Color(0xFFA78BFA)
                                    ]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item.badge!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Icon(Icons.favorite_border,
                        color: Colors.white.withOpacity(0.7), size: 18),
                  ),
                  if (ownedQty > 0)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('x$ownedQty',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(currIcon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(_fmt(item.price),
                          style: TextStyle(
                              color: currColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- BOTTOM NAV --------------------
  Widget _bottomNav() {
    Widget item(IconData icon, String label,
        {bool selected = false, VoidCallback? onTap}) {
      final color = selected ? _purple : Colors.white60;
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: selected
                ? BoxDecoration(
                    color: _purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          item(Icons.shopping_bag, 'Shop', selected: true, onTap: () {}),
          item(Icons.inventory_2_outlined, 'My Items',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MyItemsScreen()))),
          item(Icons.favorite, 'CP Inbox',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CpInboxScreen()))),
          item(Icons.diamond_outlined, 'Top Up', onTap: () {}),
        ],
      ),
    );
  }

  // -------------------- ITEM SHEET (Buy / Use) --------------------
  void _openItemSheet(ShopItem item, int ownedQty) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 10),
              Text(item.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Owned: x$ownedQty',
                  style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 18),
              if (ownedQty > 0) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      if (item.type == ShopItemType.ring ||
                          item.type == ShopItemType.tag) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => UseItemPickerScreen(item: item),
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Equip coming soon')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: Text(
                      item.type == ShopItemType.ring
                          ? 'Use to Propose'
                          : item.type == ShopItemType.tag
                              ? 'Use / Send Tag'
                              : 'Use',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmBuy(item);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    ownedQty > 0
                        ? 'Buy another (${_fmt(item.price)})'
                        : 'Buy for ${_fmt(item.price)}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------- BUY --------------------
  Future<void> _confirmBuy(ShopItem item) async {
    final currName =
        item.currency == ShopCurrency.coins ? 'coins' : 'Guard Points';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: Text('Buy ${item.name}?',
            style: const TextStyle(color: Colors.white)),
        content: Text('Cost: ${_fmt(item.price)} $currName',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buy', style: TextStyle(color: _purple)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ShopService().buy(uid: _uid, item: item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bought ${item.name}!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
