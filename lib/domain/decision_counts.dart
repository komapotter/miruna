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
}
