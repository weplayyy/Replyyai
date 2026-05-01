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

  ({int luckyCoins, bool jackpot}) _rollLucky(int price) {
    if (price < 100) return (luckyCoins: 0, jackpot: false);
    final isJackpot = _rng.nextInt(100) == 0;
    if (isJackpot) {
      final extra = _rng.nextInt(price * 7 + 1);
      return (luckyCoins: price * 3 + extra, jackpot: true);
    }
    return (luckyCoins: _rng.nextInt(price + 1), jackpot: false);
  }

  Future<void> _upsertGuardian({
    required String fromUid,
    required String toUid,
    required int charms,
  }) async {
    final senderSnap = await _db.collection('users').doc(fromUid).get();
    final s = senderSnap.data() ?? {};
    final guardianRef = _db
        .collection('users')
        .doc(toUid)
        .collection('guardians')
        .doc(fromUid);
    await guardianRef.set({
      'uid': fromUid,
      'displayName': s['displayName'] ?? 'User',
      'photoURL': s['photoURL'],
      'totalCharms': FieldValue.increment(charms),
      'lastGiftAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
    // Called after every gift. If sender and receiver are CP partners,
  // the charm value is added to their couple's cpGrowthCharms field.
  Future<void> _updateCpGrowth({
    required String fromUid,
    required String toUid,
    required int charms,
  }) async {
    try {
      final senderSnap = await _db.collection('users').doc(fromUid).get();
      final senderData = senderSnap.data() ?? {};
      final coupleId   = senderData['cpCoupleId'] as String?;
      if (coupleId == null || coupleId.isEmpty) return;

      final coupleRef  = _db.collection('couples').doc(coupleId);
      final coupleSnap = await coupleRef.get();
      final coupleData = coupleSnap.data() ?? {};

      // Verify receiver is the other partner in this couple
      final uid1 = coupleData['uid1'] as String?;
      final uid2 = coupleData['uid2'] as String?;
      final isPartner = (uid1 == fromUid && uid2 == toUid) ||
                        (uid2 == fromUid && uid1 == toUid);
      if (!isPartner) return;

      // Accumulate growth on the couple doc
      await coupleRef.update({
        'cpGrowthCharms': FieldValue.increment(charms),
        'lastGrowthAt':   FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-critical — never block a gift because of CP growth failure
    }
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

      tx.update(senderRef, {'coins': senderCoins - gift.price});

      tx.update(receiverRef, {
        'coins': receiverCoins + roll.luckyCoins,
        'charms': newReceiverCharms,
      });
    });

    await _upsertGuardian(fromUid: fromUid, toUid: toUid, charms: charms);
        await _upsertGuardian(fromUid: fromUid, toUid: toUid, charms: charms);
    await _updateCpGrowth(fromUid: fromUid, toUid: toUid, charms: charms);
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
      });
    });

    await _upsertGuardian(fromUid: fromUid, toUid: toUid, charms: charms);

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
