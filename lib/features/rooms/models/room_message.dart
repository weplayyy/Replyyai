import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomMessageType { text, gift, system, share }

extension RoomMessageTypeX on RoomMessageType {
  String toRaw() => switch (this) {
        RoomMessageType.text => 'text',
        RoomMessageType.gift => 'gift',
        RoomMessageType.system => 'system',
        RoomMessageType.share => 'share',
      };
  static RoomMessageType fromRaw(String? r) => switch (r) {
        'gift' => RoomMessageType.gift,
        'system' => RoomMessageType.system,
        'share' => RoomMessageType.share,
        _ => RoomMessageType.text,
      };
}

class RoomMessage {
  final String id;
  final RoomMessageType type;
  final String text;

  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final int senderCharms;
  final String? senderCpPartnerName;
  final String? senderCpStatus;

  final String? giftId;
  final String? giftName;
  final String? giftIcon;
  final int? giftPrice;

  final String? shareType;
  final Map<String, dynamic>? sharePayload;

  final List<String> hiddenFor;

  final DateTime createdAt;

  RoomMessage({
    required this.id,
    required this.type,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.senderPhoto,
    required this.senderCharms,
    this.senderCpPartnerName,
    this.senderCpStatus,
    this.giftId,
    this.giftName,
    this.giftIcon,
    this.giftPrice,
    this.shareType,
    this.sharePayload,
    this.hiddenFor = const [],
    required this.createdAt,
  });

  bool isHiddenFor(String uid) => hiddenFor.contains(uid);

  factory RoomMessage.fromMap(String id, Map<String, dynamic> m) {
    DateTime ts(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();
    return RoomMessage(
      id: id,
      type: RoomMessageTypeX.fromRaw(m['type'] as String?),
      text: (m['text'] ?? '') as String,
      senderId: (m['senderId'] ?? '') as String,
      senderName: (m['senderName'] ?? 'User') as String,
      senderPhoto: m['senderPhoto'] as String?,
      senderCharms: (m['senderCharms'] ?? 0) as int,
      senderCpPartnerName: m['senderCpPartnerName'] as String?,
      senderCpStatus: m['senderCpStatus'] as String?,
      giftId: m['giftId'] as String?,
      giftName: m['giftName'] as String?,
      giftIcon: m['giftIcon'] as String?,
      giftPrice: m['giftPrice'] as int?,
      shareType: m['shareType'] as String?,
      sharePayload: m['sharePayload'] as Map<String, dynamic>?,
      hiddenFor: ((m['hiddenFor'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: ts(m['createdAt']),
    );
  }
}
