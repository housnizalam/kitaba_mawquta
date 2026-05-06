import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/state/app_state_notifier.dart';
import '../../core/state/app_state_providers.dart';
import '../../shared/widgets/constrained_page_body.dart';
import '../home/home_page.dart';

// ---------------------------------------------------------------------------
// Available adhan sound options.
// Replace display names or add more choices here when real audio is added.
// ---------------------------------------------------------------------------
const List<String> _kAdhanSounds = [
  'default_adhan',
  'makkah',
  'madinah',
  'al_aqsa',
];

// ---------------------------------------------------------------------------
// Reminder-interval steps shown in the slider label row.
// ---------------------------------------------------------------------------
const List<int> _kReminderIntervals = [10, 15, 20, 30, 45, 60];

// ---------------------------------------------------------------------------
// Human-readable labels for enums used locally in this page.
// ---------------------------------------------------------------------------
String _languageLabel(AppLanguage v) {
  switch (v) {
    case AppLanguage.arabic:
      return 'العربية';
    case AppLanguage.german:
      return 'Deutsch';
    case AppLanguage.english:
      return 'English';
  }
}

String _calcMethodLabel(CalculationMethodType v) {
  const labels = {
    CalculationMethodType.muslimWorldLeague: 'Muslim World League',
    CalculationMethodType.egyptian: 'Egyptian General Authority',
    CalculationMethodType.karachi: 'University of Islamic Sciences, Karachi',
    CalculationMethodType.ummAlQura: 'Umm Al-Qura, Makkah',
    CalculationMethodType.dubai: 'Dubai',
    CalculationMethodType.northAmerica: 'Islamic Society of North America',
    CalculationMethodType.kuwait: 'Kuwait',
    CalculationMethodType.qatar: 'Qatar',
    CalculationMethodType.singapore: 'Singapore',
    CalculationMethodType.tehran: 'Institute of Geophysics, Tehran',
    CalculationMethodType.turkey: 'Diyanet İşleri Başkanlığı, Turkey',
    CalculationMethodType.moonsightingCommittee: 'Moonsighting Committee',
    CalculationMethodType.other: 'Other / Custom',
  };
  return labels[v] ?? v.name;
}

String _adhanSoundLabel(String key) {
  const labels = {
    'default_adhan': 'Default Adhan',
    'makkah': 'Makkah',
    'madinah': 'Madinah',
    'al_aqsa': 'Al-Aqsa',
  };
  return labels[key] ?? key;
}

// ---------------------------------------------------------------------------
// Onboarding page
// ---------------------------------------------------------------------------

