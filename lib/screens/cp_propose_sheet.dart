import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shop_item.dart';
import '../services/shop_service.dart';
import '../services/cp_service.dart';
import 'shop_screen.dart';

/// Show the propose-with-ring bottom sheet.
/// Pass [preselectedRingId] to jump straight to a specific ring
/// (used when the user taps "Use" on a ring in the shop).
Future<void> showCpProposeSheet(
  BuildContext context, {
  required String toUid,
  required String toName,
  String? preselectedRingId,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CpProposeSheet(
      toUid: toUid,
      toName: toName,
      preselectedRingId: preselectedRingId,
    ),
  );
}

class _CpProposeSheet extends StatefulWidget {
  final String toUid;
  final String toName;
  final String? preselectedRingId;
  const _CpProposeSheet({
    required this.toUid,
    required this.toName,
    this.preselectedRingId,
  });
  @override
  State<_CpProposeSheet> createState() => _CpProposeSheetState();
}

class _CpProposeSheetState extends State<_CpProposeSheet> {
  static const _bg = Color(0xFF181028);
  String? _selected;
  final _msgC = TextEditingController();
  final _myUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _selected = widget.preselectedRingId;
  }

  @override
  void dispose() {
    _msgC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Propose to ${widget.toName} 💍',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick a ring from your inventory',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: StreamBuilder(
              stream: ShopService().watchInventory(_myUid, type: 'ring'),
              builder: (_, snap) {
                final docs = (snap.data?.docs ?? const []).toList();
                if (docs.isEmpty) return _emptyRings();
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final id = docs[i].id;
                    final item = shopItemById(id);
                    if (item == null) return const SizedBox.shrink();
                    final qty = (docs[i].data()['quantity'] ?? 0) as int;
                    final isSelected = _selected == id;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = id),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFEC4899)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient:
                                    LinearGradient(colors: item.gradient),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'x$qty',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _msgC,
            style: const TextStyle(color: Colors.white),
            maxLength: 80,
            decoration: InputDecoration(
              hintText: 'Add a sweet message (optional)',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selected == null ? null : _propose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Send Proposal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRings() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💍', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            const Text(
              "You don't have any rings yet",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ShopScreen()),
                );
              },
              child: const Text(
                'Visit Shop',
                style: TextStyle(color: Color(0xFF7C5CFF)),
              ),
            ),
          ],
        ),
      );

  Future<void> _propose() async {
    try {
      await CpService().proposeCp(
        fromUid: _myUid,
        toUid: widget.toUid,
        ringId: _selected!,
        message: _msgC.text.trim().isEmpty ? null : _msgC.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal sent! 💌')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
      );
    }
  }
}
