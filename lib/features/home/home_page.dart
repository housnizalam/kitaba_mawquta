import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logic/prayer_logic_service.dart';
import '../../core/models/models.dart';
import '../../core/state/app_state_notifier.dart';
import '../../core/state/app_state_providers.dart';
import '../../core/state/storage_service_providers.dart';
import '../settings/settings_page.dart';
import '../../shared/widgets/constrained_page_body.dart';

/// Main home screen for the prayer app.
///
/// It shows today's prayers, the current active prayer, and quick actions.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _markCurrentPrayerAsPrayed(PrayerTimeEntry entry) async {
    final effectiveNow = DateTime.now();
    await ref
        .read(appStateNotifierProvider.notifier)
        .markPrayerAsPrayed(entry.prayerType, now: effectiveNow);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_prayerName(entry.prayerType)} marked as prayed.'),
      ),
    );
  }

  Future<void> _openSettingsPage() async {
    final didSave = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const SettingsPage()));

    if (!mounted || didSave != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully.')),
    );
  }

  void _showReminderPlaceholder(PrayerTimeEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Snooze for ${_prayerName(entry.prayerType)} is coming soon.',
        ),
      ),
    );
  }

  Future<void> _openPrayerEditDialog(PrayerTimeEntry entry) async {
    final effectiveNow = DateTime.now();
    if (effectiveNow.isBefore(entry.startTime)) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can edit this prayer after its start time.'),
        ),
      );
      return;
    }

    final pageContext = context;
    PrayerCompletionStatus selectedStatus =
        entry.status == PrayerCompletionStatus.missed
        ? PrayerCompletionStatus.missed
        : PrayerCompletionStatus.prayed;
    DateTime? selectedPrayedAt = entry.prayedAt;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickPrayedTime() async {
              final initial = selectedPrayedAt ?? entry.startTime;
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(initial),
              );

              if (pickedTime == null) {
                return;
              }

              final base = entry.startTime;
              final combined = DateTime(
                base.year,
                base.month,
                base.day,
                pickedTime.hour,
                pickedTime.minute,
              );

              setDialogState(() {
                selectedPrayedAt = combined;
                errorMessage = null;
              });
            }

            Future<void> saveEdit() async {
              if (selectedStatus == PrayerCompletionStatus.prayed) {
                if (selectedPrayedAt == null) {
                  setDialogState(() {
                    errorMessage =
                        'Please choose a prayed time when status is prayed.';
                  });
                  return;
                }

                if (selectedPrayedAt!.isBefore(entry.startTime) ||
                    selectedPrayedAt!.isAfter(entry.endTime)) {
                  setDialogState(() {
                    errorMessage =
                        'Prayed time must be between prayer start and end.';
                  });
                  return;
                }

                if (selectedPrayedAt!.isAfter(effectiveNow)) {
                  setDialogState(() {
                    errorMessage = 'Prayed time cannot be in the future.';
                  });
                  return;
                }
              }

              try {
                await ref
                    .read(appStateNotifierProvider.notifier)
                    .manuallyEditPrayerEntry(
                      entry.prayerType,
                      status: selectedStatus,
                      prayedAt: selectedPrayedAt,
                      now: effectiveNow,
                    );
              } on ArgumentError catch (e) {
                setDialogState(() {
                  errorMessage =
                      e.message?.toString() ??
                      'Invalid prayer correction. Please try again.';
                });
                return;
              }

              if (!mounted) {
                return;
              }

              if (!pageContext.mounted) {
                return;
              }

              Navigator.of(pageContext).pop();
              ScaffoldMessenger.of(pageContext).showSnackBar(
                SnackBar(
                  content: Text(
                    '${_prayerName(entry.prayerType)} was updated successfully.',
                  ),
                ),
              );
            }

            return AlertDialog(
              title: Text('Edit ${_prayerName(entry.prayerType)}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<PrayerCompletionStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              PrayerCompletionStatus.prayed,
                              PrayerCompletionStatus.missed,
                            ]
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(_completionStatusLabel(status)),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedStatus = value;
                        if (selectedStatus != PrayerCompletionStatus.prayed) {
                          selectedPrayedAt = null;
                        }
                        errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Allowed time: ${_formatTime(entry.startTime)} - ${_formatTime(entry.endTime)}',
                  ),
                  const SizedBox(height: 8),
                  if (selectedStatus == PrayerCompletionStatus.prayed)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: pickPrayedTime,
                            icon: const Icon(Icons.schedule),
                            label: Text(
                              selectedPrayedAt == null
                                  ? 'Choose prayed time'
                                  : 'Prayed at ${_formatTime(selectedPrayedAt!)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(onPressed: saveEdit, child: const Text('Save')),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveNow = DateTime.now();
    final appStateAsync = ref.watch(appStateNotifierProvider);
    final location = ref.watch(locationProvider);
    final schedule = ref.watch(todayScheduleProvider);
    final prayerLogic = ref.watch(prayerLogicServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _openSettingsPage,
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
        title: const Text('Kitaba Mawquta'),
      ),
      body: appStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load app state: $error'),
          ),
        ),
        data: (_) {
          final prayers = schedule?.prayers ?? const <PrayerTimeEntry>[];
          final activePrayer = schedule == null
              ? null
              : prayerLogic.getCurrentActivePrayerEntry(schedule, effectiveNow);
          final latestPrayedPrayer =
              prayers.where((entry) => entry.prayedAt != null).toList()
                ..sort((a, b) => b.prayedAt!.compareTo(a.prayedAt!));
          final prayedPrayer = latestPrayedPrayer.isEmpty
              ? null
              : latestPrayedPrayer.first;
          final nextPrayer = schedule == null
              ? null
              : prayerLogic.getNextUpcomingPrayerEntry(schedule, effectiveNow);

          return ConstrainedPageBody(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                Text(
                  _cityLabel(location),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(effectiveNow),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _CurrentPrayerCard(
                  now: effectiveNow,
                  activePrayer: activePrayer,
                  prayedPrayer: prayedPrayer,
                  nextPrayer: nextPrayer,
                  onPrayed: activePrayer == null
                      ? null
                      : () => _markCurrentPrayerAsPrayed(activePrayer),
                  onRemindLater: activePrayer == null
                      ? null
                      : () => _showReminderPlaceholder(activePrayer),
                ),
                const SizedBox(height: 24),
                Text(
                  'Today\'s prayers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (prayers.isEmpty)
                  _EmptyPrayerListCard(now: effectiveNow)
                else
                  ...prayers.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PrayerListTile(
                        entry: entry,
                        runtimeStatus: prayerLogic.determinePrayerRuntimeStatus(
                          entry,
                          effectiveNow,
                        ),
                        isEditable: !entry.startTime.isAfter(effectiveNow),
                        onEdit: () => _openPrayerEditDialog(entry),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CurrentPrayerCard extends StatelessWidget {
  final DateTime now;
  final PrayerTimeEntry? activePrayer;
  final PrayerTimeEntry? prayedPrayer;
  final PrayerTimeEntry? nextPrayer;
  final VoidCallback? onPrayed;
  final VoidCallback? onRemindLater;

  const _CurrentPrayerCard({
    required this.now,
    required this.activePrayer,
    required this.prayedPrayer,
    required this.nextPrayer,
    required this.onPrayed,
    required this.onRemindLater,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardPrayer = activePrayer ?? nextPrayer ?? prayedPrayer;
    final cardStatus = activePrayer != null
        ? PrayerRuntimeStatus.active
        : nextPrayer != null
        ? PrayerRuntimeStatus.notStarted
        : prayedPrayer != null
        ? PrayerRuntimeStatus.prayed
        : null;
    final showTimeRemaining = activePrayer != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activePrayer != null ? 'Current prayer' : 'Prayer overview',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (cardPrayer == null) ...[
              Text(
                'No prayer schedule is available yet.',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Once today\'s prayer times are prepared, they will appear here.',
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                _prayerName(cardPrayer.prayerType),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Starts: ${_formatTime(cardPrayer.startTime)}',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Ends: ${_formatTime(cardPrayer.endTime)}',
                style: theme.textTheme.bodyLarge,
              ),
              if (cardPrayer.prayedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Prayed at: ${_formatTime(cardPrayer.prayedAt!)}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  if (cardStatus != null) _StatusChip(status: cardStatus),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      showTimeRemaining
                          ? 'Ends in ${_formatRemaining(cardPrayer.endTime.difference(now))}'
                          : 'Next prayer starts later today',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onPrayed,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('I prayed'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRemindLater,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Remind me later'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerListTile extends StatelessWidget {
  final PrayerTimeEntry entry;
  final PrayerRuntimeStatus runtimeStatus;
  final bool isEditable;
  final VoidCallback onEdit;

  const _PrayerListTile({
    required this.entry,
    required this.runtimeStatus,
    required this.isEditable,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          _prayerName(entry.prayerType),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Starts: ${_formatTime(entry.startTime)}'),
              Text('Ends: ${_formatTime(entry.endTime)}'),
              Text('Status: ${_runtimeStatusLabel(runtimeStatus)}'),
              if (entry.prayedAt != null)
                Text('Prayed at: ${_formatTime(entry.prayedAt!)}'),
              if (!isEditable)
                Text(
                  'Editable after start time',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusChip(status: runtimeStatus),
            IconButton(
              tooltip: isEditable
                  ? 'Edit prayer'
                  : 'Editing available after prayer start',
              onPressed: isEditable ? onEdit : null,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPrayerListCard extends StatelessWidget {
  final DateTime now;

  const _EmptyPrayerListCard({required this.now});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text('No prayer times are saved for ${_formatDate(now)} yet.'),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PrayerRuntimeStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _statusColors(theme, status);

    return Chip(
      label: Text(_runtimeStatusLabel(status)),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: colors.foreground,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: colors.background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatusColors {
  final Color background;
  final Color foreground;

  const _StatusColors({required this.background, required this.foreground});
}

String _cityLabel(UserLocationData? location) {
  if (location == null || location.cityName.trim().isEmpty) {
    return 'Location not set';
  }

  if (location.countryName.trim().isEmpty) {
    return location.cityName;
  }

  return '${location.cityName}, ${location.countryName}';
}

String _formatDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatRemaining(Duration duration) {
  if (duration.isNegative) {
    return '0m';
  }

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }

  return '${minutes}m';
}

String _prayerName(PrayerType prayerType) {
  switch (prayerType) {
    case PrayerType.fajr:
      return 'Fajr';
    case PrayerType.dhuhr:
      return 'Dhuhr';
    case PrayerType.asr:
      return 'Asr';
    case PrayerType.maghrib:
      return 'Maghrib';
    case PrayerType.isha:
      return 'Isha';
  }
}

String _runtimeStatusLabel(PrayerRuntimeStatus status) {
  switch (status) {
    case PrayerRuntimeStatus.notStarted:
      return 'Not started';
    case PrayerRuntimeStatus.active:
      return 'Active';
    case PrayerRuntimeStatus.prayed:
      return 'Prayed';
    case PrayerRuntimeStatus.missed:
      return 'Missed';
  }
}

String _completionStatusLabel(PrayerCompletionStatus status) {
  switch (status) {
    case PrayerCompletionStatus.pending:
      return 'Pending';
    case PrayerCompletionStatus.prayed:
      return 'Prayed';
    case PrayerCompletionStatus.missed:
      return 'Missed';
  }
}

_StatusColors _statusColors(ThemeData theme, PrayerRuntimeStatus status) {
  switch (status) {
    case PrayerRuntimeStatus.notStarted:
      return _StatusColors(
        background: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurfaceVariant,
      );
    case PrayerRuntimeStatus.active:
      return _StatusColors(
        background: theme.colorScheme.primaryContainer,
        foreground: theme.colorScheme.onPrimaryContainer,
      );
    case PrayerRuntimeStatus.prayed:
      return _StatusColors(
        background: theme.colorScheme.tertiaryContainer,
        foreground: theme.colorScheme.onTertiaryContainer,
      );
    case PrayerRuntimeStatus.missed:
      return _StatusColors(
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
      );
  }
}
