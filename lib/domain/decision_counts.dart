/// One day's yes/no totals for a single watched app.
class DailyDecisionCount {
  const DailyDecisionCount({
    required this.packageName,
    required this.dateKey,
    this.yesCount = 0,
    this.noCount = 0,
  });

  final String packageName;

  /// Local calendar date as `yyyy-MM-dd`.
  final String dateKey;
  final int yesCount;
  final int noCount;

  factory DailyDecisionCount.fromChannelMap(Map<Object?, Object?> map) {
    return DailyDecisionCount(
      packageName: map['packageName'] as String,
      dateKey: map['date'] as String,
      yesCount: (map['yesCount'] as num?)?.toInt() ?? 0,
      noCount: (map['noCount'] as num?)?.toInt() ?? 0,
    );
  }

  String periodKey(DecisionPeriod period) {
    switch (period) {
      case DecisionPeriod.day:
        return dateKey;
      case DecisionPeriod.month:
        return dateKey.length >= 7 ? dateKey.substring(0, 7) : dateKey;
      case DecisionPeriod.year:
        return dateKey.length >= 4 ? dateKey.substring(0, 4) : dateKey;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is DailyDecisionCount &&
        other.packageName == packageName &&
        other.dateKey == dateKey &&
        other.yesCount == yesCount &&
        other.noCount == noCount;
  }

  @override
  int get hashCode => Object.hash(packageName, dateKey, yesCount, noCount);
}

enum DecisionPeriod { day, month, year }

class PeriodDecisionCount {
  const PeriodDecisionCount({
    required this.packageName,
    required this.period,
    required this.periodKey,
    this.yesCount = 0,
    this.noCount = 0,
  });

  final String packageName;
  final DecisionPeriod period;

  /// `yyyy-MM-dd`, `yyyy-MM`, or `yyyy` depending on [period].
  final String periodKey;
  final int yesCount;
  final int noCount;

  /// Combined height used by the stacked yes/no bar chart.
  int get totalCount => yesCount + noCount;

  PeriodDecisionCount add(int yes, int no) {
    return PeriodDecisionCount(
      packageName: packageName,
      period: period,
      periodKey: periodKey,
      yesCount: yesCount + yes,
      noCount: noCount + no,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PeriodDecisionCount &&
        other.packageName == packageName &&
        other.period == period &&
        other.periodKey == periodKey &&
        other.yesCount == yesCount &&
        other.noCount == noCount;
  }

  @override
  int get hashCode =>
      Object.hash(packageName, period, periodKey, yesCount, noCount);
}

class DecisionTally {
  const DecisionTally({this.yesCount = 0, this.noCount = 0});

  final int yesCount;
  final int noCount;

  DecisionTally increment({required bool yes}) {
    return DecisionTally(
      yesCount: yesCount + (yes ? 1 : 0),
      noCount: noCount + (yes ? 0 : 1),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DecisionTally &&
        other.yesCount == yesCount &&
        other.noCount == noCount;
  }

  @override
  int get hashCode => Object.hash(yesCount, noCount);
}

/// Daily yes/no totals, plus the merge/aggregation rules used by Android.
class DecisionCounts {
  const DecisionCounts(this.entries);

  static const empty = DecisionCounts([]);

  final List<DailyDecisionCount> entries;

  factory DecisionCounts.fromChannelList(List<Object?> raw) {
    return DecisionCounts([
      for (final item in raw)
        if (item is Map<Object?, Object?>) DailyDecisionCount.fromChannelMap(item),
    ]);
  }

