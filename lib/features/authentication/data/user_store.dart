import 'dart:convert';

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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Buyer',
    );
  }
}

class UserStore {
  static const String _usersKey = 'agroconnect_users';

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
  // LOAD USERS
  // --------------------------------------------------

  static Future<void> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUsers = prefs.getStringList(_usersKey);

    // Always keep the hard-coded admin.
    users.removeWhere(
      (user) => user.role != 'Admin',
    );

    if (savedUsers == null || savedUsers.isEmpty) {
      return;
    }

    for (final savedUser in savedUsers) {
      try {
        final decoded = jsonDecode(savedUser);

        if (decoded is Map<String, dynamic>) {
          final user = User.fromJson(decoded);

          // Prevent duplicate users.
          final alreadyExists = users.any(
            (existingUser) =>
                existingUser.email.toLowerCase() ==
                user.email.toLowerCase(),
          );

          if (!alreadyExists) {
            users.add(user);
          }
        }
      } catch (_) {
        // Ignore corrupted user records.
      }
    }
  }

  // --------------------------------------------------
  // ADD USER
  // --------------------------------------------------

  static Future<bool> addUser(User user) async {
    // Prevent duplicate email addresses.
    if (emailExists(user.email)) {
      return false;
    }

    users.add(user);

    final prefs = await SharedPreferences.getInstance();

    final savedUsers = users
        .where(
          (user) => user.role != 'Admin',
        )
        .map(
          (user) => jsonEncode(user.toJson()),
        )
        .toList();

    final saved = await prefs.setStringList(
      _usersKey,
      savedUsers,
    );

    return saved;
  }

  // --------------------------------------------------
  // FIND USER
  // --------------------------------------------------

  static User? findUser(
    String email,
    String password,
  ) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    for (final user in users) {
      if (user.email.trim().toLowerCase() ==
              cleanEmail &&
          user.password.trim() == cleanPassword) {
        return user;
      }
    }

    return null;
  }

  // --------------------------------------------------
  // CHECK EMAIL
  // --------------------------------------------------

  static bool emailExists(String email) {
    final cleanEmail = email.trim().toLowerCase();

    return users.any(
      (user) =>
          user.email.trim().toLowerCase() ==
          cleanEmail,
    );
  }

  // --------------------------------------------------
  // DEBUG INFORMATION
  // --------------------------------------------------

  static Future<List<String>> getSavedUsers() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getStringList(_usersKey) ?? [];
  }
}