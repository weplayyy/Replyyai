import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final Timestamp? createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Message(
      id: d.id,
      senderId: m['senderId'] ?? '',
      text: m['text'] ?? '',
      createdAt: m['createdAt'],
    );
  }
}
