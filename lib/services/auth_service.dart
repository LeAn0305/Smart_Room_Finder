import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng nhập email/password
  static Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Đăng ký email/password
  static Future<UserCredential> registerWithEmail(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(name);
    await _saveUserToFirestore(cred.user!, name: name);
    return cred;
  }

  // Đăng nhập Google
  static Future<UserCredential?> signInWithGoogle() async {
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    await _saveUserToFirestore(cred.user!);
    return cred;
  }

  // Lưu user vào Firestore
  static Future<void> _saveUserToFirestore(User user, {String? name}) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set({
        'uid': user.uid,
        'name': name ?? user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.update({'lastLogin': FieldValue.serverTimestamp()});
    }
  }

  // Đăng xuất
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Quên mật khẩu
  static Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
