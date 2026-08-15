import 'package:flutter/material.dart';
import 'app.dart';
import 'package:agroconnect/features/authentication/data/user_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await UserStore.loadUsers();

  runApp(const AgroConnectApp());
}