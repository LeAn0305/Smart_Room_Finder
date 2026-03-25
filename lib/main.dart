import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:smart_room_finder/screens/splash/splash_screen.dart';
import 'package:smart_room_finder/screens/welcome/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      home: SplashScreen(nextScreen: const WelcomeScreen()),
    );
  }
}
