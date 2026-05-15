import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Take2',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0E4B3C),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
