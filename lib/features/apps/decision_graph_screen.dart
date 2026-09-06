import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miruna/domain/decision_counts.dart';
import 'package:miruna/providers.dart';

class DecisionGraphScreen extends ConsumerStatefulWidget {
  const DecisionGraphScreen({
    super.key,
    required this.packageName,
    required this.displayName,
    this.now,
  });

  final String packageName;
  final String displayName;
  final DateTime? now;

  @override
  ConsumerState<DecisionGraphScreen> createState() =>
      _DecisionGraphScreenState();
}

class _DecisionGraphScreenState extends ConsumerState<DecisionGraphScreen> {
  DecisionPeriod _period = DecisionPeriod.day;

  DateTime get _now => widget.now ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(decisionCountsProvider(widget.packageName));
    return Scaffold(
      appBar: AppBar(title: Text('${widget.displayName}の記録')),
      body: counts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
        data: (data) => _GraphBody(
          counts: data,
          period: _period,
          now: _now,
          packageName: widget.packageName,
          onPeriodChanged: (period) => setState(() => _period = period),
          onRefresh: () =>
              ref.refresh(decisionCountsProvider(widget.packageName).future),
        ),
      ),
    );
  }
}

class _GraphBody extends StatelessWidget {
  const _GraphBody({
    required this.counts,
    required this.period,
    required this.now,
    required this.packageName,
    required this.onPeriodChanged,
    required this.onRefresh,
  });