/// The first screen users see on a fresh install.
///
/// It lets them configure language, notifications, location mode,
/// calculation method, reminder interval, and adhan sound before
/// entering the main app.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  // -------------------------------------------------------------------------
  // Local form state — initialized from persisted settings on first build.
  // -------------------------------------------------------------------------
  AppLanguage _language = AppLanguage.english;
  bool _notificationsEnabled = true;
  bool _adhanEnabled = true;
  bool _vibrationEnabled = true;
  LocationMode _locationMode = LocationMode.auto;
  CalculationMethodType _calculationMethod =
      CalculationMethodType.muslimWorldLeague;
  AsrMethod _asrMethod = AsrMethod.standard;
  int _reminderIntervalMinutes = 15;
  String _adhanSoundName = 'default_adhan';

  bool _didHydrateFromPersistedSettings = false;

  void _applySettingsToLocalState(AppSettings settings) {
    _language = settings.language;
    _notificationsEnabled = settings.notificationsEnabled;
    _adhanEnabled = settings.adhanEnabled;
    _vibrationEnabled = settings.vibrationEnabled;
    _locationMode = settings.locationMode;
    _calculationMethod = settings.calculationMethod;
    _asrMethod = settings.asrMethod;
    _reminderIntervalMinutes = settings.reminderIntervalMinutes;
    _adhanSoundName = settings.adhanSoundName;
  }

  // -------------------------------------------------------------------------
  // Save and navigate
  // -------------------------------------------------------------------------
  Future<void> _saveAndContinue() async {
    final newSettings = AppSettings(
      language: _language,
      reminderIntervalMinutes: _reminderIntervalMinutes,
      notificationsEnabled: _notificationsEnabled,
      adhanEnabled: _adhanEnabled,
      vibrationEnabled: _vibrationEnabled,
      adhanSoundName: _adhanSoundName,
      calculationMethod: _calculationMethod,
      asrMethod: _asrMethod,
      locationMode: _locationMode,
    );

    await ref
        .read(appStateNotifierProvider.notifier)
        .updateSettings(newSettings);

    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      // Opened as settings screen from HomePage — return with a saved flag.
      Navigator.of(context).pop(true);
    } else {
      // First launch — replace the router screen with HomePage.
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  // -------------------------------------------------------------------------
  // Location placeholder — replace with real permission/geocoding later.
  // -------------------------------------------------------------------------
  void _handleUseCurrentLocation() {
    setState(() => _locationMode = LocationMode.auto);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location permission will be requested when this feature is ready.',
        ),
      ),
    );
  }

  void _handleChooseCityManually() {
    setState(() => _locationMode = LocationMode.manual);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('City picker will be available in a future update.'),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Keep the async app-state loading path active for this page.
    ref.watch(appStateNotifierProvider);

    ref.listen<AppSettings?>(settingsProvider, (previous, next) {
      if (!mounted || _didHydrateFromPersistedSettings || next == null) {
        return;
      }

      setState(() {
        _applySettingsToLocalState(next);
        _didHydrateFromPersistedSettings = true;
      });
    });

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: ConstrainedPageBody(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // ------ Header -------------------------------------------------
            Text(
              'Welcome to Kitaba Mawquta',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Configure your preferences to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 28),

            // ------ Language -----------------------------------------------
            _SectionHeader(title: 'Language'),
            const SizedBox(height: 8),
            _SegmentedRow<AppLanguage>(
              values: AppLanguage.values,
              selected: _language,
              labelOf: _languageLabel,
              onChanged: (v) => setState(() => _language = v),
            ),

            const SizedBox(height: 28),

            // ------ Notifications ------------------------------------------
            _SectionHeader(title: 'Notifications & Reminders'),
            const SizedBox(height: 4),
            _ToggleTile(
              title: 'Enable notifications',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
            _ToggleTile(
              title: 'Enable adhan sound',
              value: _adhanEnabled,
              onChanged: (v) => setState(() => _adhanEnabled = v),
            ),
            _ToggleTile(
              title: 'Enable vibration',
              value: _vibrationEnabled,
              onChanged: (v) => setState(() => _vibrationEnabled = v),
            ),

            const SizedBox(height: 28),

            // ------ Reminder interval --------------------------------------
            _SectionHeader(title: 'Reminder Interval'),
            const SizedBox(height: 4),
            Text(
              'Remind me every $_reminderIntervalMinutes minutes during the prayer window.',
              style: theme.textTheme.bodySmall,
            ),
            Slider(
              value: _reminderIntervalMinutes.toDouble(),
              min: _kReminderIntervals.first.toDouble(),
              max: _kReminderIntervals.last.toDouble(),
              divisions: _kReminderIntervals.length - 1,
              label: '$_reminderIntervalMinutes min',
              onChanged: (v) {
                // Snap to the nearest defined step.
                final snapped = _kReminderIntervals.reduce(
                  (a, b) =>
                      (a - v.round()).abs() < (b - v.round()).abs() ? a : b,
                );
                setState(() => _reminderIntervalMinutes = snapped);
              },
            ),

            const SizedBox(height: 28),

            // ------ Location -----------------------------------------------
            _SectionHeader(title: 'Location'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('Use my location'),
                    style: _locationMode == LocationMode.auto
                        ? OutlinedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                          )
                        : null,
                    onPressed: _handleUseCurrentLocation,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.location_city, size: 18),
                    label: const Text('Choose city'),
                    style: _locationMode == LocationMode.manual
                        ? OutlinedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                          )
                        : null,
                    onPressed: _handleChooseCityManually,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _locationMode == LocationMode.auto
                  ? 'Selected: Use current location'
                  : 'Selected: Choose city manually',
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 28),

            // ------ Calculation method -------------------------------------
            _SectionHeader(title: 'Calculation Method'),
            const SizedBox(height: 8),
            _DropdownRow<CalculationMethodType>(
              value: _calculationMethod,
              items: CalculationMethodType.values,
              labelOf: _calcMethodLabel,
              onChanged: (v) => setState(() => _calculationMethod = v),
            ),

            const SizedBox(height: 16),

            // ------ Asr method ---------------------------------------------
            _SectionHeader(title: 'Asr Calculation'),
            const SizedBox(height: 8),
            _SegmentedRow<AsrMethod>(
              values: AsrMethod.values,
              selected: _asrMethod,
              labelOf: (v) =>
                  v == AsrMethod.standard ? 'Standard (Shafi\'i)' : 'Hanafi',
              onChanged: (v) => setState(() => _asrMethod = v),
            ),

            const SizedBox(height: 28),

            // ------ Adhan sound --------------------------------------------
            _SectionHeader(title: 'Adhan Sound'),
            const SizedBox(height: 8),
            _DropdownRow<String>(
              value: _adhanSoundName,
              items: _kAdhanSounds,
              labelOf: _adhanSoundLabel,
              onChanged: (v) => setState(() => _adhanSoundName = v),
            ),

            const SizedBox(height: 40),

            // ------ Save button --------------------------------------------
            FilledButton(
              onPressed: _saveAndContinue,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Save & Get Started'),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small reusable section-level widgets used only in this file.
// ---------------------------------------------------------------------------

/// Bold section header label.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

/// A switch-based list tile for boolean settings.
class _ToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// A row of segmented-style [ChoiceChip] buttons for small enum selections.
class _SegmentedRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const _SegmentedRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: values
          .map(
            (v) => ChoiceChip(
              label: Text(labelOf(v)),
              selected: v == selected,
              onSelected: (_) => onChanged(v),
            ),
          )
          .toList(),
    );
  }
}

/// A [DropdownButton] wrapped in a full-width container for long enum lists.
class _DropdownRow<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const _DropdownRow({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items
          .map((v) => DropdownMenuItem<T>(value: v, child: Text(labelOf(v))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
