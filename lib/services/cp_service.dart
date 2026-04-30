import 'package:cloud_firestore/cloud_firestore.dart';
import 'shop_service.dart';

class CpService {
  final _db = FirebaseFirestore.instance;

  /// Send a CP proposal to [toUid] using a ring you already own.
  /// Throws if the sender doesn't own the ring.
  Future<void> proposeCp({
    required String fromUid,
    required String toUid,
    required String ringId,
    String? message,
  }) async {
    final me = (await _db.collection('users').doc(fromUid).get()).data() ?? {};

    // verify sender owns at least one of this ring
    final inv = await _db
        .collection('users')
        .doc(fromUid)
        .collection('inventory')
        .doc(ringId)
        .get();
    if (!inv.exists || ((inv.data()?['quantity'] ?? 0) as int) < 1) {
      throw Exception("You don't own this ring");
    }

    await _db
        .collection('users')
        .doc(toUid)
        .collection('cp_proposals')
        .doc(fromUid)
        .set({
      'fromUid': fromUid,
      'fromName': me['displayName'] ?? 'User',
      'fromPhoto': me['photoURL'],
      'ringId': ringId,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sender cancels their own outgoing proposal.
  Future<void> cancelProposal({
    required String fromUid,
    required String toUid,
  }) async {
    await _db
        .collection('users')
        .doc(toUid)
        .collection('cp_proposals')
        .doc(fromUid)
        .delete();
  }

  /// Recipient declines an incoming proposal.
  Future<void> declineProposal({
    required String myUid,
    required String fromUid,
  }) async {
    await _db
        .collection('users')
        .doc(myUid)
        .collection('cp_proposals')
        .doc(fromUid)
        .delete();
  }

  /// Recipient accepts the proposal — both users become CP partners,
  /// the ring is bonded to both profiles, and one ring is consumed
  /// from the sender's inventory.
  Future<void> acceptProposal({
    required String myUid,
    required String fromUid,
  }) async {
    final propRef = _db
        .collection('users')
        .doc(myUid)
        .collection('cp_proposals')
        .doc(fromUid);
    final prop = await propRef.get();
    if (!prop.exists) throw Exception('Proposal no longer exists');
    final ringId = prop.data()!['ringId'] as String;

    final my = (await _db.collection('users').doc(myUid).get()).data() ?? {};
    final them =
        (await _db.collection('users').doc(fromUid).get()).data() ?? {};
    final since = FieldValue.serverTimestamp();

    final batch = _db.batch();
    batch.set(
      _db.collection('users').doc(myUid),
      {
        'cpPartnerUid': fromUid,
        'cpPartnerName': them['displayName'] ?? 'User',
        'cpRingId': ringId,
        'cpSince': since,
      },
      SetOptions(merge: true),
    );
    batch.set(
      _db.collection('users').doc(fromUid),
      {
        'cpPartnerUid': myUid,
        'cpPartnerName': my['displayName'] ?? 'User',
        'cpRingId': ringId,
        'cpSince': since,
      },
      SetOptions(merge: true),
    );
    batch.delete(propRef);
    await batch.commit();

    // ring is consumed from sender's inventory after acceptance
    await ShopService().consumeRing(uid: fromUid, ringId: ringId);
  }

  /// Either partner can break the CP relationship.
  Future<void> breakCp({
    required String myUid,
    required String partnerUid,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(myUid), {
      'cpPartnerUid': FieldValue.delete(),
      'cpPartnerName': FieldValue.delete(),
      'cpRingId': FieldValue.delete(),
      'cpSince': FieldValue.delete(),
    });
    batch.update(_db.collection('users').doc(partnerUid), {
      'cpPartnerUid': FieldValue.delete(),
      'cpPartnerName': FieldValue.delete(),
      'cpRingId': FieldValue.delete(),
      'cpSince': FieldValue.delete(),
    });
    await batch.commit();
  }
}
