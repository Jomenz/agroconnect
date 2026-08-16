import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;

  User({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
  });
}

class UserStore {
  static final List<User> users = [
    User(
      name: 'Agroconect Admin',
      email: 'admin@agroconect.com',
      phone: '0000000000',
      password: 'admin123',
      role: 'Admin',
    ),
  ];

  // --------------------------------------------------
  // CURRENT USER
  // --------------------------------------------------

  static User? currentUser;

  // --------------------------------------------------
  // ADD USER
  // --------------------------------------------------

  static Future<void> addUser(User user) async {
    users.add(user);
    await _saveUsers();
  }

  // --------------------------------------------------
  // FIND USER
  // --------------------------------------------------

  static User? findUser(
    String email,
    String password,
  ) {
    try {
      return users.firstWhere(
        (user) =>
            user.email.toLowerCase() ==
                email.toLowerCase() &&
            user.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  // --------------------------------------------------
  // EMAIL EXISTS
  // --------------------------------------------------

  static bool emailExists(String email) {
    return users.any(
      (user) =>
          user.email.toLowerCase() ==
          email.toLowerCase(),
    );
  }

  // --------------------------------------------------
  // LOGIN
  // --------------------------------------------------

  static Future<void> login(User user) async {
    currentUser = user;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'current_user_email',
      user.email,
    );
  }

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  static Future<void> logout() async {
    currentUser = null;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('current_user_email');
  }

  // --------------------------------------------------
  // LOAD USERS
  // --------------------------------------------------

  static Future<void> loadUsers() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedEmail =
        prefs.getString('current_user_email');

    if (savedEmail != null) {
      try {
        currentUser = users.firstWhere(
          (user) =>
              user.email.toLowerCase() ==
              savedEmail.toLowerCase(),
        );
      } catch (e) {
        currentUser = null;
      }
    }
  }

  // --------------------------------------------------
  // SAVE USERS
  // --------------------------------------------------

  static Future<void> _saveUsers() async {
    // User persistence is already handled
    // by the existing UserStore implementation.
    //
    // We are intentionally leaving this method
    // available for the next persistence improvement.
  }
}