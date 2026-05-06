import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/state/app_state_notifier.dart';
import '../../core/state/app_state_providers.dart';
import '../home/home_page.dart';
import '../../shared/widgets/constrained_page_body.dart';

// ---------------------------------------------------------------------------
// Ordered list of all five PrayerTypes used for dot rendering.
// ---------------------------------------------------------------------------
const _kPrayerOrder = [
  PrayerType.fajr,
  PrayerType.dhuhr,
  PrayerType.asr,
  PrayerType.maghrib,
  PrayerType.isha,
];

const _kWeekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const _kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

// ---------------------------------------------------------------------------
// CalendarPage
// ---------------------------------------------------------------------------
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(
      () => _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      ),
    );
  }

  void _nextMonth() {
    setState(
      () => _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      ),
    );
  }

  Future<void> _selectDayAndOpenHome(DateTime day) async {
    await ref.read(appStateNotifierProvider.notifier).setSelectedDate(day);

    if (!mounted) {
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    await Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final todaySchedule = ref.watch(todayScheduleProvider);
    final earliestUsageDay = ref.watch(earliestUsageDayProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Build date → prayer entries map.
    final Map<String, List<PrayerTimeEntry>> prayerData = {};
    for (final log in history) {
      prayerData[_dayKey(log.date)] = log.prayers;
    }
    if (todaySchedule != null && todaySchedule.prayers.isNotEmpty) {
      prayerData[_dayKey(todaySchedule.date)] = todaySchedule.prayers;
    }

    // Calendar starts effectively from first usage day; before that month is
    // not navigable.
    final today = _dayOnly(now);
    final effectiveEarliestDay = earliestUsageDay ?? today;
    final firstUsageMonth = DateTime(
      effectiveEarliestDay.year,
      effectiveEarliestDay.month,
    );

    final visibleMonth = _displayedMonth.isBefore(firstUsageMonth)
        ? firstUsageMonth
        : _displayedMonth;

    // Build list of day numbers (nullable = leading/trailing padding cell).
    final firstWeekday = DateTime(
      visibleMonth.year,
      visibleMonth.month,
      1,
    ).weekday; // 1=Mon … 7=Sun
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final leadingBlanks = firstWeekday - 1;

    // Total cells (round up to full weeks).
    final totalCells = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - totalCells % 7) % 7;
    final cellCount = totalCells + trailingBlanks;

    final canGoNext =
        !_isSameMonth(visibleMonth, today) || visibleMonth.isBefore(today);
    final canGoPrevious = visibleMonth.isAfter(firstUsageMonth);

    final monthSummary = _buildMonthSummary(
      visibleMonth: visibleMonth,
      now: now,
      today: today,
      earliestUsageDay: effectiveEarliestDay,
      prayerData: prayerData,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: ConstrainedPageBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              // Month navigation header.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: canGoPrevious ? _previousMonth : null,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous month',
                    ),
                    Text(
                      '${_kMonthNames[visibleMonth.month - 1]} ${visibleMonth.year}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: canGoNext ? _nextMonth : null,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next month',
                    ),
                  ],
                ),
              ),

              // Weekday label row.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: _kWeekdayLabels
                      .map(
                        (label) => Expanded(
                          child: Center(
                            child: Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 4),

              // Calendar grid.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: cellCount,
                  itemBuilder: (context, index) {
                    final dayNumber = index - leadingBlanks + 1;

                    // Leading/trailing blank cells.
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox.shrink();
                    }

                    final cellDate = DateTime(
                      visibleMonth.year,
                      visibleMonth.month,
                      dayNumber,
                    );
                    final key = _dayKey(cellDate);
                    final prayers = prayerData[key];

                    // Only show dots when there is data and the day is at or
                    // after the earliest recorded day.
                    final showDots =
                        prayers != null &&
                        !cellDate.isBefore(effectiveEarliestDay);
                    final isFutureDay = cellDate.isAfter(today);
                    final isBeforeUsage = cellDate.isBefore(
                      effectiveEarliestDay,
                    );
                    final isSelectable = !isFutureDay && !isBeforeUsage;

                    return _DayCell(
                      day: dayNumber,
                      prayers: showDots ? prayers : null,
                      isToday: cellDate == today,
                      isEnabled: isSelectable,
                      onTap: isSelectable
                          ? () => _selectDayAndOpenHome(cellDate)
                          : null,
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: _MonthSummaryCard(summary: monthSummary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DayCell
// ---------------------------------------------------------------------------
class _DayCell extends StatelessWidget {
  final int day;
  final List<PrayerTimeEntry>? prayers; // null → no dots
  final bool isToday;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.prayers,
    required this.isToday,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isEnabled
        ? theme.colorScheme.outlineVariant
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.35);
    final background = isEnabled
        ? (isToday
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface)
        : theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.55);
    final shadowColor = isEnabled
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: isToday ? 1.2 : 0.8),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: isEnabled ? 3.5 : 0,
              offset: isEnabled ? const Offset(0, 1.5) : Offset.zero,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                color: !isEnabled
                    ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
                    : isToday
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            if (prayers != null) _PrayerDotRow(prayers: prayers!),
          ],
        ),
      ),
    );
  }
}

