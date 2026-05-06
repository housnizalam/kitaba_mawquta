import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/state/app_state_notifier.dart';
import '../../core/state/app_state_providers.dart';
import '../../shared/widgets/constrained_page_body.dart';

enum _HistoryFilter { today, week, month }

class _DayHistoryView {
  final DateTime date;
  final List<PrayerTimeEntry> prayers;

  const _DayHistoryView({required this.date, required this.prayers});
}

/// History and statistics screen.
///
/// Shows today's prayer results, previous saved days, and basic prayed/missed
/// counts with simple date-range filtering.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  _HistoryFilter _selectedFilter = _HistoryFilter.today;

  @override
  Widget build(BuildContext context) {
    final appStateAsync = ref.watch(appStateNotifierProvider);
    final history = ref.watch(historyProvider);
    final todaySchedule = ref.watch(todayScheduleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History & Statistics')),
      body: appStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load history: $error'),
          ),
        ),
        data: (_) {
          final dayViews = _buildDayViews(
            todaySchedule: todaySchedule,
            history: history,
          );
          final filtered = _applyFilter(dayViews, _selectedFilter);
          final prayedCount = _countPrayed(filtered);
          final missedCount = _countMissed(filtered);
          final qadaCount = _countQada(filtered);

          return ConstrainedPageBody(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                _FilterSelector(
                  selected: _selectedFilter,
                  onChanged: (value) => setState(() => _selectedFilter = value),
                ),
                const SizedBox(height: 16),
                _SummaryCard(
                  prayedCount: prayedCount,
                  missedCount: missedCount,
                  qadaCount: qadaCount,
                ),
                const SizedBox(height: 20),
                if (filtered.isEmpty)
                  const _EmptyHistoryCard()
                else
                  ...filtered.map(
                    (day) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayHistoryCard(day: day),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_DayHistoryView> _buildDayViews({
    required DailyPrayerSchedule? todaySchedule,
    required List<DailyPrayerLog> history,
  }) {
    final Map<String, _DayHistoryView> map = {};

    for (final log in history) {
      final day = _dayOnly(log.date);
      map[_dayKey(day)] = _DayHistoryView(date: day, prayers: log.prayers);
    }

    if (todaySchedule != null && todaySchedule.prayers.isNotEmpty) {
      final today = _dayOnly(todaySchedule.date);
      map[_dayKey(today)] = _DayHistoryView(
        date: today,
        prayers: todaySchedule.prayers,
      );
    }

    final result = map.values.toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  List<_DayHistoryView> _applyFilter(
    List<_DayHistoryView> days,
    _HistoryFilter filter,
  ) {
    final now = DateTime.now();
    final today = _dayOnly(now);

    switch (filter) {
      case _HistoryFilter.today:
        return days.where((day) => _dayOnly(day.date) == today).toList();
      case _HistoryFilter.week:
        final start = today.subtract(const Duration(days: 6));
        return days.where((day) {
          final current = _dayOnly(day.date);
          return !current.isBefore(start) && !current.isAfter(today);
        }).toList();
      case _HistoryFilter.month:
        final start = DateTime(today.year, today.month, 1);
        return days.where((day) {
          final current = _dayOnly(day.date);
          return !current.isBefore(start) && !current.isAfter(today);
        }).toList();
    }
  }

  int _countPrayed(List<_DayHistoryView> days) {
    return days
        .expand((day) => day.prayers)
        .where((entry) => entry.status == PrayerCompletionStatus.prayed)
        .length;
  }

  int _countMissed(List<_DayHistoryView> days) {
    return days
        .expand((day) => day.prayers)
        .where((entry) => entry.status == PrayerCompletionStatus.missed)
        .length;
  }

  int _countQada(List<_DayHistoryView> days) {
    return days
        .expand((day) => day.prayers)
        .where((entry) => entry.status == PrayerCompletionStatus.qada)
        .length;
  }

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _dayKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _FilterSelector extends StatelessWidget {
  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;

  const _FilterSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _HistoryFilter.values
          .map(
            (filter) => ChoiceChip(
              label: Text(_filterLabel(filter)),
              selected: selected == filter,
              onSelected: (_) => onChanged(filter),
            ),
          )
          .toList(),
    );
  }

  String _filterLabel(_HistoryFilter filter) {
    switch (filter) {
      case _HistoryFilter.today:
        return 'Today';
      case _HistoryFilter.week:
        return 'This week';
      case _HistoryFilter.month:
        return 'This month';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final int prayedCount;
  final int missedCount;
  final int qadaCount;

  const _SummaryCard({
    required this.prayedCount,
    required this.missedCount,
    required this.qadaCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _SummaryItem(
                title: 'Prayed',
                value: prayedCount.toString(),
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryItem(
                title: 'Missed',
                value: missedCount.toString(),
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryItem(
                title: 'Qada',
                value: qadaCount.toString(),
                color: const Color(0xFFE6B800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(title),
        ],
      ),
    );
  }
}

class _DayHistoryCard extends StatelessWidget {
  final _DayHistoryView day;

  const _DayHistoryCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final prayed = day.prayers
        .where((entry) => entry.status == PrayerCompletionStatus.prayed)
        .length;
    final missed = day.prayers
        .where((entry) => entry.status == PrayerCompletionStatus.missed)
        .length;
    final qada = day.prayers
        .where((entry) => entry.status == PrayerCompletionStatus.qada)
        .length;

    return Card(
      child: ExpansionTile(
        title: Text(_formatDate(day.date)),
        subtitle: Text('Prayed: $prayed • Missed: $missed • Qada: $qada'),
        children: day.prayers
            .map(
              (entry) => ListTile(
                title: Text(_prayerName(entry.prayerType)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Starts: ${_formatTime(entry.startTime)}'),
                    Text('Ends: ${_formatTime(entry.endTime)}'),
                    Text('Status: ${_statusLabel(entry.status)}'),
                    if (entry.prayedAt != null)
                      Text('Prayed at: ${_formatTime(entry.prayedAt!)}'),
                  ],
                ),
                trailing: _StatusChip(status: entry.status),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PrayerCompletionStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _statusColors(theme, status);

    return Chip(
      label: Text(_statusLabel(status)),
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

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text('No history available yet.'),
      ),
    );
  }
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

String _statusLabel(PrayerCompletionStatus status) {
  switch (status) {
    case PrayerCompletionStatus.pending:
      return 'Pending';
    case PrayerCompletionStatus.prayed:
      return 'Prayed (on time)';
    case PrayerCompletionStatus.missed:
      return 'Missed';
    case PrayerCompletionStatus.qada:
      return 'Qada';
  }
}

_StatusColors _statusColors(ThemeData theme, PrayerCompletionStatus status) {
  switch (status) {
    case PrayerCompletionStatus.pending:
      return _StatusColors(
        background: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurfaceVariant,
      );
    case PrayerCompletionStatus.prayed:
      return _StatusColors(
        background: theme.colorScheme.tertiaryContainer,
        foreground: theme.colorScheme.onTertiaryContainer,
      );
    case PrayerCompletionStatus.missed:
      return _StatusColors(
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
      );
    case PrayerCompletionStatus.qada:
      return const _StatusColors(
        background: Color(0xFFFFF3CD),
        foreground: Color(0xFF8A6D00),
      );
  }
}
