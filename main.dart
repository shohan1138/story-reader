import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF11111B),
  ));
  runApp(const StoryReaderApp());
}

class StoryReaderApp extends StatelessWidget {
  const StoryReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story Reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF89B4FA),
          surface: Color(0xFF11111B),
        ),
        scaffoldBackgroundColor: const Color(0xFF11111B),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
