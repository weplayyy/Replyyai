import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final int charms;
  final int level;
  final int coins;
  final Timestamp? createdAt;

  AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.charms = 0,
    this.level = 1,
    this.coins = 100,
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        uid: m['uid'] ?? '',
        displayName: m['displayName'] ?? 'User',
        email: m['email'] ?? '',
        photoURL: m['photoURL'],
        charms: (m['charms'] ?? 0) as int,
        level: (m['level'] ?? 1) as int,
        coins: (m['coins'] ?? 0) as int,
        createdAt: m['createdAt'],
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoURL': photoURL,
        'charms': charms,
        'level': level,
        'coins': coins,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };
}
