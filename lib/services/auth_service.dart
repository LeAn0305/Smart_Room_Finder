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
  // ROLE HELPERS
  // =========================
  static String? _roleToValue(UserRole? role) => role?.value;

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
  // ADMIN LOGIN
  // =========================
  static Future<UserModel> signInAdminWithEmail({
    required String email,
    required String password,
    required String secretCode,
  }) async {
    final cred = await signInWithEmail(email, password);
    final user = cred.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Không tìm thấy tài khoản admin hiện tại',
      );
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();

    if (!doc.exists || data == null) {
      await signOut();
      throw FirebaseAuthException(
        code: 'user-data-not-found',
        message: 'Không tìm thấy dữ liệu người dùng trong Firestore',
      );
    }

    final userModel = UserModel.fromFirebase(data, doc.id);
    final storedSecret = (data['adminSecretCode'] ?? '').toString().trim();

    if (!userModel.isAdmin) {
      await signOut();
      throw FirebaseAuthException(
        code: 'not-admin',
        message: 'Tài khoản này không có quyền quản trị',
      );
    }

    if (storedSecret.isEmpty) {
      await signOut();
      throw FirebaseAuthException(
        code: 'admin-secret-not-set',
        message: 'Tài khoản admin chưa được cấu hình mã bí mật',
      );
    }

    if (storedSecret != secretCode.trim()) {
      await signOut();
      throw FirebaseAuthException(
        code: 'invalid-admin-secret',
        message: 'Mã bí mật admin không chính xác',
      );
    }

    return userModel;
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
  // PHONE LOGIN - SEND OTP
  // =========================
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        codeAutoRetrievalTimeout(verificationId);
      },
    );
  }

  // =========================
  // PHONE LOGIN - VERIFY OTP
  // =========================
  static Future<UserCredential> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
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
    UserRole? overrideRole,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    final now = DateTime.now().toIso8601String();
    final resolvedRole = _roleToValue(overrideRole);

    if (!snapshot.exists) {
      await docRef.set({
        'name': overrideName ??
            (user.displayName != null && user.displayName!.trim().isNotEmpty
                ? user.displayName!.trim()
                : 'Unknown User'),
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'profileImageUrl': user.photoURL ?? '',
        'location': 'TP. Hồ Chí Minh',

        // 🔥 User mới chưa chọn vai trò
        // Sau khi đăng nhập / đăng ký xong sẽ chuyển sang màn chọn vai trò
        'role': resolvedRole,
        'hasSelectedRole': resolvedRole != null,

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
      'phoneNumber': (user.phoneNumber != null &&
              user.phoneNumber!.trim().isNotEmpty)
          ? user.phoneNumber!.trim()
          : (oldData['phoneNumber'] ?? ''),
      'profileImageUrl':
          (user.photoURL != null && user.photoURL!.trim().isNotEmpty)
              ? user.photoURL!.trim()
              : (oldData['profileImageUrl'] ?? ''),
      'location': oldData['location'] ?? 'TP. Hồ Chí Minh',

      // 🔥 Giữ role cũ nếu đã có trong Firestore
      // Nếu có truyền overrideRole thì cập nhật theo overrideRole
      // Nếu user cũ chưa có role thì giữ null để chuyển sang màn chọn vai trò
      'role': resolvedRole ?? oldData['role'],

      // 🔥 Giữ trạng thái đã chọn vai trò nếu đã có
      // Nếu user cũ chưa có field này thì mặc định là false
      'hasSelectedRole': resolvedRole != null ? true : (oldData['hasSelectedRole'] ?? (oldData['role'] != null)),


      'updatedAt': now,
    });
  }

  // =========================
  // USER ROLE
  // =========================
  static Future<void> updateUserRole(UserRole role) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Không tìm thấy người dùng hiện tại',
      );
    }

    await _firestore.collection('users').doc(user.uid).set({
      'role': _roleToValue(role),
      'hasSelectedRole': true,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

  }

  static Future<UserRole?> getCurrentUserRole() async {
    final userData = await getCurrentUserData();
    return userData?.role;
  }

  static Future<bool> isCurrentUserAdmin() async {
    return (await getCurrentUserRole()) == UserRole.admin;
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
