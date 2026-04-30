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
  // MODERATION — kick / mute / promote / demote.
  // Charm rule is enforced at the call site (see ManageMemberSheet); these
  // methods just do the writes. Firestore Security Rules also enforce
  // the rule server-side.
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

  // ---------------------------------------------------------------------------
  // OWNER LIFECYCLE — leave / return / freeze / auto-delete countdown
  // ---------------------------------------------------------------------------

  /// Owner taps "Exit" on a room.
  ///
  /// - Temporary room → 3-min countdown then auto-delete.
  /// - Advanced room with other moderators present → owner just leaves,
  ///   room stays live (admins keep it going).
  /// - Advanced room with no other moderators → status flips to `frozen`
  ///   (no one can chat) until any moderator returns. Never deletes.
  ///
  /// Returns true if the room is still chattable, false if it was put into
  /// pending_delete or frozen state.
    Future<bool> ownerLeaveRoom(String roomId) async {
    final roomSnap = await _rooms.doc(roomId).get();
    if (!roomSnap.exists) return false;
    final room = Room.fromMap(roomSnap.id, roomSnap.data()!);

    final modsSnap = await _rooms
        .doc(roomId)
        .collection('members')
        .where('role', whereIn: ['co_owner', 'admin']).get();
    final hasOtherMods = modsSnap.docs.any((d) => d.id != _me);

    if (room.isAdvanced && hasOtherMods) {
      // Advanced room with mods present → owner just leaves; room continues.
      // Post system message FIRST (while still a member of a live room).
      await postSystemMessage(roomId,
          '👑 Owner stepped out — admins are keeping the room alive');
      await leaveRoom(roomId);
      return true;
    }

    if (room.isAdvanced) {
      // Post system message FIRST (room still 'live'), then freeze.
      await postSystemMessage(roomId,
          '❄️ Room frozen — chat locked until owner / admin / co-owner returns');
      final batch = _db.batch();
      batch.update(_rooms.doc(roomId), {
        'status': 'frozen',
        'frozenAt': FieldValue.serverTimestamp(),
        'ownerLeftAt': FieldValue.serverTimestamp(),
      });
      batch.update(_rooms.doc(roomId).collection('members').doc(_me), {
        'isPresent': false,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return false;
    }

    // Temporary room → post message FIRST, then start the 3-min countdown.
    await postSystemMessage(roomId,
        '👑 Owner has exited — room will be deleted in 3 min unless they return');
    final now = DateTime.now();
    final deleteAt = now.add(const Duration(minutes: 3));
    final batch = _db.batch();
    batch.update(_rooms.doc(roomId), {
      'status': 'pending_delete',
      'ownerLeftAt': Timestamp.fromDate(now),
      'deleteAt': Timestamp.fromDate(deleteAt),
    });
    batch.update(_rooms.doc(roomId).collection('members').doc(_me), {
      'isPresent': false,
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return false;
    }

  /// Called when any moderator (owner / co-owner / admin) opens a room that's
  /// in pending_delete or frozen state. Cancels the countdown / unfreezes.
  ///
  /// - For `pending_delete`: only the owner can rescue (they triggered it).
  /// - For `frozen`: any mod can unfreeze.
  Future<void> modReturnRoom(String roomId) async {
    final snap = await _rooms.doc(roomId).get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final status = data['status'] as String?;
    if (status != 'pending_delete' && status != 'frozen') return;

    final memSnap =
        await _rooms.doc(roomId).collection('members').doc(_me).get();
    if (!memSnap.exists) return;
    final myRole = memSnap.data()?['role'] as String?;
    final isMod =
        myRole == 'owner' || myRole == 'co_owner' || myRole == 'admin';
    if (!isMod) return;

    if (status == 'pending_delete' && myRole != 'owner') return;

    await _rooms.doc(roomId).update({
      'status': 'live',
      'ownerLeftAt': FieldValue.delete(),
      'deleteAt': FieldValue.delete(),
      'frozenAt': FieldValue.delete(),
    });

    final msg = status == 'frozen'
        ? '🔓 Room unfrozen — chat is back'
        : '👑 Owner is back — room saved';
    await postSystemMessage(roomId, msg);
  }

  /// Soft-delete the room if its `deleteAt` has passed. Idempotent.
  /// Any client can call this — first one wins. Used by the countdown
  /// banner when the timer hits zero.
  Future<bool> autoDeleteIfExpired(String roomId) async {
    final snap = await _rooms.doc(roomId).get();
    if (!snap.exists) return false;
    final data = snap.data()!;
    if (data['status'] != 'pending_delete') return false;
    final deleteAt = data['deleteAt'];
    if (deleteAt is! Timestamp) return false;
    if (deleteAt.toDate().isAfter(DateTime.now())) return false;

    await _rooms.doc(roomId).update({
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
    });
    return true;
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

    // Mute check — block sending if mutedUntil is in the future.
    final myMemberDoc = await _rooms
        .doc(roomId)
        .collection('members')
        .doc(_me)
        .get();
    final mutedUntilTs = myMemberDoc.data()?['mutedUntil'];
    if (mutedUntilTs is Timestamp &&
        mutedUntilTs.toDate().isAfter(DateTime.now())) {
      throw Exception('You are muted in this room');
    }

    // Frozen / pending_delete / deleted check — block all chat.
    final roomDoc = await _rooms.doc(roomId).get();
    final status = roomDoc.data()?['status'] as String?;
    if (status == 'frozen') {
      throw Exception('Room is frozen — chat is locked');
    }
    if (status == 'pending_delete') {
      throw Exception('Room is closing');
    }
    if (status == 'deleted') {
      throw Exception('Room no longer exists');
    }

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
      'senderPhoto': 'null',
      'senderCharms': 0,
      'hiddenFor': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
