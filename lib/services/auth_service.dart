import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _users = UserService();

  Future<UserCredential> signUpWithEmail(
      String email, String password, String displayName) async {
    final cred =
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(displayName);
    if (cred.user != null) {
      await _users.ensureUserDoc(cred.user!, displayName: displayName);
    }
    return cred;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final cred =
        await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) await _users.ensureUserDoc(cred.user!);
    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    if (cred.user != null) await _users.ensureUserDoc(cred.user!);
    return cred;
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
