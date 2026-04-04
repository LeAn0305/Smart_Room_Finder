import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:smart_room_finder/core/config/google_oauth_config.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static final _googleSignIn = GoogleSignIn(
    params: const GoogleSignInParams(
      clientId: GoogleOAuthConfig.windowsClientId,
      clientSecret: GoogleOAuthConfig.windowsClientSecret,
      scopes: ['openid', 'profile', 'email'],
    ),
  );

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng nhập email/password
  static Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Đăng ký email/password
  static Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user?.updateDisplayName(name);
    await _saveUserToFirestore(cred.user!, name: name);
    return cred;
  }

  // Đăng nhập Google
  static Future<UserCredential?> signInWithGoogle() async {
    final credentials = await _googleSignIn.signInOnline();
    if (credentials == null) return null;

    final credential = GoogleAuthProvider.credential(
      idToken: credentials.idToken,
      accessToken: credentials.accessToken,
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
      await doc.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // Đăng xuất
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _auth.signOut();
  }

  // Quên mật khẩu
  static Future<void> sendPasswordReset(String email) async {
    await _auth.setLanguageCode('en');
    await _auth.sendPasswordResetEmail(email: email);
  }
}