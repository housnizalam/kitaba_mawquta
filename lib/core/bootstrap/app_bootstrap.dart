import 'package:flutter/widgets.dart';

import '../storage/hive_storage_initializer.dart';

/// Handles all startup tasks that must complete before the app is shown.
///
/// Call [AppBootstrap.initialize] once at the very beginning of [main],
/// before [runApp].
class AppBootstrap {
  AppBootstrap._();

  /// Runs all startup steps in the correct order:
  /// 1. Ensures Flutter binding is initialized.
  /// 2. Initializes Hive and opens the required boxes.
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await HiveStorageInitializer.initialize();
  }
}
