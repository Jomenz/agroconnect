import 'auth_service.dart';

export 'auth_service.dart';

class User {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;

  User({
    this.uid = '',
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    String? password,
  });

  factory User.fromModel(UserModel model) {
    return User(
      uid: model.uid,
      name: model.name,
      email: model.email,
      phone: model.phone,
      role: model.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Buyer',
    );
  }
}

class UserStore {
  UserStore._();

  static UserModel? get currentUser => AuthService.instance.currentUser;

  static Future<UserModel?> loadCurrentUser() async {
    return AuthService.instance.loadCurrentUserProfile();
  }
}