import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

class RoomService {
  final _db = FirebaseFirestore.instance;

  Future<String> createRoom(Room r) async {
    final ref = await _db.collection('rooms').add(r.toMap());
    return ref.id;
  }

  Stream<List<Room>> watchRooms() {
    return _db.collection('rooms').snapshots().map((qs) {
      final list = qs.docs.map((d) => Room.fromDoc(d)).toList();
      list.sort((a, b) {
        final ta = a.createdAt;
        final tb = b.createdAt;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    await _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((qs) => qs.docs.map((d) {
              final m = d.data();
              m['id'] = d.id;
              return m;
            }).toList());
  }
}
