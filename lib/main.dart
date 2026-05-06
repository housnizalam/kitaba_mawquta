import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/state/app_state_providers.dart';
import 'features/home/home_page.dart';
import 'features/onboarding/onboarding_page.dart';

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
      home: const _AppRouter(),
    );
  }
}

/// Reads persisted settings once at startup and routes to either
/// [OnboardingPage] (first launch) or [HomePage] (returning user).
class _AppRouter extends ConsumerWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsExist = ref.watch(hasPersistedSettingsProvider);

    return settingsExist.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const HomePage(), // fail-open to home on storage error
      data: (exists) => exists ? const HomePage() : const OnboardingPage(),
    );
  }
}
