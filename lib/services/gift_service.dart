import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gift.dart';

class GiftSendResult {
  final int charms;
  final int luckyCoins;
  final bool jackpot;
  GiftSendResult({
    required this.charms,
    required this.luckyCoins,
    required this.jackpot,
  });
}

class GiftService {
  final _db = FirebaseFirestore.instance;
  final _rng = Random();

  String _chatId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// 1% chance of jackpot (3x..10x of price).
  /// Otherwise random 0..price inclusive.
  /// Gifts under 100 give no lucky coins.
  ({int luckyCoins, bool jackpot}) _rollLucky(int price) {
    if (price < 100) return (luckyCoins: 0, jackpot: false);
    final isJackpot = _rng.nextInt(100) == 0; // exactly 1/100
    if (isJackpot) {
      final extra = _rng.nextInt(price * 7 + 1); // 0..7*price
      return (luckyCoins: price * 3 + extra, jackpot: true);
    }
    return (luckyCoins: _rng.nextInt(price + 1), jackpot: false);
  }

  Future<GiftSendResult> sendGift({
    required String fromUid,
    required String toUid,
    required Gift gift,
  }) async {
    final senderRef = _db.collection('users').doc(fromUid);
    final receiverRef = _db.collection('users').doc(toUid);

    final charms = (gift.price * 0.3).round();
    final roll = _rollLucky(gift.price);

    await _db.runTransaction((tx) async {
      final senderSnap = await tx.get(senderRef);
      final receiverSnap = await tx.get(receiverRef);

      final senderCoins = (senderSnap.data()?['coins'] ?? 0) as int;
      if (senderCoins < gift.price) {
        throw Exception('Not enough coins');
      }
      final receiverCoins = (receiverSnap.data()?['coins'] ?? 0) as int;
      final receiverCharms = (receiverSnap.data()?['charms'] ?? 0) as int;
      final newReceiverCharms = receiverCharms + charms;

      // Sender: only coins are deducted. No charms, no level bump.
      tx.update(senderRef, {'coins': senderCoins - gift.price});

      // Receiver: gets charms + lucky coins, level recomputed.
      tx.update(receiverRef, {
        'coins': receiverCoins + roll.luckyCoins,
        'charms': newReceiverCharms,
        'level': 1 + (newReceiverCharms ~/ 100),
      });
    });

    final chatRef = _db.collection('chats').doc(_chatId(fromUid, toUid));
    await chatRef.set({
      'participants': [fromUid, toUid],
      'lastMessage': '🎁 ${gift.name}',
      'lastSenderId': fromUid,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': fromUid,
      'text': '🎁 ${gift.name}',
      'type': 'gift',
      'giftId': gift.id,
      'giftName': gift.name,
      'giftIcon': gift.icon,
      'giftPrice': gift.price,
      'giftVideo': gift.videoAsset,
      'charms': charms,
      'luckyCoins': roll.luckyCoins,
      'jackpot': roll.jackpot,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return GiftSendResult(
      charms: charms,
      luckyCoins: roll.luckyCoins,
      jackpot: roll.jackpot,
    );
  }

  /// Same rules as [sendGift] but the message lands in a room feed.
  Future<GiftSendResult> sendGiftInRoom({
    required String fromUid,
    required String toUid,
    required String roomId,
    required Gift gift,
  }) async {
    final senderRef = _db.collection('users').doc(fromUid);
    final receiverRef = _db.collection('users').doc(toUid);

    final charms = (gift.price * 0.3).round();
    final roll = _rollLucky(gift.price);

    await _db.runTransaction((tx) async {
      final senderSnap = await tx.get(senderRef);
      final receiverSnap = await tx.get(receiverRef);

      final senderCoins = (senderSnap.data()?['coins'] ?? 0) as int;
      if (senderCoins < gift.price) {
        throw Exception('Not enough coins');
      }
      final receiverCoins = (receiverSnap.data()?['coins'] ?? 0) as int;
      final receiverCharms = (receiverSnap.data()?['charms'] ?? 0) as int;
      final newReceiverCharms = receiverCharms + charms;

      tx.update(senderRef, {'coins': senderCoins - gift.price});

      tx.update(receiverRef, {
        'coins': receiverCoins + roll.luckyCoins,
        'charms': newReceiverCharms,
        'level': 1 + (newReceiverCharms ~/ 100),
      });
    });

    await _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderId': fromUid,
      'receiverId': toUid,
      'text': '🎁 ${gift.name}',
      'type': 'gift',
      'giftId': gift.id,
      'giftName': gift.name,
      'giftIcon': gift.icon,
      'giftPrice': gift.price,
      'giftVideo': gift.videoAsset,
      'charms': charms,
      'luckyCoins': roll.luckyCoins,
      'jackpot': roll.jackpot,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return GiftSendResult(
      charms: charms,
      luckyCoins: roll.luckyCoins,
      jackpot: roll.jackpot,
    );
  }
}
