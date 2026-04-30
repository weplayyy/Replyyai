import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/room.dart';
import '../features/rooms/models/room_member.dart';
import '../features/rooms/models/room_message.dart';
import '../features/rooms/models/room_role.dart';

class RoomService {
  RoomService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _me => _auth.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');

  // ---------------------------------------------------------------------------
  // ROOM CRUD
  // ---------------------------------------------------------------------------

  /// Live rooms only, newest first. Requires a Firestore index on
  /// (status ASC, createdAt DESC) — Firebase will give you a one-click
  /// link the first time you run it.
  Stream<List<Room>> watchRooms({int limit = 100}) {
    return _rooms
        .where('status', isEqualTo: 'live')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Room.fromMap(d.id, d.data())).toList());
  }

  Future<Room?> getRoom(String id) async {
    final s = await _rooms.doc(id).get();
    if (!s.exists) return null;
    return Room.fromMap(s.id, s.data()!);
  }

  Stream<Room?> watchRoom(String id) {
    return _rooms.doc(id).snapshots().map(
        (s) => s.exists ? Room.fromMap(s.id, s.data()!) : null);
  }

    // ---------------------------------------------------------------------------
  // MODERATION — kick / mute / promote / demote.
  // Charm rule is enforced at the call site (see ManageMemberSheet); these
  // methods just do the writes. Firestore Security Rules should also enforce
  // the rule server-side (see comment block at the bottom of this file).
  // ---------------------------------------------------------------------------

  /// Hard-remove a member doc and decrement counters.
  Future<void> kickMember(String roomId, String targetUid) async {
    final ref = _rooms.doc(roomId).collection('members').doc(targetUid);
    final existing = await ref.get();
    if (!existing.exists) return;
    final wasPresent = (existing.data()?['isPresent'] ?? false) as bool;
    final name =
        (existing.data()?['displayName'] ?? 'A member') as String;

    final batch = _db.batch();
    batch.delete(ref);
    batch.update(_rooms.doc(roomId), {
      'memberCount': FieldValue.increment(-1),
      if (wasPresent) 'onlineCount': FieldValue.increment(-1),
    });
    await batch.commit();

    await postSystemMessage(roomId, '$name was removed from the room');
  }

  /// Set mutedUntil = now + duration.
  Future<void> muteMember(
      String roomId, String targetUid, Duration duration) async {
    final until = DateTime.now().add(duration);
    await _rooms.doc(roomId).collection('members').doc(targetUid).update({
      'mutedUntil': Timestamp.fromDate(until),
    });
  }

  Future<void> unmuteMember(String roomId, String targetUid) async {
    await _rooms.doc(roomId).collection('members').doc(targetUid).update({
      'mutedUntil': FieldValue.delete(),
    });
  }

  /// Owner-only — promote / demote.
  Future<void> setMemberRole(
      String roomId, String targetUid, RoomRole role) async {
    await _rooms.doc(roomId).collection('members').doc(targetUid).update({
      'role': role.toRaw(),
    });
  }

  /// Creates a room AND adds the creator as the OWNER member in one batch.
  Future<String> createRoom(Room room) async {
    final ref = _rooms.doc();
    final me = await _db.collection('users').doc(_me).get();
    final m = me.data() ?? {};

    final batch = _db.batch();
    batch.set(ref, room.toCreateMap());
    batch.set(ref.collection('members').doc(_me), {
      'uid': _me,
      'displayName': m['displayName'] ?? 'Owner',
      'photoUrl': m['photoURL'],
      'charms': m['charms'] ?? 0,
      'role': RoomRole.owner.toRaw(),
      'joinedAt': FieldValue.serverTimestamp(),
      'isPresent': true,
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return ref.id;
  }

  /// Soft delete — flips status. Cleanup of subcollections happens via
  /// the scheduled function (Slice 5).
  Future<void> deleteRoom(String roomId) async {
    await _rooms.doc(roomId).update({
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // MEMBERSHIP & PRESENCE
  // ---------------------------------------------------------------------------

  /// Idempotent — refreshes denormalized fields if already a member.
  Future<void> joinRoom(String roomId) async {
    final ref = _rooms.doc(roomId).collection('members').doc(_me);
    final existing = await ref.get();
    final me = await _db.collection('users').doc(_me).get();
    final m = me.data() ?? {};

    final batch = _db.batch();

    if (!existing.exists) {
      batch.set(ref, {
        'uid': _me,
        'displayName': m['displayName'] ?? 'User',
        'photoUrl': m['photoURL'],
        'charms': m['charms'] ?? 0,
        'role': RoomRole.member.toRaw(),
        'joinedAt': FieldValue.serverTimestamp(),
        'isPresent': true,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      batch.update(_rooms.doc(roomId), {
        'memberCount': FieldValue.increment(1),
        'onlineCount': FieldValue.increment(1),
      });
    } else {
      final wasPresent = (existing.data()?['isPresent'] ?? false) as bool;
      batch.update(ref, {
        'displayName': m['displayName'] ?? 'User',
        'photoUrl': m['photoURL'],
        'charms': m['charms'] ?? 0,
        'isPresent': true,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      if (!wasPresent) {
        batch.update(_rooms.doc(roomId),
            {'onlineCount': FieldValue.increment(1)});
      }
    }
    await batch.commit();
  }

  /// Real exit — removes membership doc + decrements counters.
  Future<void> leaveRoom(String roomId) async {
    final ref = _rooms.doc(roomId).collection('members').doc(_me);
    final existing = await ref.get();
    if (!existing.exists) return;
    final wasPresent = (existing.data()?['isPresent'] ?? false) as bool;
    final batch = _db.batch();
    batch.delete(ref);
    batch.update(_rooms.doc(roomId), {
      'memberCount': FieldValue.increment(-1),
      if (wasPresent) 'onlineCount': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  /// Flip "present in screen" without changing membership. Used by the
  /// floating bubble (back-press = setPresent(false), reopen = true).
  Future<void> setPresent(String roomId, bool present) async {
    final ref = _rooms.doc(roomId).collection('members').doc(_me);
    final existing = await ref.get();
    if (!existing.exists) return;
    final was = (existing.data()?['isPresent'] ?? false) as bool;
    if (was == present) return;
    final batch = _db.batch();
    batch.update(ref, {
      'isPresent': present,
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
    batch.update(_rooms.doc(roomId),
        {'onlineCount': FieldValue.increment(present ? 1 : -1)});
    await batch.commit();
  }

  Stream<List<RoomMember>> watchMembers(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('members')
        .snapshots()
        .map((s) => s.docs
            .map((d) => RoomMember.fromMap(d.id, d.data()))
            .toList());
  }

  Stream<RoomMember?> watchMyMembership(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('members')
        .doc(_me)
        .snapshots()
        .map((d) => d.exists ? RoomMember.fromMap(d.id, d.data()!) : null);
  }

  // ---------------------------------------------------------------------------
  // MESSAGES — both legacy (Map) and typed (RoomMessage) APIs available.
  // ---------------------------------------------------------------------------

  /// Legacy raw stream — kept so existing room_screen.dart still compiles.
  Stream<List<Map<String, dynamic>>> watchMessages(String roomId,
      {int limit = 100}) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) {
      return s.docs
          .map((d) => {...d.data(), 'id': d.id})
          .where((m) => !((m['hiddenFor'] as List?) ?? const [])
              .map((e) => e.toString())
              .contains(_me))
          .toList();
    });
  }

  /// Typed stream — used by Slice 3 onwards.
  Stream<List<RoomMessage>> watchMessagesTyped(String roomId,
      {int limit = 100}) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => RoomMessage.fromMap(d.id, d.data()))
            .where((m) => !m.isHiddenFor(_me))
            .toList());
  }

  /// Legacy wrapper — old call sites pass senderId explicitly.
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) =>
      sendTextMessage(roomId, text);

  Future<void> sendTextMessage(String roomId, String text) async {
    if (text.trim().isEmpty) return;
    final me = await _db.collection('users').doc(_me).get();
    final m = me.data() ?? {};
    await _rooms.doc(roomId).collection('messages').add({
      'type': 'text',
      'text': text.trim(),
      'senderId': _me,
      'senderName': m['displayName'] ?? 'User',
      'senderPhoto': m['photoURL'],
      'senderCharms': m['charms'] ?? 0,
      'hiddenFor': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Append my uid to a message's hiddenFor — invisible only to me.
  Future<void> hideMessageForMe(String roomId, String messageId) {
    return _rooms.doc(roomId).collection('messages').doc(messageId).update({
      'hiddenFor': FieldValue.arrayUnion([_me]),
    });
  }

  /// Owner / admin / co-owner — actually deletes the message doc.
  Future<void> deleteMessageForAll(String roomId, String messageId) {
    return _rooms.doc(roomId).collection('messages').doc(messageId).delete();
  }

  Future<void> postSystemMessage(String roomId, String text) async {
    await _rooms.doc(roomId).collection('messages').add({
      'type': 'system',
      'text': text,
      'senderId': 'system',
      'senderName': 'System',
      'senderPhoto': null,
      'senderCharms': 0,
      'hiddenFor': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
