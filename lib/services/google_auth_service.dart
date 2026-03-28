import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Đăng nhập bằng Google
  /// Trả về [GoogleSignInAccount] nếu thành công, null nếu người dùng huỷ
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      // Đảm bảo đăng xuất phiên cũ trước (để luôn hiện dialog chọn tài khoản)
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy thông tin authentication (token)
  static Future<GoogleSignInAuthentication?> getAuth(
      GoogleSignInAccount account) async {
    return await account.authentication;
  }

  /// Đăng xuất
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Kiểm tra đã đăng nhập chưa
  static Future<GoogleSignInAccount?> signInSilently() async {
    return await _googleSignIn.signInSilently();
  }
}
