import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/state/app_state_notifier.dart';
import '../../core/state/app_state_providers.dart';
import '../../shared/widgets/constrained_page_body.dart';

const List<String> _kAdhanSounds = [
  'default_adhan',
  'makkah',
  'madinah',
  'al_aqsa',
];

const List<int> _kReminderIntervals = [10, 15, 20, 30, 45, 60];

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

String _locationModeLabel(LocationMode mode) {
  switch (mode) {
    case LocationMode.auto:
      return 'Use current location';
    case LocationMode.manual:
      return 'Choose city manually';
  }
}

/// App settings screen.
///
/// Uses local form state and saves through the app state notifier.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
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

  Future<void> _saveSettings() async {
    final updated = AppSettings(
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

    await ref.read(appStateNotifierProvider.notifier).updateSettings(updated);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // Keep async app state loading path active.
    ref.watch(appStateNotifierProvider);
    final currentSettings = ref.watch(settingsProvider);

    // If settings are already available on first build, hydrate immediately.
    if (!_didHydrateFromPersistedSettings && currentSettings != null) {
      _applySettingsToLocalState(currentSettings);
      _didHydrateFromPersistedSettings = true;
    }

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
      appBar: AppBar(title: const Text('Settings')),
      body: ConstrainedPageBody(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _SectionHeader(title: 'Language'),
            const SizedBox(height: 8),
            _SegmentedRow<AppLanguage>(
              values: AppLanguage.values,
              selected: _language,
              labelOf: _languageLabel,
              onChanged: (v) => setState(() => _language = v),
            ),
            const SizedBox(height: 28),
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
            _SectionHeader(title: 'Reminder Interval'),
            const SizedBox(height: 4),
            Text(
              'Remind every $_reminderIntervalMinutes minutes during the prayer window.',
              style: theme.textTheme.bodySmall,
            ),
            Slider(
              value: _reminderIntervalMinutes.toDouble(),
              min: _kReminderIntervals.first.toDouble(),
              max: _kReminderIntervals.last.toDouble(),
              divisions: _kReminderIntervals.length - 1,
              label: '$_reminderIntervalMinutes min',
              onChanged: (v) {
                final snapped = _kReminderIntervals.reduce(
                  (a, b) =>
                      (a - v.round()).abs() < (b - v.round()).abs() ? a : b,
                );
                setState(() => _reminderIntervalMinutes = snapped);
              },
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: 'Location Mode'),
            const SizedBox(height: 8),
            _SegmentedRow<LocationMode>(
              values: LocationMode.values,
              selected: _locationMode,
              labelOf: _locationModeLabel,
              onChanged: (v) => setState(() => _locationMode = v),
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: 'Calculation Method'),
            const SizedBox(height: 8),
            _DropdownRow<CalculationMethodType>(
              value: _calculationMethod,
              items: CalculationMethodType.values,
              labelOf: _calcMethodLabel,
              onChanged: (v) => setState(() => _calculationMethod = v),
            ),
            const SizedBox(height: 16),
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
            _SectionHeader(title: 'Adhan Sound'),
            const SizedBox(height: 8),
            _DropdownRow<String>(
              value: _adhanSoundName,
              items: _kAdhanSounds,
              labelOf: _adhanSoundLabel,
              onChanged: (v) => setState(() => _adhanSoundName = v),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

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
      runSpacing: 8,
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
        if (v != null) {
          onChanged(v);
        }
      },
    );
  }
}
