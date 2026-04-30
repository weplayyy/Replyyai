import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/friendship.dart';

/// All friend-related read/write logic.
///
/// Mirroring rule: every state change writes BOTH sides in the same batch
/// so the two users never disagree about the friendship status.
class FriendService {
  FriendService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _me => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _friendsOf(String uid) =>
      _db.collection('users').doc(uid).collection('friends');

  // ---------------------------------------------------------------------------
  // READS
  // ---------------------------------------------------------------------------

  /// All accepted friends of the current user, newest first.
  Stream<List<Friendship>> watchMyFriends() {
    return _friendsOf(_me)
        .where('status', isEqualTo: FriendStatus.accepted.toRaw())
        .snapshots()
        .map((s) => s.docs
            .map((d) => Friendship.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt)));
  }

  /// Incoming friend requests waiting on me to accept/decline.
  Stream<List<Friendship>> watchIncomingRequests() {
    return _friendsOf(_me)
        .where('status', isEqualTo: FriendStatus.pendingIncoming.toRaw())
        .snapshots()
        .map((s) => s.docs
            .map((d) => Friendship.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt)));
  }

  /// Outgoing requests I've sent that are still pending.
  Stream<List<Friendship>> watchOutgoingRequests() {
    return _friendsOf(_me)
        .where('status', isEqualTo: FriendStatus.pendingOutgoing.toRaw())
        .snapshots()
        .map((s) => s.docs
            .map((d) => Friendship.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt)));
  }

  /// Live friendship status with one specific user.
  /// Emits null if no relationship doc exists (i.e. strangers).
  Stream<Friendship?> watchFriendship(String otherUid) {
    return _friendsOf(_me).doc(otherUid).snapshots().map(
          (d) => d.exists ? Friendship.fromMap(d.id, d.data()!) : null,
        );
  }

  /// One-shot check — true only if status == accepted.
  Future<bool> areFriends(String otherUid) async {
    final doc = await _friendsOf(_me).doc(otherUid).get();
    if (!doc.exists) return false;
    return FriendStatusX.fromRaw(doc.data()?['status'] as String?) ==
        FriendStatus.accepted;
  }

  /// Live count of accepted friends — useful for profile screens.
  Stream<int> watchFriendCount() {
    return _friendsOf(_me)
        .where('status', isEqualTo: FriendStatus.accepted.toRaw())
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ---------------------------------------------------------------------------
  // WRITES
  // ---------------------------------------------------------------------------

  /// Send a friend request to [otherUid]. Reads both user docs once
  /// to denormalize displayName/photoUrl/charms onto both sides.
  Future<void> sendRequest(String otherUid) async {
    if (otherUid == _me) {
      throw Exception("You can't friend yourself.");
    }

    final mine = await _friendsOf(_me).doc(otherUid).get();
    if (mine.exists) {
      final status =
          FriendStatusX.fromRaw(mine.data()?['status'] as String?);
      if (status == FriendStatus.accepted) {
        throw Exception('You are already friends.');
      }
      if (status == FriendStatus.pendingOutgoing) {
        throw Exception('Request already sent.');
      }
      if (status == FriendStatus.pendingIncoming) {
        // They already sent us a request — auto-accept instead.
        return acceptRequest(otherUid);
      }
      if (status == FriendStatus.blocked) {
        throw Exception('Unblock this user before sending a request.');
      }
    }

    final meDoc = await _db.collection('users').doc(_me).get();
    final otherDoc = await _db.collection('users').doc(otherUid).get();
    if (!otherDoc.exists) {
      throw Exception('User not found.');
    }

    final me = meDoc.data() ?? {};
    final other = otherDoc.data() ?? {};

    final batch = _db.batch();

    batch.set(_friendsOf(_me).doc(otherUid), {
      'uid': otherUid,
      'displayName': other['displayName'] ?? 'User',
      'photoUrl': other['photoURL'],
      'charms': other['charms'] ?? 0,
      'status': FriendStatus.pendingOutgoing.toRaw(),
      'addedAt': FieldValue.serverTimestamp(),
    });

    batch.set(_friendsOf(otherUid).doc(_me), {
      'uid': _me,
      'displayName': me['displayName'] ?? 'User',
      'photoUrl': me['photoURL'],
      'charms': me['charms'] ?? 0,
      'status': FriendStatus.pendingIncoming.toRaw(),
      'addedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Accept a request that came in from [otherUid]. Increments
  /// `friendsCount` on both user docs.
  Future<void> acceptRequest(String otherUid) async {
    final batch = _db.batch();

    batch.update(_friendsOf(_me).doc(otherUid), {
      'status': FriendStatus.accepted.toRaw(),
      'addedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_friendsOf(otherUid).doc(_me), {
      'status': FriendStatus.accepted.toRaw(),
      'addedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_db.collection('users').doc(_me),
        {'friendsCount': FieldValue.increment(1)});
    batch.update(_db.collection('users').doc(otherUid),
        {'friendsCount': FieldValue.increment(1)});

    await batch.commit();
  }

  /// Decline a pending incoming request, OR cancel a pending outgoing one.
  /// Removes both sides cleanly. Does NOT touch friendsCount (no friendship
  /// existed yet).
  Future<void> declineOrCancel(String otherUid) async {
    final batch = _db.batch();
    batch.delete(_friendsOf(_me).doc(otherUid));
    batch.delete(_friendsOf(otherUid).doc(_me));
    await batch.commit();
  }

  /// Remove an existing friend. Decrements `friendsCount` on both sides.
  Future<void> removeFriend(String otherUid) async {
    final batch = _db.batch();
    batch.delete(_friendsOf(_me).doc(otherUid));
    batch.delete(_friendsOf(otherUid).doc(_me));
    batch.update(_db.collection('users').doc(_me),
        {'friendsCount': FieldValue.increment(-1)});
    batch.update(_db.collection('users').doc(otherUid),
        {'friendsCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  /// Block another user. Removes any friendship and writes a one-sided
  /// blocked record on my side so the UI can hide them everywhere.
  Future<void> blockUser(String otherUid) async {
    final batch = _db.batch();

    final wasFriend = await areFriends(otherUid);

    batch.set(_friendsOf(_me).doc(otherUid), {
      'uid': otherUid,
      'displayName': '',
      'photoUrl': null,
      'charms': 0,
      'status': FriendStatus.blocked.toRaw(),
      'addedAt': FieldValue.serverTimestamp(),
    });
    // Wipe their record of me so they don't see a stale friendship.
    batch.delete(_friendsOf(otherUid).doc(_me));

    if (wasFriend) {
      batch.update(_db.collection('users').doc(_me),
          {'friendsCount': FieldValue.increment(-1)});
      batch.update(_db.collection('users').doc(otherUid),
          {'friendsCount': FieldValue.increment(-1)});
    }

    await batch.commit();
  }

  Future<void> unblock(String otherUid) =>
      _friendsOf(_me).doc(otherUid).delete();
}
