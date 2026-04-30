import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Future<void> ensureUserDoc(User user, {String? displayName}) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final name = displayName ?? user.displayName ?? 'User';
      final username = (user.email ?? user.uid)
          .split('@')
          .first
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
      await ref.set({
        'uid': user.uid,
        'displayName': name,
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'username': username,
        'bio': 'Talk more, Worry less.',
        'charms': 0,
        'level': 1,
        'coins': 100,
        'friendsCount': 0,
        'momentsCount': 0,
        'visitorsCount': 0,
        'followingCount': 0,
        'isOnline': true,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<AppUser> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((s) => AppUser.fromMap(s.data() ?? {'uid': uid}));
  }

  Stream<List<AppUser>> watchAllUsersExcept(String uid) {
    return _users.snapshots().map((qs) => qs.docs
        .map((d) => AppUser.fromMap(d.data()))
        .where((u) => u.uid != uid)
        .toList());
  }

  /// One-shot fetch of a user by uid. Returns null if no doc exists.
  Future<AppUser?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromMap(snap.data()!, uid);
  }
}
