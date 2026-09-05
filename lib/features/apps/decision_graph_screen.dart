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

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SegmentedButton<DecisionPeriod>(
            segments: const [
              ButtonSegment(value: DecisionPeriod.day, label: Text('日')),
              ButtonSegment(value: DecisionPeriod.month, label: Text('月')),
              ButtonSegment(value: DecisionPeriod.year, label: Text('年')),
            ],
            selected: {period},
            onSelectionChanged: (selected) => onPeriodChanged(selected.first),
          ),
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

  static const yesColor = Color(0xFF0F766E);
  static const noColor = Color(0xFF2563EB);

  final List<PeriodDecisionCount> series;

  @override
  Widget build(BuildContext context) {
    final maxCount = series.fold<int>(0, (max, item) {
      final taller = item.yesCount > item.noCount ? item.yesCount : item.noCount;
      return taller > max ? taller : max;
    });
    return Semantics(
      label: series
          .map(
            (item) =>
                '${DecisionCounts.formatPeriodLabel(item.period, item.periodKey)} はい${item.yesCount} いいえ${item.noCount}',
          )
          .join('、'),
      child: CustomPaint(
        painter: _DecisionBarPainter(series: series, maxCount: maxCount),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DecisionBarPainter extends CustomPainter {
  _DecisionBarPainter({required this.series, required this.maxCount});

  final List<PeriodDecisionCount> series;
  final int maxCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    const labelHeight = 22.0;
    const topPad = 8.0;
    final chartHeight = size.height - labelHeight - topPad;
    if (chartHeight <= 0) return;
    final groupWidth = size.width / series.length;
    final barWidth = (groupWidth * 0.28).clamp(4.0, 16.0);
    final gap = 3.0;
    final baseline = topPad + chartHeight;
    final scale = maxCount == 0 ? 0.0 : chartHeight / maxCount;
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), gridPaint);

    final labelStyle = TextStyle(
      color: const Color(0xFF64748B),
      fontSize: series.length > 10 ? 10 : 11,
    );

    for (var i = 0; i < series.length; i++) {
      final item = series[i];
      final center = (i + 0.5) * groupWidth;
      _drawBar(
        canvas,
        offset: Offset(center - barWidth - gap / 2, baseline),
        width: barWidth,
        height: item.yesCount * scale,
        color: DecisionBarChart.yesColor,
      );
      _drawBar(
        canvas,
        offset: Offset(center + gap / 2, baseline),
        width: barWidth,
        height: item.noCount * scale,
        color: DecisionBarChart.noColor,
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

  void _drawBar(
    Canvas canvas, {
    required Offset offset,
    required double width,
    required double height,
    required Color color,
  }) {
    if (height <= 0) return;
    final rect = Rect.fromLTWH(offset.dx, offset.dy - height, width, height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _DecisionBarPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.maxCount != maxCount;
  }
}
