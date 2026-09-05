import 'package:flutter_test/flutter_test.dart';
import 'package:miruna/domain/decision_counts.dart';

void main() {
  final day = DateTime(2026, 9, 5, 14, 30);

  group('DecisionCounts.localDateKey', () {
    test('formats the local calendar date', () {
      expect(DecisionCounts.localDateKey(day), '2026-09-05');
      expect(DecisionCounts.localDateKey(DateTime(2026, 1, 2)), '2026-01-02');
    });

    test('converts UTC to local before formatting', () {
      final utc = DateTime.utc(2026, 9, 5, 15);
      expect(
        DecisionCounts.localDateKey(utc),
        DecisionCounts.localDateKey(utc.toLocal()),
      );
    });
  });

  group('DecisionCounts.increment', () {
    test('adds the first yes for an app and day', () {
      final next = DecisionCounts.increment(
        current: const {},
        packageName: 'com.instagram.android',
        yes: true,
        now: day,
      );
      expect(
        next['com.instagram.android']?['2026-09-05'],
        const DecisionTally(yesCount: 1),
      );
    });

    test('adds yes and no on the same day', () {
      var next = DecisionCounts.increment(
        current: const {},
        packageName: 'com.instagram.android',
        yes: true,
        now: day,
      );
      next = DecisionCounts.increment(
        current: next,
        packageName: 'com.instagram.android',
        yes: true,
        now: day.add(const Duration(hours: 1)),
      );
      next = DecisionCounts.increment(
        current: next,
        packageName: 'com.instagram.android',
        yes: false,
        now: day.add(const Duration(hours: 2)),
      );
      expect(
        next['com.instagram.android']?['2026-09-05'],
        const DecisionTally(yesCount: 2, noCount: 1),
      );
    });

    test('keeps other apps and days unchanged', () {
      final current = {
        'com.foo': {'2026-09-04': const DecisionTally(yesCount: 3, noCount: 1)},
      };
      final next = DecisionCounts.increment(
        current: current,
        packageName: 'com.bar',
        yes: false,
        now: day,
      );
      expect(
        next['com.foo']?['2026-09-04'],
        const DecisionTally(yesCount: 3, noCount: 1),
      );
      expect(
        next['com.bar']?['2026-09-05'],
        const DecisionTally(noCount: 1),
      );
    });
  });

  group('DecisionCounts query helpers', () {
    const counts = DecisionCounts([
      DailyDecisionCount(
        packageName: 'com.foo',
        dateKey: '2026-08-31',
        yesCount: 1,
        noCount: 2,
      ),
      DailyDecisionCount(
        packageName: 'com.foo',
        dateKey: '2026-09-05',
        yesCount: 2,
        noCount: 1,
      ),
      DailyDecisionCount(
        packageName: 'com.bar',
        dateKey: '2026-09-05',
        yesCount: 4,
      ),
      DailyDecisionCount(
        packageName: 'com.foo',
        dateKey: '2026-10-01',
        yesCount: 1,
      ),
    ]);

    test('filters by package and inclusive date range', () {
      expect(
        counts
            .filtered(
              packageName: 'com.foo',
              from: DateTime(2026, 9, 5),
              to: DateTime(2026, 9, 30),
            )
            .entries,
        [
          const DailyDecisionCount(
            packageName: 'com.foo',
            dateKey: '2026-09-05',
            yesCount: 2,
            noCount: 1,
          ),
        ],
      );
    });

    test('groups days into months and years per app', () {
      expect(
        counts.filtered(packageName: 'com.foo').groupedBy(DecisionPeriod.month),
        [
          const PeriodDecisionCount(
            packageName: 'com.foo',
            period: DecisionPeriod.month,
            periodKey: '2026-08',
            yesCount: 1,
            noCount: 2,
          ),
          const PeriodDecisionCount(
            packageName: 'com.foo',
            period: DecisionPeriod.month,
            periodKey: '2026-09',
            yesCount: 2,
            noCount: 1,
          ),
          const PeriodDecisionCount(
            packageName: 'com.foo',
            period: DecisionPeriod.month,
            periodKey: '2026-10',
            yesCount: 1,
          ),
        ],
      );
      expect(
        counts.filtered(packageName: 'com.foo').groupedBy(DecisionPeriod.year),
        [
          const PeriodDecisionCount(
            packageName: 'com.foo',
            period: DecisionPeriod.year,
            periodKey: '2026',
            yesCount: 4,
            noCount: 3,
          ),
        ],
      );
    });

    test('returns today yes count for one app', () {
      expect(
        counts.todayYesCount(packageName: 'com.foo', now: day),
        2,
      );
      expect(
        counts.todayYesCount(packageName: 'com.foo', now: DateTime(2026, 9, 6)),
        0,
      );
    });

    test('formats the overlay copy for today yes count', () {
      expect(DecisionCounts.formatTodayOpenMessage(0), '');
      expect(
        DecisionCounts.formatTodayOpenMessage(3),
        '今日は3回解除しました',
      );
      expect(DecisionCounts.formatTodayOpenMessage(-1), '');
    });

    test('builds a 14-day chart series with empty buckets filled', () {
      expect(
        counts
            .chartSeries(
              period: DecisionPeriod.day,
              now: day,
              packageName: 'com.foo',
            )
            .map((item) => (item.periodKey, item.yesCount, item.noCount))
            .toList(),
        [
          for (var i = 0; i < 14; i++)
            (
              DecisionCounts.localDateKey(DateTime(2026, 8, 23 + i)),
              DateTime(2026, 8, 23 + i).day == 31
                  ? 1
                  : DateTime(2026, 8, 23 + i).month == 9 &&
                        DateTime(2026, 8, 23 + i).day == 5
                  ? 2
                  : 0,
              DateTime(2026, 8, 23 + i).day == 31
                  ? 2
                  : DateTime(2026, 8, 23 + i).month == 9 &&
                        DateTime(2026, 8, 23 + i).day == 5
                  ? 1
                  : 0,
            ),
        ],
      );
    });

    test('builds a 12-month chart series and year keys from first record', () {
      expect(
        counts
            .chartSeries(
              period: DecisionPeriod.month,
              now: day,
              packageName: 'com.foo',
            )
            .map((item) => (item.periodKey, item.yesCount, item.noCount))
            .toList(),
        [
          for (final key in [
            '2025-10',
            '2025-11',
            '2025-12',
            '2026-01',
            '2026-02',
            '2026-03',
            '2026-04',
            '2026-05',
            '2026-06',
            '2026-07',
            '2026-08',
            '2026-09',
          ])
            (
              key,
              key == '2026-08'
                  ? 1
                  : key == '2026-09'
                  ? 2
                  : 0,
              key == '2026-08'
                  ? 2
                  : key == '2026-09'
                  ? 1
                  : 0,
            ),
        ],
      );
      expect(
        counts.chartSeries(
          period: DecisionPeriod.year,
          now: day,
          packageName: 'com.foo',
        ),
        [
          const PeriodDecisionCount(
            packageName: 'com.foo',
            period: DecisionPeriod.year,
            periodKey: '2026',
            yesCount: 4,
            noCount: 3,
          ),
        ],
      );
    });

    test('formats chart axis labels', () {
      expect(
        DecisionCounts.formatPeriodLabel(DecisionPeriod.day, '2026-09-05'),
        '9/5',
      );
      expect(
        DecisionCounts.formatPeriodLabel(DecisionPeriod.month, '2026-09'),
        '9月',
      );
      expect(
        DecisionCounts.formatPeriodLabel(DecisionPeriod.year, '2026'),
        '2026',
      );
    });

    test('maps channel payloads', () {
      expect(
        DecisionCounts.fromChannelList([
          {
            'packageName': 'com.foo',
            'date': '2026-09-05',
            'yesCount': 2,
            'noCount': 1,
          },
        ]).entries.single,
        const DailyDecisionCount(
          packageName: 'com.foo',
          dateKey: '2026-09-05',
          yesCount: 2,
          noCount: 1,
        ),
      );
    });
  });
}
