import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const SmartRoomFinder());
}

class SmartRoomFinder extends StatelessWidget {
  const SmartRoomFinder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Room Finder',
      home: const SplashScreen(),
    );
  }
}