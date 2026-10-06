import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/dashboard_screen.dart';

void main() => runApp(const ProviderScope(child: ScooterApp()));

class ScooterApp extends StatelessWidget {
  const ScooterApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Scooter Dashboard',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green, brightness: Brightness.dark),
    home: const DashboardScreen(),
  );
}