class _MonthSummary {
  final int prayed;
  final int missed;
  final int qada;
  final int totalPossiblePrayers;

  const _MonthSummary({
    required this.prayed,
    required this.missed,
    required this.qada,
    required this.totalPossiblePrayers,
  });
}

class _MonthSummaryCard extends StatelessWidget {
  final _MonthSummary summary;

  const _MonthSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly summary',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _SummaryStatusItem(
                  color: Colors.green.shade600,
                  label: 'Prayed',
                  count: summary.prayed,
                ),
                _SummaryStatusItem(
                  color: Colors.red.shade600,
                  label: 'Missed',
                  count: summary.missed,
                ),
                _SummaryStatusItem(
                  color: const Color(0xFFE6B800),
                  label: 'Qada',
                  count: summary.qada,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total possible prayers: ${summary.totalPossiblePrayers}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatusItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _SummaryStatusItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label: $count', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _PrayerDotRow — five small status dots in Fajr→Isha order
// ---------------------------------------------------------------------------
class _PrayerDotRow extends StatelessWidget {
  final List<PrayerTimeEntry> prayers;

  const _PrayerDotRow({required this.prayers});

  @override
  Widget build(BuildContext context) {
    // Build a quick lookup map.
    final Map<PrayerType, PrayerCompletionStatus> statusMap = {
      for (final e in prayers) e.prayerType: e.status,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _kPrayerOrder.map((type) {
        final status = statusMap[type];
        final color = _dotColor(status);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: _PrayerDot(color: color),
        );
      }).toList(),
    );
  }

  Color? _dotColor(PrayerCompletionStatus? status) {
    switch (status) {
      case PrayerCompletionStatus.prayed:
        return Colors.green.shade600;
      case PrayerCompletionStatus.missed:
        return Colors.red.shade600;
      case PrayerCompletionStatus.qada:
        return const Color(0xFFE6B800);
      case PrayerCompletionStatus.pending:
      case null:
        return null;
    }
  }
}

// ---------------------------------------------------------------------------
// _PrayerDot
// ---------------------------------------------------------------------------
class _PrayerDot extends StatelessWidget {
  final Color? color;

  const _PrayerDot({required this.color});

  @override
  Widget build(BuildContext context) {
    if (color == null) {
      // Keep spacing for consistent Fajr→Isha ordering, but hide the dot.
      return const SizedBox(width: 5, height: 5);
    }

    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color!, shape: BoxShape.circle),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

bool _isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

_MonthSummary _buildMonthSummary({
  required DateTime visibleMonth,
  required DateTime now,
  required DateTime today,
  required DateTime earliestUsageDay,
  required Map<String, List<PrayerTimeEntry>> prayerData,
}) {
  final monthStart = DateTime(visibleMonth.year, visibleMonth.month, 1);
  final monthEnd = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);

  final eligibleStart = earliestUsageDay.isAfter(monthStart)
      ? earliestUsageDay
      : monthStart;
  final eligibleEnd = today.isBefore(monthEnd) ? today : monthEnd;

  if (eligibleStart.isAfter(eligibleEnd)) {
    return const _MonthSummary(
      prayed: 0,
      missed: 0,
      qada: 0,
      totalPossiblePrayers: 0,
    );
  }

  int prayed = 0;
  int missed = 0;
  int qada = 0;
  int totalPossiblePrayers = 0;

  var current = eligibleStart;
  while (!current.isAfter(eligibleEnd)) {
    final entries = prayerData[_dayKey(current)] ?? const <PrayerTimeEntry>[];
    for (final entry in entries) {
      if (!entry.startTime.isAfter(now)) {
        totalPossiblePrayers += 1;
      }

      switch (entry.status) {
        case PrayerCompletionStatus.prayed:
          prayed += 1;
        case PrayerCompletionStatus.missed:
          missed += 1;
        case PrayerCompletionStatus.qada:
          qada += 1;
        case PrayerCompletionStatus.pending:
          break;
      }
    }

    current = current.add(const Duration(days: 1));
  }

  return _MonthSummary(
    prayed: prayed,
    missed: missed,
    qada: qada,
    totalPossiblePrayers: totalPossiblePrayers,
  );
}
