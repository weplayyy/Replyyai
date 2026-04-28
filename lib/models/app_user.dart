import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String username;
  final String bio;
  final int charms;
  final int level;
  final int coins;
  final int friendsCount;
  final int momentsCount;
  final int visitorsCount;
  final int followingCount;
  final bool isOnline;
  final bool isVerified;
  final Timestamp? createdAt;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.username = '',
    this.bio = 'Talk more, Worry less.',
    this.charms = 0,
    this.level = 1,
    this.coins = 100,
    this.friendsCount = 0,
    this.momentsCount = 0,
    this.visitorsCount = 0,
    this.followingCount = 0,
    this.isOnline = true,
    this.isVerified = false,
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        uid: m['uid'] ?? '',
        displayName: m['displayName'] ?? 'User',
        email: m['email'] ?? '',
        photoURL: m['photoURL'],
        username: m['username'] ?? '',
        bio: m['bio'] ?? 'Talk more, Worry less.',
        charms: (m['charms'] ?? 0) as int,
        level: (m['level'] ?? 1) as int,
        coins: (m['coins'] ?? 0) as int,
        friendsCount: (m['friendsCount'] ?? 0) as int,
        momentsCount: (m['momentsCount'] ?? 0) as int,
        visitorsCount: (m['visitorsCount'] ?? 0) as int,
        followingCount: (m['followingCount'] ?? 0) as int,
        isOnline: m['isOnline'] ?? true,
        isVerified: m['isVerified'] ?? false,
        createdAt: m['createdAt'],
      );
}
