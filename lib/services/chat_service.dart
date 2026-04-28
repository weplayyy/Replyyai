import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  String chatIdFor(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> sendMessage({
    required String fromUid,
    required String toUid,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    final id = chatIdFor(fromUid, toUid);
    final chatRef = _db.collection('chats').doc(id);

    await chatRef.set({
      'participants': [fromUid, toUid],
      'lastMessage': text,
      'lastSenderId': fromUid,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': fromUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Message>> watchMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((qs) => qs.docs.map((d) => Message.fromDoc(d)).toList());
  }

  Stream<List<Map<String, dynamic>>> watchMyChats(String myUid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((qs) => qs.docs.map((d) {
              final m = d.data();
              m['id'] = d.id;
              return m;
            }).toList());
  }
}
