import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<String> tags;
  final String emoji;
  final String creatorId;
  final int onlineCount;
  final Timestamp? createdAt;

  Room({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.tags,
    required this.emoji,
    required this.creatorId,
    required this.onlineCount,
    this.createdAt,
  });

  factory Room.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Room(
      id: d.id,
      name: m['name'] ?? '',
      description: m['description'] ?? '',
      category: m['category'] ?? 'All',
      tags: List<String>.from(m['tags'] ?? const []),
      emoji: m['emoji'] ?? '💬',
      creatorId: m['creatorId'] ?? '',
      onlineCount: (m['onlineCount'] as num?)?.toInt() ?? 1,
      createdAt: m['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'tags': tags,
        'emoji': emoji,
        'creatorId': creatorId,
        'onlineCount': onlineCount,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
