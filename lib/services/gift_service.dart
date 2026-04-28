import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gift.dart';

class GiftSendResult {
  final int charms;
  final int luckyCoins;
  GiftSendResult({required this.charms, required this.luckyCoins});
}

class GiftService {
  final _db = FirebaseFirestore.instance;
  final _rng = Random();

  String _chatId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<GiftSendResult> sendGift({
    required String fromUid,
    required String toUid,
    required Gift gift,
  }) async {
    final senderRef = _db.collection('users').doc(fromUid);
    final receiverRef = _db.collection('users').doc(toUid);

    final charms = (gift.price * 0.3).round();
    final luckyCoins =
        gift.price >= 100 ? 1 + _rng.nextInt(gift.price * 3) : 0;

    await _db.runTransaction((tx) async {
      final senderSnap = await tx.get(senderRef);
      final receiverSnap = await tx.get(receiverRef);

      final senderCoins = (senderSnap.data()?['coins'] ?? 0) as int;
      if (senderCoins < gift.price) {
        throw Exception('Not enough coins');
      }
      final senderCharms = (senderSnap.data()?['charms'] ?? 0) as int;
      final receiverCoins = (receiverSnap.data()?['coins'] ?? 0) as int;
      final receiverCharms = (receiverSnap.data()?['charms'] ?? 0) as int;

      final newSenderCharms = senderCharms + charms;
      final newReceiverCharms = receiverCharms + charms;

      tx.update(senderRef, {
        'coins': senderCoins - gift.price,
        'charms': newSenderCharms,
        'level': 1 + (newSenderCharms ~/ 100),
      });
      tx.update(receiverRef, {
        'coins': receiverCoins + luckyCoins,
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
      'charms': charms,
      'luckyCoins': luckyCoins,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return GiftSendResult(charms: charms, luckyCoins: luckyCoins);
  }
}
