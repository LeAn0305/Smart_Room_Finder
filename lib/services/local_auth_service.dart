// Local auth service - demo only, không dùng trong production
class LocalAuthService {
  static final Map<String, String> _users = {}; // email -> password
  static String? _currentUserEmail;

  static String? get currentUserEmail => _currentUserEmail;

  static bool register(String email, String password) {
    if (_users.containsKey(email)) return false; // đã tồn tại
    _users[email] = password;
    return true;
  }

  static bool login(String email, String password) {
    return _users[email] == password;
  }

  static void logout() {
    _currentUserEmail = null;
  }

  static void setCurrentUser(String email) {
    _currentUserEmail = email;
  }
}
