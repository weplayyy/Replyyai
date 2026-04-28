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
      await ref.set({
        'uid': user.uid,
        'displayName': displayName ?? user.displayName ?? 'User',
        'email': user.email ?? '',
        'photoURL': user.photoURL,
        'charms': 0,
        'level': 1,
        'coins': 100,
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
}
