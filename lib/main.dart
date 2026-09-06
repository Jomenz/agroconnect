import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'package:agroconnect/features/authentication/data/auth_service.dart';
import 'package:agroconnect/features/product/data/product_store.dart';
import 'package:agroconnect/features/order/data/order_store.dart';
import 'package:agroconnect/features/negotiation/data/negotiation_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before starting the app.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize backend stores and active user session
  await AuthService.instance.loadCurrentUserProfile();
  await ProductStore.initialize();
  await OrderStore.initialize();
  await NegotiationStore.initialize();

  runApp(const AgroConnectApp());
}