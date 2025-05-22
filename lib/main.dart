import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/notes_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotesProvider(),
      child: MaterialApp(
        title: 'Notes App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1C1A17),
          cardColor: const Color(0xFF3A332A),
          dialogBackgroundColor: const Color(0xFF2E2B28),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1C1A17),
            foregroundColor: Colors.white,
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFF3A332A),
            selectedColor: Theme.of(context).primaryColor,
            labelStyle: const TextStyle(color: Colors.white70),
            secondaryLabelStyle: const TextStyle(color: Colors.black87),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
