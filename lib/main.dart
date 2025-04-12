import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_lock/home/screens/home_screen.dart';

import 'home/cubit/bottom_navigation_cubit.dart';

void main() {
  runApp(MyBeaconApp());
}

class MyBeaconApp extends StatelessWidget {
  const MyBeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white70,
          surface: Color(0xFF1A1A1A),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
          create: (_) => BottomNavigationCubit(), child: HomeScreen()),
    );
  }
}
