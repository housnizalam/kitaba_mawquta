import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'features/home/home_page.dart';

Future<void> main() async {
  await AppBootstrap.initialize();

  runApp(const ProviderScope(child: KitabaMawqutaApp()));
}

/// Root application widget.
class KitabaMawqutaApp extends StatelessWidget {
  const KitabaMawqutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitaba Mawquta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomePage(),
    );
  }
}
