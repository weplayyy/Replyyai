import 'package:cloud_firestore/cloud_firestore.dart';

class TagService {
  final _db = FirebaseFirestore.instance;

  Future<void> sendTag({
    required String fromUid,
    required String toUid,
    required String tagId,
  }) async {
    final myInvRef = _db
        .collection('users')
        .doc(fromUid)
        .collection('inventory')
        .doc(tagId);
    final theirInvRef = _db
        .collection('users')
        .doc(toUid)
        .collection('inventory')
        .doc(tagId);

    await _db.runTransaction((tx) async {
      final mine = await tx.get(myInvRef);
      final qty = (mine.data()?['quantity'] ?? 0) as int;
      if (qty < 1) throw Exception("You don't own this tag");

      final theirs = await tx.get(theirInvRef);
      final theirQty = (theirs.data()?['quantity'] ?? 0) as int;

      if (qty <= 1) {
        tx.delete(myInvRef);
      } else {
        tx.update(myInvRef, {'quantity': qty - 1});
      }

      tx.set(
        theirInvRef,
        {
          'itemId': tagId,
          'type': 'tag',
          'quantity': theirQty + 1,
          'lastReceivedAt': FieldValue.serverTimestamp(),
          'lastReceivedFrom': fromUid,
        },
        SetOptions(merge: true),
      );
    });
  }
}
