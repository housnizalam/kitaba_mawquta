import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  await AppBootstrap.initialize();

  runApp(const ProviderScope(child: KitabaMawqutaApp()));
}

/// Root application widget.
///
/// This is a temporary placeholder shell.
/// Real routes and pages will be added in a future step.
class KitabaMawqutaApp extends StatelessWidget {
  const KitabaMawqutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Kitaba Mawquta',
      debugShowCheckedModeBanner: false,
      home: _PlaceholderHome(),
    );
  }
}

/// Minimal placeholder screen so the app boots visibly.
///
/// This will be replaced with the real home screen in the UI step.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Kitaba Mawquta — loading…')),
    );
  }
}
