import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'Buyer', 'Farmer', 'Admin'
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    DateTime? date;
    final createdAtRaw = map['createdAt'];
    if (createdAtRaw is Timestamp) {
      date = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      date = DateTime.tryParse(createdAtRaw);
    }

    return UserModel(
      uid: uid,
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: map['role']?.toString() ?? 'Buyer',
      createdAt: date,
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  firebase_auth.User? get firebaseUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // --------------------------------------------------
  // LOAD CURRENT USER PROFILE
  // --------------------------------------------------
  Future<UserModel?> loadCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      _currentUser = null;
      return null;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = UserModel.fromMap(doc.data()!, doc.id);
      } else {
        // Create default profile if user exists in Auth but not Firestore
        final role = (user.email?.toLowerCase().contains('admin') ?? false)
            ? 'Admin'
            : 'Buyer';

        final newProfile = UserModel(
          uid: user.uid,
          name: user.displayName ?? (user.email?.split('@').first ?? 'User'),
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
          role: role,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(newProfile.toMap());
        _currentUser = newProfile;
      }
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------
  // SIGN UP
  // --------------------------------------------------
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Failed to create user account.');
    }

    // Update display name on Firebase Auth profile
    try {
      await user.updateDisplayName(name.trim());
    } catch (_) {}

    final userModel = UserModel(
      uid: user.uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: role,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap());

    _currentUser = userModel;
    return userModel;
  }

  // --------------------------------------------------
  // SIGN IN
  // --------------------------------------------------
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Failed to sign in.');
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) {
      final role = email.toLowerCase().contains('admin')
          ? 'Admin'
          : (email.toLowerCase().contains('farmer') ? 'Farmer' : 'Buyer');

      final userModel = UserModel(
        uid: user.uid,
        name: user.displayName ?? email.split('@').first,
        email: email.trim().toLowerCase(),
        phone: user.phoneNumber ?? '',
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());

      _currentUser = userModel;
      return userModel;
    }

    _currentUser = UserModel.fromMap(doc.data()!, doc.id);
    return _currentUser!;
  }

  // --------------------------------------------------
  // SIGN OUT
  // --------------------------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  // --------------------------------------------------
  // PASSWORD RESET
  // --------------------------------------------------
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
