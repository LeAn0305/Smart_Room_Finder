import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:smart_room_finder/core/l10n/language_provider.dart';
import 'package:smart_room_finder/firebase_options.dart';
import 'package:smart_room_finder/screens/splash/splash_screen.dart';
import 'package:smart_room_finder/screens/welcome/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: langProvider.locale,
      supportedLocales: LanguageProvider.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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