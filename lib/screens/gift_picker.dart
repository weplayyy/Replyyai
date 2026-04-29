import 'package:flutter/material.dart';
import '../models/gift.dart';
import 'gift_animation_overlay.dart';

const _bg = Color(0xFF120821);
const _cardBg = Color(0xFF1B0E32);
const _accentPink = Color(0xFFEC4899);
const _accentPurple = Color(0xFF8B5CF6);
const _coinYellow = Color(0xFFFBBF24);

const _topTabs = ['Gift', 'Effects', 'Luxury', 'Special', 'Event'];

const List<Map<String, String>> _chips = [
  {'icon': '🔥', 'label': 'Hot'},
  {'icon': '💖', 'label': 'Love'},
  {'icon': '🚗', 'label': 'Ride'},
  {'icon': '✨', 'label': 'Premium'},
  {'icon': '😄', 'label': 'Fun'},
  {'icon': '🌸', 'label': 'All'},
];

Future<Gift?> showGiftPicker(BuildContext context, int balance) {
  return showModalBottomSheet<Gift>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _GiftPickerSheet(balance: balance),
  );
}

class _GiftPickerSheet extends StatefulWidget {
  final int balance;
  const _GiftPickerSheet({required this.balance});
  @override
  State<_GiftPickerSheet> createState() => _GiftPickerSheetState();
}

class _GiftPickerSheetState extends State<_GiftPickerSheet> {
  int _topTab = 0;
  int _chip = 0;
  int _selected = 0;
  int _quantity = 1;
  int _page = 0;
  final _pageCtrl = PageController();

  static const int _perPage = 8;

  List<Gift> get _gifts => kAllGifts;

  int get _pageCount =>
      _gifts.isEmpty ? 1 : ((_gifts.length + _perPage - 1) ~/ _perPage);

  Gift? get _selectedGift =>
      _gifts.isEmpty ? null : _gifts[_selected.clamp(0, _gifts.length - 1)];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (_, __) => Container(
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            _grabber(),
            _topTabsRow(),
            const SizedBox(height: 6),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 14),
            _chipsRow(),
            const SizedBox(height: 14),
            Expanded(child: _grid()),
            const SizedBox(height: 8),
            _dots(),
            const SizedBox(height: 10),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _grabber() => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _topTabsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 14, 0),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_topTabs.length, (i) {
                  final active = i == _topTab;
                  return GestureDetector(
                    onTap: () => setState(() => _topTab = i),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _topTabs[i],
                            style: TextStyle(
                              color: active ? Colors.white : Colors.white54,
                              fontSize: 18,
                              fontWeight:
                                  active ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 22,
                            height: 3,
                            decoration: BoxDecoration(
                              color: active ? _accentPink : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          _balancePill(),
        ],
      ),
    );
  }

  Widget _balancePill() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _coinChip(size: 18),
          const SizedBox(width: 6),
          Text(
            _formatBalance(widget.balance),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
          const SizedBox(width: 6),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_accentPink, _accentPurple],
              ),
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _chipsRow() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final c = _chips[i];
          final active = i == _chip;
          return GestureDetector(
            onTap: () => setState(() => _chip = i),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [_accentPink, _accentPurple])
                    : null,
                color: active ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c['icon']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    c['label']!,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _grid() {
    if (_gifts.isEmpty) {
      return const Center(
        child: Text('No gifts yet',
            style: TextStyle(color: Colors.white54)),
      );
    }
    return PageView.builder(
      controller: _pageCtrl,
      onPageChanged: (i) => setState(() => _page = i),
      itemCount: _pageCount,
      itemBuilder: (_, page) {
        final start = page * _perPage;
        final end = (start + _perPage).clamp(0, _gifts.length);
        final pageGifts = _gifts.sublist(start, end);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: pageGifts.length,
          itemBuilder: (_, i) {
            final globalIndex = start + i;
            return _giftCard(pageGifts[i], globalIndex);
          },
        );
      },
    );
  }
    Widget _giftCard(Gift g, int index) {
    final selected = index == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = index),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          border: Border.all(
            color: selected ? _accentPink : Colors.white.withOpacity(0.06),
            width: selected ? 1.6 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _accentPink.withOpacity(0.45),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
              child: Column(
                children: [
                  Expanded(
                    child: Center(child: GiftIcon(gift: g, size: 64)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _coinChip(size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _formatPrice(g.price),
                        style: const TextStyle(
                          color: _coinYellow,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (g.badge != null)
              Positioned(top: 6, right: 6, child: _badge(g.badge!)),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accentPurple, _accentPink],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(13),
          bottomLeft: Radius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? _accentPink : Colors.white24,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _bottomBar() {
    final g = _selectedGift;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF160B26),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: g == null
                ? const SizedBox.shrink()
                : GiftIcon(gift: g, size: 48),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  g?.name ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.diamond,
                        color: _accentPurple, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+${_charmFor(g?.price ?? 0)} Charm',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _specialEffectButton(g),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _qtyStepper(),
          const SizedBox(width: 8),
          _sendButton(g),
        ],
      ),
    );
  }

  Widget _specialEffectButton(Gift? g) {
    final hasEffect = g?.videoAsset != null && g!.videoAsset!.isNotEmpty;
    return GestureDetector(
      onTap: hasEffect
          ? () => playGiftAnimation(context, g.videoAsset!)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(hasEffect ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Special Effect',
              style: TextStyle(
                color: hasEffect ? Colors.white : Colors.white38,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: hasEffect ? _accentPink : Colors.white12,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyStepper() {
    Widget btn(IconData ic, VoidCallback onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            child: Icon(ic, color: Colors.white70, size: 16),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, () {
            if (_quantity > 1) setState(() => _quantity--);
          }),
          SizedBox(
            width: 22,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ),
          btn(Icons.add, () => setState(() => _quantity++)),
        ],
      ),
    );
  }

  Widget _sendButton(Gift? g) {
    final price = (g?.price ?? 0) * _quantity;
    final canAfford = g != null && widget.balance >= price;
    return GestureDetector(
      onTap: () {
        if (g == null) return;
        if (!canAfford) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not enough coins')),
          );
          return;
        }
        Navigator.pop(context, g);
      },
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.5,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_accentPink, _accentPurple],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _accentPink.withOpacity(0.45),
                blurRadius: 14,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Send',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _coinChip(size: 12),
                  const SizedBox(width: 3),
                  Text(
                    _formatPrice(price),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coinChip({double size = 16}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFFD86B), Color(0xFFF59E0B)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '\$',
        style: TextStyle(
          color: const Color(0xFF7A3E00),
          fontWeight: FontWeight.bold,
          fontSize: size * 0.7,
        ),
      ),
    );
  }

  String _formatBalance(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatPrice(int n) => _formatBalance(n);

  int _charmFor(int price) => (price * 0.3).round();
}
