import 'package:flutter/material.dart';

void main() {
  runApp(const AgroConnectApp());
}

class AgroConnectApp extends StatelessWidget {
  const AgroConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgroConnect',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'AgroConnect',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}