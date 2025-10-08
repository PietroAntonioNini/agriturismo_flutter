import 'package:flutter/material.dart';
import 'theme.dart';
import 'pages/login_page.dart';

/// Main app widget con Riverpod e tema custom
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agriturismo Manager',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
