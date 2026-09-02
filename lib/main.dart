import 'package:flutter/material.dart';
import 'app.dart';
import 'package:agroconnect/features/authentication/data/user_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await UserStore.loadUsers();

  debugPrint(
    'LOADED USERS: ${UserStore.users.length}',
  );

  for (final user in UserStore.users) {
    debugPrint(
      'USER: ${user.email} | ROLE: ${user.role}',
    );
  }

  final savedUsers = await UserStore.getSavedUsers();

  debugPrint(
    'SAVED USERS IN SHARED PREFERENCES: ${savedUsers.length}',
  );

  for (final savedUser in savedUsers) {
    debugPrint(
      'SAVED: $savedUser',
    );
  }

  runApp(const AgroConnectApp());
}