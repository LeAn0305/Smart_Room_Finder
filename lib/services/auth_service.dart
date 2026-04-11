import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:smart_room_finder/core/config/google_oauth_config.dart';
import 'package:smart_room_finder/models/user_model.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    params: const GoogleSignInParams(
      clientId: GoogleOAuthConfig.windowsClientId,
      clientSecret: GoogleOAuthConfig.windowsClientSecret,
      scopes: ['openid', 'profile', 'email'],
    ),
  );

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // =========================
  // EMAIL LOGIN
  // =========================
  static Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user != null) {
      await _syncUserToFirestore(cred.user!);
    }

    return cred;
  }

  // =========================
  // REGISTER
  // =========================
  static Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user != null) {
      await cred.user!.updateDisplayName(name);
      await cred.user!.reload();

      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null) {
        await _syncUserToFirestore(
          refreshedUser,
          overrideName: name,
        );
      }
    }

    return cred;
  }

  // =========================
  // GOOGLE LOGIN
  // =========================
  static Future<UserCredential?> signInWithGoogle() async {
    final credentials = await _googleSignIn.signInOnline();
    if (credentials == null) return null;

    final credential = GoogleAuthProvider.credential(
      idToken: credentials.idToken,
      accessToken: credentials.accessToken,
    );

    final cred = await _auth.signInWithCredential(credential);

    if (cred.user != null) {
      await _syncUserToFirestore(cred.user!);
    }

    return cred;
  }

  // =========================
  // SYNC USER TO FIRESTORE
  // =========================
  static Future<void> _syncUserToFirestore(
    User user, {
    String? overrideName,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    final now = DateTime.now().toIso8601String();

    if (!snapshot.exists) {
      await docRef.set({
        'name': overrideName ?? user.displayName ?? 'Unknown User',
        'email': user.email ?? '',
        'profileImageUrl': user.photoURL ?? '',
        'location': 'TP. Hồ Chí Minh',
        'createdAt': now,
        'updatedAt': now,
      });
      return;
    }

    final oldData = snapshot.data() ?? {};

    await docRef.update({
      'name': (overrideName != null && overrideName.trim().isNotEmpty)
          ? overrideName.trim()
          : ((user.displayName != null && user.displayName!.trim().isNotEmpty)
              ? user.displayName!.trim()
              : (oldData['name'] ?? 'Unknown User')),
      'email': (user.email != null && user.email!.trim().isNotEmpty)
          ? user.email!.trim()
          : (oldData['email'] ?? ''),
      'profileImageUrl':
          (user.photoURL != null && user.photoURL!.trim().isNotEmpty)
              ? user.photoURL!.trim()
              : (oldData['profileImageUrl'] ?? ''),
      'location': oldData['location'] ?? 'TP. Hồ Chí Minh',
      'updatedAt': now,
    });
  }

  // =========================
  // GET CURRENT USER DATA
  // =========================
  static Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists || doc.data() == null) return null;

    return UserModel.fromFirebase(doc.data()!, doc.id);
  }

  // =========================
  // UPDATE PROFILE
  // =========================
  static Future<void> updateUserProfile({
    required String name,
    String? profileImageUrl,
    String? location,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Không tìm thấy người dùng hiện tại',
      );
    }

    final updateData = <String, dynamic>{
      'name': name.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (profileImageUrl != null) {
      updateData['profileImageUrl'] = profileImageUrl;
    }

    if (location != null) {
      updateData['location'] = location;
    }

    await _firestore.collection('users').doc(user.uid).update(updateData);

    await user.updateDisplayName(name.trim());

    if (profileImageUrl != null && profileImageUrl.trim().isNotEmpty) {
      await user.updatePhotoURL(profileImageUrl.trim());
    }

    await user.reload();
  }

  // =========================
  // SIGN OUT
  // =========================
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _auth.signOut();
  }

  // =========================
  // FORGOT PASSWORD
  // =========================
  static Future<void> sendPasswordReset(String email) async {
    await _auth.setLanguageCode('en');
    await _auth.sendPasswordResetEmail(email: email);
  }

  // =========================
  // CHECK IF USER SIGNED IN WITH EMAIL
  // =========================
  static bool isPasswordProvider() {
  final user = _auth.currentUser;
  if (user == null) return false;

  return user.providerData.any((info) => info.providerId == 'password');
  }

  // =========================
  // CHANGE PASSWORD
  // =========================
  static Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  final user = _auth.currentUser;

  if (user == null) {
    throw FirebaseAuthException(
      code: 'no-current-user',
      message: 'Không tìm thấy người dùng hiện tại',
    );
  }

  if (user.email == null || user.email!.trim().isEmpty) {
    throw FirebaseAuthException(
      code: 'no-email',
      message: 'Tài khoản hiện tại không có email',
    );
  }

  final credential = EmailAuthProvider.credential(
    email: user.email!.trim(),
    password: currentPassword,
  );

  debugPrint('==> Reauthenticate bắt đầu');
  await user.reauthenticateWithCredential(credential);

  debugPrint('==> Reauthenticate xong, bắt đầu updatePassword');
  await user.updatePassword(newPassword);

  debugPrint('==> updatePassword xong, reload');
  await user.reload();
  }
}