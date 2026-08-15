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

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    };
  }

  // Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
      role: json['role'],
    );
  }
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

  // Load saved users from the phone
  static Future<void> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUsers = prefs.getStringList('users');

    if (savedUsers == null) {
      return;
    }

    // Keep admin account and add saved Buyer/Farmer accounts
    users.removeWhere((user) => user.role != 'Admin');

    for (final userJson in savedUsers) {
      final user = User.fromJson(
        jsonDecode(userJson),
      );

      users.add(user);
    }
  }

  // Add a new user and save it
  static Future<void> addUser(User user) async {
    users.add(user);

    final prefs = await SharedPreferences.getInstance();

    final nonAdminUsers = users
        .where((user) => user.role != 'Admin')
        .map(
          (user) => jsonEncode(user.toJson()),
        )
        .toList();

    await prefs.setStringList(
      'users',
      nonAdminUsers,
    );
  }

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

  static bool emailExists(String email) {
    return users.any(
      (user) =>
          user.email.toLowerCase() ==
          email.toLowerCase(),
    );
  }
}