  final DecisionCounts counts;
  final DecisionPeriod period;
  final DateTime now;
  final String packageName;
  final ValueChanged<DecisionPeriod> onPeriodChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final series = counts.chartSeries(
      period: period,
      now: now,
      packageName: packageName,
    );
    final yesTotal = series.fold<int>(0, (sum, item) => sum + item.yesCount);
    final noTotal = series.fold<int>(0, (sum, item) => sum + item.noCount);
    final hasVisibleCounts = series.any(
      (item) => item.yesCount > 0 || item.noCount > 0,
    );
    final rangeLabel = DecisionCounts.formatAggregationRange(
      period: period,
      periodKeys: [for (final item in series) item.periodKey],
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SegmentedButton<DecisionPeriod>(
            segments: const [
              ButtonSegment(value: DecisionPeriod.day, label: Text('週')),
              ButtonSegment(value: DecisionPeriod.month, label: Text('月')),
              ButtonSegment(value: DecisionPeriod.year, label: Text('年')),
            ],
            selected: {period},
            onSelectionChanged: (selected) => onPeriodChanged(selected.first),
          ),
          const SizedBox(height: 16),
          Text(rangeLabel, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (!counts.hasDecisions)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: Text('まだ記録がありません')),
            )
          else if (!hasVisibleCounts)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: Text('この期間の記録はありません')),
            )
          else ...[
            Text(
              'はい $yesTotal回 · いいえ $noTotal回',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const _Legend(),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: DecisionBarChart(series: series),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _LegendSwatch(color: DecisionBarChart.yesColor, label: 'はい'),
        SizedBox(width: 16),
        _LegendSwatch(color: DecisionBarChart.noColor, label: 'いいえ'),
      ],
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class DecisionBarChart extends StatelessWidget {
  const DecisionBarChart({super.key, required this.series});

  static const yesColor = Color(0xFFB91C1C);
  static const noColor = Color(0xFF6B7280);

  final List<PeriodDecisionCount> series;

  /// Tallest stacked bar: yes + no in the same period.
  static int maxStackedCount(List<PeriodDecisionCount> series) {
    return series.fold<int>(0, (max, item) {
      final total = item.totalCount;
      return total > max ? total : max;
    });
  }

  /// Right-side gauge ticks: max, 2/3, 1/3, and 0 (deduped, high to low).
  static List<int> gaugeValues(int maxCount) {
    if (maxCount <= 0) return const [0];
    if (maxCount == 1) return const [1, 0];
    final twoThirds = (maxCount * 2 / 3).round();
    final oneThird = (maxCount / 3).round();
    return {maxCount, twoThirds, oneThird, 0}.toList()
      ..sort((a, b) => b.compareTo(a));
  }

  static String formatGaugeLabel(int value) {
    if (value.abs() < 1000) return '$value';
    final sign = value < 0 ? '-' : '';
    final digits = value.abs().toString();
    final buffer = StringBuffer(sign);
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = maxStackedCount(series);
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Semantics(
      label: series
          .map(
            (item) =>
                '${DecisionCounts.formatPeriodLabel(item.period, item.periodKey)} はい${item.yesCount} いいえ${item.noCount}',
          )
          .join('、'),
      child: CustomPaint(
        painter: _DecisionBarPainter(
          series: series,
          maxCount: maxCount,
          fontFamily: fontFamily,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DecisionBarPainter extends CustomPainter {
  _DecisionBarPainter({
    required this.series,
    required this.maxCount,
    this.fontFamily,
  });

  final List<PeriodDecisionCount> series;
  final int maxCount;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    const labelHeight = 22.0;
    const topPad = 12.0;
    const gaugeGap = 8.0;
    final chartHeight = size.height - labelHeight - topPad;
    if (chartHeight <= 0) return;

    final ticks = DecisionBarChart.gaugeValues(maxCount);
    final gaugePainters = <int, TextPainter>{};
    var gaugeWidth = 0.0;
    for (final tick in ticks) {
      final painter = TextPainter(
        text: TextSpan(
          text: DecisionBarChart.formatGaugeLabel(tick),
          style: TextStyle(
            color: tick == ticks.first
                ? const Color(0xFFE5E7EB)
                : const Color(0xFF9CA3AF),
            fontSize: 10,
            fontFamily: fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      gaugePainters[tick] = painter;
      if (painter.width > gaugeWidth) {
        gaugeWidth = painter.width;
      }
    }

    final chartWidth = (size.width - gaugeWidth - gaugeGap).clamp(0.0, size.width);
    if (chartWidth <= 0) return;
    final groupWidth = chartWidth / series.length;
    final barWidth = (groupWidth * 0.45).clamp(6.0, 22.0);
    final baseline = topPad + chartHeight;
    final scale = maxCount == 0 ? 0.0 : chartHeight / maxCount;
    final gridPaint = Paint()
      ..color = const Color(0xFF3F2A2A)
      ..strokeWidth = 1;

    for (final tick in ticks) {
      final y = baseline - tick * scale;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
      final painter = gaugePainters[tick]!;
      var labelY = y - painter.height / 2;
      if (labelY < 0) {
        labelY = 0;
      }
      if (labelY + painter.height > baseline) {
        labelY = baseline - painter.height;
      }
      painter.paint(canvas, Offset(chartWidth + gaugeGap, labelY));
    }

    final labelStyle = TextStyle(
      color: const Color(0xFF9CA3AF),
      fontSize: series.length > 10 ? 10 : 11,
      fontFamily: fontFamily,
    );

    for (var i = 0; i < series.length; i++) {
      final item = series[i];
      final center = (i + 0.5) * groupWidth;
      _drawStackedBar(
        canvas,
        left: center - barWidth / 2,
        baseline: baseline,
        width: barWidth,
        yesHeight: item.yesCount * scale,
        noHeight: item.noCount * scale,
      );
      final label = DecisionCounts.formatPeriodLabel(item.period, item.periodKey);
      final painter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: groupWidth);
      painter.paint(
        canvas,
        Offset(center - painter.width / 2, baseline + 4),
      );
    }
  }

  void _drawStackedBar(
    Canvas canvas, {
    required double left,
    required double baseline,
    required double width,
    required double yesHeight,
    required double noHeight,
  }) {
    const radius = Radius.circular(3);
    if (yesHeight > 0) {
      final yesRect = Rect.fromLTWH(
        left,
        baseline - yesHeight,
        width,
        yesHeight,
      );
      canvas.drawRRect(
        noHeight > 0
            ? RRect.fromRectAndCorners(
                yesRect,
                bottomLeft: radius,
                bottomRight: radius,
              )
            : RRect.fromRectAndRadius(yesRect, radius),
        Paint()..color = DecisionBarChart.yesColor,
      );
    }
    if (noHeight > 0) {
      final noRect = Rect.fromLTWH(
        left,
        baseline - yesHeight - noHeight,
        width,
        noHeight,
      );
      canvas.drawRRect(
        yesHeight > 0
            ? RRect.fromRectAndCorners(
                noRect,
                topLeft: radius,
                topRight: radius,
              )
            : RRect.fromRectAndRadius(noRect, radius),
        Paint()..color = DecisionBarChart.noColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DecisionBarPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.maxCount != maxCount ||
        oldDelegate.fontFamily != fontFamily;
  }
}
