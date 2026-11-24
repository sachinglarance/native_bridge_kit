import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/home_page.dart';

void main() => runApp(const ProviderScope(child: NativeBridgeApp()));

class NativeBridgeApp extends StatelessWidget {
  const NativeBridgeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Native Bridge Kit',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.deepPurple,
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}
