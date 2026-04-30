import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_item.dart';

class ShopService {
  final _db = FirebaseFirestore.instance;

  /// Buy [item] for the user. Throws if balance is insufficient.
  Future<void> buy({
    required String uid,
    required ShopItem item,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final invRef = userRef.collection('inventory').doc(item.id);
    final field = item.currency == ShopCurrency.coins ? 'coins' : 'clanCoins';

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final invSnap = await tx.get(invRef);
      final balance = (userSnap.data()?[field] ?? 0) as int;
      if (balance < item.price) {
        throw Exception(item.currency == ShopCurrency.coins
            ? 'Not enough coins'
            : 'Not enough Clan Coins');
      }
      final qty = (invSnap.data()?['quantity'] ?? 0) as int;
      tx.update(userRef, {field: balance - item.price});
      tx.set(
        invRef,
        {
          'itemId': item.id,
          'type': _typeKey(item.type),
          'subCategory': item.subCategory,
          'quantity': qty + 1,
          'lastPurchasedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  String _typeKey(ShopItemType t) {
    switch (t) {
      case ShopItemType.ring:
        return 'ring';
      case ShopItemType.tag:
        return 'tag';
      case ShopItemType.badge:
        return 'badge';
      case ShopItemType.seat:
        return 'seat';
      case ShopItemType.frame:
        return 'frame';
      case ShopItemType.effect:
        return 'effect';
      case ShopItemType.other:
        return 'other';
    }
  }

  /// Watch a user's inventory. Optionally filter by item type
  /// ('ring', 'tag', 'badge', 'seat', 'frame', 'effect', 'other').
  Stream<QuerySnapshot<Map<String, dynamic>>> watchInventory(
    String uid, {
    String? type,
  }) {
    Query<Map<String, dynamic>> q =
        _db.collection('users').doc(uid).collection('inventory');
    if (type != null) q = q.where('type', isEqualTo: type);
    return q.snapshots();
  }

  /// Replace the user's currently equipped tag IDs (max 3 shown on profile).
  Future<void> setActiveTags({
    required String uid,
    required List<String> tagIds,
  }) async {
    await _db.collection('users').doc(uid).set({
      'activeTags': tagIds.take(3).toList(),
    }, SetOptions(merge: true));
  }

  /// Decrement (or remove) one ring of [ringId] from the user's inventory.
  /// Used after a CP proposal is accepted.
  Future<void> consumeRing({
    required String uid,
    required String ringId,
  }) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('inventory')
        .doc(ringId);
    await _db.runTransaction((tx) async {
      final s = await tx.get(ref);
      final qty = (s.data()?['quantity'] ?? 0) as int;
      if (qty <= 1) {
        tx.delete(ref);
      } else {
        tx.update(ref, {'quantity': qty - 1});
      }
    });
  }
}
