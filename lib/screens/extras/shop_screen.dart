import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/user_service.dart';
import '../../models/app_user.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const _packages = [
    _Pack('Starter', 100, 0.99, '🪙', [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
    _Pack('Popular', 600, 4.99, '💰', [Color(0xFFEC4899), Color(0xFFF472B6)],
        badge: 'POPULAR'),
    _Pack('Pro', 1500, 9.99, '💎', [Color(0xFF06B6D4), Color(0xFF22D3EE)]),
    _Pack('Mega', 4000, 24.99, '🎁', [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        badge: 'BEST VALUE'),
    _Pack('Whale', 10000, 49.99, '🏆', [Color(0xFFEF4444), Color(0xFFF87171)]),
  ];

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0B2E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Coin Shop', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<AppUser>(
        stream: UserService().watchUser(me.uid),
        builder: (context, snap) {
          final coins = snap.data?.coins ?? 0;
          return Column(
            children: [
              _balanceBar(coins),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _packages.length,
                  itemBuilder: (_, i) =>
                      _packCard(context, _packages[i], me.uid),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _balanceBar(int coins) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
            colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)]),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const Text('🪙', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          const Text('Your balance',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text('$coins',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _packCard(BuildContext context, _Pack p, String uid) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient:
                  LinearGradient(colors: p.colors),
            ),
            alignment: Alignment.center,
            child: Text(p.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    if (p.badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(p.badge!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('${p.coins} coins',
                    style: const TextStyle(
                        color: Color(0xFFB794F6), fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
            ),
            onPressed: () => _buy(context, p, uid),
            child: Text('\$${p.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(BuildContext context, _Pack p, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A0B2E),
        title: Text('Buy ${p.name}?',
            style: const TextStyle(color: Colors.white)),
        content: Text(
            'You\'ll receive ${p.coins} coins for \$${p.price.toStringAsFixed(2)}.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Buy',
                  style: TextStyle(
                      color: Color(0xFFEC4899),
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'coins': FieldValue.increment(p.coins)});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF8B5CF6),
        content: Text('+${p.coins} coins added 🎉'),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    }
  }
}

class _Pack {
  final String name;
  final int coins;
  final double price;
  final String emoji;
  final List<Color> colors;
  final String? badge;
  const _Pack(this.name, this.coins, this.price, this.emoji, this.colors,
      {this.badge});
}