  static String localDateKey(DateTime date) {
    final local = date.isUtc ? date.toLocal() : date;
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static bool dateInRange(
    String dateKey, {
    String? fromDate,
    String? toDate,
  }) {
    if (fromDate != null && dateKey.compareTo(fromDate) < 0) {
      return false;
    }
    if (toDate != null && dateKey.compareTo(toDate) > 0) {
      return false;
    }
    return true;
  }

  /// Spec for the Android store: add one yes/no to the app's local-date bucket.
  static Map<String, Map<String, DecisionTally>> increment({
    required Map<String, Map<String, DecisionTally>> current,
    required String packageName,
    required bool yes,
    required DateTime now,
  }) {
    final date = localDateKey(now);
    final next = <String, Map<String, DecisionTally>>{
      for (final entry in current.entries)
        entry.key: Map<String, DecisionTally>.from(entry.value),
    };
    final days = next.putIfAbsent(packageName, () => <String, DecisionTally>{});
    final existing = days[date] ?? const DecisionTally();
    days[date] = existing.increment(yes: yes);
    return next;
  }

  DecisionCounts filtered({
    String? packageName,
    DateTime? from,
    DateTime? to,
  }) {
    final fromDate = from == null ? null : localDateKey(from);
    final toDate = to == null ? null : localDateKey(to);
    return DecisionCounts([
      for (final entry in entries)
        if ((packageName == null || entry.packageName == packageName) &&
            dateInRange(entry.dateKey, fromDate: fromDate, toDate: toDate))
          entry,
    ]);
  }

  List<PeriodDecisionCount> groupedBy(DecisionPeriod period) {
    final buckets = <String, PeriodDecisionCount>{};
    for (final entry in entries) {
      final periodKey = entry.periodKey(period);
      final key = '${entry.packageName}\t$periodKey';
      final existing = buckets[key];
      buckets[key] = existing == null
          ? PeriodDecisionCount(
              packageName: entry.packageName,
              period: period,
              periodKey: periodKey,
              yesCount: entry.yesCount,
              noCount: entry.noCount,
            )
          : existing.add(entry.yesCount, entry.noCount);
    }
    return buckets.values.toList()
      ..sort((a, b) {
        final byPackage = a.packageName.compareTo(b.packageName);
        if (byPackage != 0) {
          return byPackage;
        }
        return a.periodKey.compareTo(b.periodKey);
      });
  }

  int todayYesCount({required String packageName, required DateTime now}) {
    final key = localDateKey(now);
    return entries
        .where((entry) => entry.packageName == packageName && entry.dateKey == key)
        .fold<int>(0, (sum, entry) => sum + entry.yesCount);
  }

  bool get hasDecisions =>
      entries.any((entry) => entry.yesCount > 0 || entry.noCount > 0);

  /// Local `yyyy-MM` key for month buckets.
  static String yearMonthKey(DateTime date) {
    final local = date.isUtc ? date.toLocal() : date;
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  static String formatPeriodLabel(DecisionPeriod period, String periodKey) {
    switch (period) {
      case DecisionPeriod.day:
        return formatWeekdayLabel(periodKey);
      case DecisionPeriod.month:
        if (periodKey.length < 7) return periodKey;
        return '${int.parse(periodKey.substring(5, 7))}月';
      case DecisionPeriod.year:
        return periodKey;
    }
  }

  /// Monday-first weekday for a `yyyy-MM-dd` key: 月…日.
  static String formatWeekdayLabel(String dateKey) {
    if (dateKey.length < 10) return dateKey;
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final date = DateTime(
      int.parse(dateKey.substring(0, 4)),
      int.parse(dateKey.substring(5, 7)),
      int.parse(dateKey.substring(8, 10)),
    );
    return weekdays[date.weekday - 1];
  }

  /// Visible chart window, e.g. `8月31日～9月6日` or `2025年10月～2026年9月`.
  static String formatAggregationRange({
    required DecisionPeriod period,
    required List<String> periodKeys,
  }) {
    if (periodKeys.isEmpty) return '';
    final first = periodKeys.first;
    final last = periodKeys.last;
    switch (period) {
      case DecisionPeriod.day:
        final crossYear = first.substring(0, 4) != last.substring(0, 4);
        return '${_formatMonthDay(first, includeYear: crossYear)}～${_formatMonthDay(last, includeYear: crossYear)}';
      case DecisionPeriod.month:
        return first == last
            ? _formatYearMonth(first)
            : '${_formatYearMonth(first)}～${_formatYearMonth(last)}';
      case DecisionPeriod.year:
        return first == last ? '$first年' : '$first年～$last年';
    }
  }

  /// Per-bucket average over the visible chart window.
  static String formatAverageCounts({
    required DecisionPeriod period,
    required int yesTotal,
    required int noTotal,
    required int bucketCount,
  }) {
    late final String unit;
    switch (period) {
      case DecisionPeriod.day:
        unit = '1日平均';
      case DecisionPeriod.month:
        unit = '1か月平均';
      case DecisionPeriod.year:
        unit = '1年平均';
    }
    final yes = bucketCount == 0 ? 0.0 : yesTotal / bucketCount;
    final no = bucketCount == 0 ? 0.0 : noTotal / bucketCount;
    return 'はい ${_formatAverage(yes)}回 · いいえ ${_formatAverage(no)}回 ($unit)';
  }

  static String _formatAverage(double value) {
    final tenths = (value * 10).round() / 10;
    if (tenths == tenths.roundToDouble()) {
      return '${tenths.toInt()}';
    }
    return tenths.toStringAsFixed(1);
  }

  static String _formatMonthDay(String dateKey, {required bool includeYear}) {
    if (dateKey.length < 10) return dateKey;
    final month = int.parse(dateKey.substring(5, 7));
    final day = int.parse(dateKey.substring(8, 10));
    final md = '$month月$day日';
    if (!includeYear) return md;
    return '${int.parse(dateKey.substring(0, 4))}年$md';
  }

  static String _formatYearMonth(String periodKey) {
    if (periodKey.length < 7) return periodKey;
    return '${int.parse(periodKey.substring(0, 4))}年${int.parse(periodKey.substring(5, 7))}月';
  }

  /// Consecutive week (Mon-Sun) / month / year keys to plot, including empty buckets.
  static List<String> chartPeriodKeys({
    required DecisionPeriod period,
    required DateTime now,
    int? firstYear,
  }) {
    final local = now.isUtc ? now.toLocal() : now;
    switch (period) {
      case DecisionPeriod.day:
        final monday = DateTime(
          local.year,
          local.month,
          local.day - (local.weekday - 1),
        );
        return [
          for (var i = 0; i < 7; i++)
            localDateKey(DateTime(monday.year, monday.month, monday.day + i)),
        ];
      case DecisionPeriod.month:
        final start = DateTime(local.year, local.month - 11, 1);
        return [
          for (var i = 0; i < 12; i++)
            yearMonthKey(DateTime(start.year, start.month + i, 1)),
        ];
      case DecisionPeriod.year:
        final endYear = local.year;
        final startYear = firstYear == null || firstYear > endYear
            ? endYear
            : firstYear;
        return [for (var year = startYear; year <= endYear; year++) '$year'];
    }
  }

  /// Fills [chartPeriodKeys] so the graph keeps a stable axis.
  List<PeriodDecisionCount> chartSeries({
    required DecisionPeriod period,
    required DateTime now,
    String? packageName,
  }) {
    final scoped = filtered(packageName: packageName);
    final grouped = <String, PeriodDecisionCount>{};
    for (final item in scoped.groupedBy(period)) {
      final existing = grouped[item.periodKey];
      grouped[item.periodKey] = existing == null
          ? PeriodDecisionCount(
              packageName: packageName ?? item.packageName,
              period: period,
              periodKey: item.periodKey,
              yesCount: item.yesCount,
              noCount: item.noCount,
            )
          : existing.add(item.yesCount, item.noCount);
    }
    final firstYear = scoped.entries
        .map((entry) => int.tryParse(entry.periodKey(DecisionPeriod.year)))
        .whereType<int>()
        .fold<int?>(null, (min, year) => min == null || year < min ? year : min);
    final keys = chartPeriodKeys(
      period: period,
      now: now,
      firstYear: firstYear,
    );
    return [
      for (final key in keys)
        grouped[key] ??
            PeriodDecisionCount(
              packageName: packageName ?? '',
              period: period,
              periodKey: key,
            ),
    ];
  }

  /// Spec for the Android warning overlay. [yesCount] is today's confirmed
  /// unfreezes so far, not including the dialog currently on screen.
  ///
  /// Empty when there are no confirmed unfreezes yet, so the overlay omits
  /// the line instead of saying "0回".
  static String formatTodayOpenMessage(int yesCount) {
    if (yesCount <= 0) {
      return '';
    }
    return '今日は$yesCount回解除しました';
  }
}
