import 'package:cloud_firestore/cloud_firestore.dart';

class CpService {
  final _db = FirebaseFirestore.instance;

  Future<void> sendCpRequest({
    required String fromUid,
    required String toUid,
  }) async {
    final me = (await _db.collection('users').doc(fromUid).get()).data() ?? {};
    await _db
        .collection('users')
        .doc(toUid)
        .collection('cp_requests')
        .doc(fromUid)
        .set({
      'fromUid': fromUid,
      'fromName': me['displayName'] ?? 'User',
      'fromPhoto': me['photoURL'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelCpRequest({
    required String fromUid,
    required String toUid,
  }) async {
    await _db
        .collection('users')
        .doc(toUid)
        .collection('cp_requests')
        .doc(fromUid)
        .delete();
  }

  Future<void> acceptCpRequest({
    required String myUid,
    required String fromUid,
  }) async {
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
        'cpSince': since,
      },
      SetOptions(merge: true),
    );
    batch.set(
      _db.collection('users').doc(fromUid),
      {
        'cpPartnerUid': myUid,
        'cpPartnerName': my['displayName'] ?? 'User',
        'cpSince': since,
      },
      SetOptions(merge: true),
    );
    batch.delete(_db
        .collection('users')
        .doc(myUid)
        .collection('cp_requests')
        .doc(fromUid));
    await batch.commit();
  }

  Future<void> breakCp({
    required String myUid,
    required String partnerUid,
  }) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(myUid), {
      'cpPartnerUid': FieldValue.delete(),
      'cpPartnerName': FieldValue.delete(),
      'cpSince': FieldValue.delete(),
    });
    batch.update(_db.collection('users').doc(partnerUid), {
      'cpPartnerUid': FieldValue.delete(),
      'cpPartnerName': FieldValue.delete(),
      'cpSince': FieldValue.delete(),
    });
    await batch.commit();
  }
}
