import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_role.dart';

class RoomMember {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final int charms;
  final RoomRole role;
  final DateTime joinedAt;
  final bool isPresent;
  final DateTime? lastActiveAt;
  final DateTime? mutedUntil;

  RoomMember({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.charms,
    required this.role,
    required this.joinedAt,
    this.isPresent = false,
    this.lastActiveAt,
    this.mutedUntil,
  });

  bool get isMuted =>
      mutedUntil != null && mutedUntil!.isAfter(DateTime.now());

  factory RoomMember.fromMap(String uid, Map<String, dynamic> m) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return RoomMember(
      uid: uid,
      displayName: (m['displayName'] ?? 'User') as String,
      photoUrl: m['photoUrl'] as String?,
      charms: (m['charms'] ?? 0) as int,
      role: RoomRoleX.fromRaw(m['role'] as String?),
      joinedAt: ts(m['joinedAt']) ?? DateTime.now(),
      isPresent: (m['isPresent'] ?? false) as bool,
      lastActiveAt: ts(m['lastActiveAt']),
      mutedUntil: ts(m['mutedUntil']),
    );
  }
}
