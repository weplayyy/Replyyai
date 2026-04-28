import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final String type;
  final String? giftId;
  final String? giftName;
  final String? giftIcon;
  final int? giftPrice;
  final int? luckyCoins;
  final Timestamp? createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.type = 'text',
    this.giftId,
    this.giftName,
    this.giftIcon,
    this.giftPrice,
    this.luckyCoins,
    this.createdAt,
  });

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Message(
      id: d.id,
      senderId: m['senderId'] ?? '',
      text: m['text'] ?? '',
      type: m['type'] ?? 'text',
      giftId: m['giftId'],
      giftName: m['giftName'],
      giftIcon: m['giftIcon'],
      giftPrice: m['giftPrice'],
      luckyCoins: m['luckyCoins'],
      createdAt: m['createdAt'],
    );
  }
}
