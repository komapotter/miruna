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
        '今日は3回見てしまいました',
      );
      expect(DecisionCounts.formatTodayOpenMessage(-1), '');
    });

    test('builds a Monday-Sunday week chart series with empty buckets filled', () {
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
          ('2026-08-31', 1, 2),
          ('2026-09-01', 0, 0),
          ('2026-09-02', 0, 0),
          ('2026-09-03', 0, 0),
          ('2026-09-04', 0, 0),
          ('2026-09-05', 2, 1),
          ('2026-09-06', 0, 0),
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

    test('sums yes and no for a stacked bar height', () {
      expect(
        const PeriodDecisionCount(
          packageName: 'com.foo',
          period: DecisionPeriod.day,
          periodKey: '2026-09-05',
          yesCount: 2,
          noCount: 3,
        ).totalCount,
        5,
      );
    });

    test('formats chart axis labels', () {
      expect(
        DecisionCounts.formatPeriodLabel(DecisionPeriod.day, '2026-09-05'),
        '土',
      );
      expect(
        DecisionCounts.formatWeekdayLabel('2026-08-31'),
        '月',
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

    test('formats the aggregation range for the visible chart window', () {
      expect(
        DecisionCounts.formatAggregationRange(
          period: DecisionPeriod.day,
          periodKeys: DecisionCounts.chartPeriodKeys(
            period: DecisionPeriod.day,
            now: day,
          ),
        ),
        '8月31日～9月6日',
      );
      expect(
        DecisionCounts.formatAggregationRange(
          period: DecisionPeriod.day,
          periodKeys: const ['2025-12-29', '2026-01-04'],
        ),
        '2025年12月29日～2026年1月4日',
      );
      expect(
        DecisionCounts.formatAggregationRange(
          period: DecisionPeriod.month,
          periodKeys: const ['2025-10', '2026-09'],
        ),
        '2025年10月～2026年9月',
      );
      expect(
        DecisionCounts.formatAggregationRange(
          period: DecisionPeriod.year,
          periodKeys: const ['2026'],
        ),
        '2026年',
      );
    });

    test('formats look/skip averages over the aggregation window', () {
      expect(
        DecisionCounts.formatAverageCounts(
          period: DecisionPeriod.day,
          yesTotal: 2,
          noTotal: 1,
          bucketCount: 7,
        ),
        '見る 0.3回 · 見ない 0.1回 (1日平均)',
      );
      expect(
        DecisionCounts.formatAverageCounts(
          period: DecisionPeriod.month,
          yesTotal: 3,
          noTotal: 3,
          bucketCount: 12,
        ),
        '見る 0.3回 · 見ない 0.3回 (1か月平均)',
      );
      expect(
        DecisionCounts.formatAverageCounts(
          period: DecisionPeriod.year,
          yesTotal: 3,
          noTotal: 3,
          bucketCount: 1,
        ),
        '見る 3回 · 見ない 3回 (1年平均)',
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
