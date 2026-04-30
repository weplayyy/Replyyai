import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomType { temporary, advanced }
enum RoomStatus { live, pendingDelete, deleted }

extension RoomTypeX on RoomType {
  String toRaw() => this == RoomType.advanced ? 'advanced' : 'temporary';
  static RoomType fromRaw(String? r) =>
      r == 'advanced' ? RoomType.advanced : RoomType.temporary;
}

extension RoomStatusX on RoomStatus {
  String toRaw() => switch (this) {
        RoomStatus.live => 'live',
        RoomStatus.pendingDelete => 'pending_delete',
        RoomStatus.deleted => 'deleted',
      };
  static RoomStatus fromRaw(String? r) => switch (r) {
        'pending_delete' => RoomStatus.pendingDelete,
        'deleted' => RoomStatus.deleted,
        _ => RoomStatus.live,
      };
}

class Room {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> tags;
  final String emoji;

  /// Asset path to the bundled preset PFP. e.g. 'assets/rooms/late_night_1.png'
  final String? photoUrl;

  // Owner info — denormalized so we don't fetch the user doc on every render.
  final String ownerId;
  final String ownerName;
  final String? ownerPhoto;
  final int ownerCharms;

  final RoomType type;
  final int level; // advanced only
  final int xp;    // advanced only

  final RoomStatus status;
  final DateTime? ownerLeftAt;
  final DateTime? deleteAt;

  final int memberCount;
  final int onlineCount;

  final DateTime? createdAt;

  Room({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.tags = const [],
    this.emoji = '🌙',
    this.photoUrl,
    required this.ownerId,
    this.ownerName = 'Owner',
    this.ownerPhoto,
    this.ownerCharms = 0,
    this.type = RoomType.temporary,
    this.level = 1,
    this.xp = 0,
    this.status = RoomStatus.live,
    this.ownerLeftAt,
    this.deleteAt,
    this.memberCount = 1,
    this.onlineCount = 1,
    this.createdAt,
  });

  /// Backwards-compat — legacy code reads r.creatorId.
  String get creatorId => ownerId;

  bool get isAdvanced => type == RoomType.advanced;
  bool get isPendingDelete => status == RoomStatus.pendingDelete;

  factory Room.fromMap(String id, Map<String, dynamic> m) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Room(
      id: id,
      name: (m['name'] ?? 'Room') as String,
      description: (m['description'] ?? '') as String,
      category: (m['category'] ?? 'All') as String,
      tags: ((m['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      emoji: (m['emoji'] ?? '🌙') as String,
      photoUrl: m['photoUrl'] as String?,
      ownerId: (m['ownerId'] ?? m['creatorId'] ?? '') as String,
      ownerName: (m['ownerName'] ?? 'Owner') as String,
      ownerPhoto: m['ownerPhoto'] as String?,
      ownerCharms: (m['ownerCharms'] ?? 0) as int,
      type: RoomTypeX.fromRaw(m['type'] as String?),
      level: (m['level'] ?? 1) as int,
      xp: (m['xp'] ?? 0) as int,
      status: RoomStatusX.fromRaw(m['status'] as String?),
      ownerLeftAt: ts(m['ownerLeftAt']),
      deleteAt: ts(m['deleteAt']),
      memberCount: (m['memberCount'] ?? 1) as int,
      onlineCount: (m['onlineCount'] ?? 1) as int,
      createdAt: ts(m['createdAt']),
    );
  }

  /// Used on createRoom — writes legacy creatorId too so older queries
  /// still work during migration.
  Map<String, dynamic> toCreateMap() => {
        'name': name,
        'description': description,
        'category': category,
        'tags': tags,
        'emoji': emoji,
        'photoUrl': photoUrl,
        'ownerId': ownerId,
        'creatorId': ownerId,
        'ownerName': ownerName,
        'ownerPhoto': ownerPhoto,
        'ownerCharms': ownerCharms,
        'type': type.toRaw(),
        'level': level,
        'xp': xp,
        'status': status.toRaw(),
        'memberCount': memberCount,
        'onlineCount': onlineCount,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
