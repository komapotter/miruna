import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miruna/domain/cooldown.dart';
import 'package:miruna/domain/duration_format.dart';
import 'package:miruna/domain/watched_app.dart';
import 'package:miruna/features/apps/decision_graph_screen.dart';
import 'package:miruna/features/common/period_picker.dart';
import 'package:miruna/providers.dart';

class AppEditScreen extends ConsumerStatefulWidget {
  const AppEditScreen({super.key, required this.app});

  final WatchedApp app;

  @override
  ConsumerState<AppEditScreen> createState() => _AppEditScreenState();
}

class _AppEditScreenState extends ConsumerState<AppEditScreen> {
  late bool _enabled = widget.app.enabled;
  late Duration _period = widget.app.warningPeriod;
  late Duration _cooldownPeriod = widget.app.cooldownPeriod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.app.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('このアプリを監視する'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          const SizedBox(height: 8),
          Text(
            '警告期間（現在 ${formatWarningPeriod(_period)}）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          PeriodPicker(
            value: _period,
            onChanged: (value) => setState(() => _period = value),
          ),
          const SizedBox(height: 24),
          Text(
            'クールダウン期間（現在 ${formatWarningPeriod(_cooldownPeriod)}）',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '「見る」で解除した時点から数えます。この時間が過ぎるまでは、閉じて開き直しても警告しません。なし（0）で無効です。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          PeriodPicker(
            value: _cooldownPeriod,
            onChanged: (value) => setState(() => _cooldownPeriod = value),
            presets: Cooldown.cooldownPresets,
            dialogTitle: 'クールダウン期間',
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('見てしまった回数'),
            subtitle: const Text('見る / 見ないの回数を年・月・日で表示します'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DecisionGraphScreen(
                    packageName: widget.app.packageName,
                    displayName: widget.app.displayName,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await ref.read(monitorControllerProvider.notifier).upsert(
                    widget.app.copyWith(
                      enabled: _enabled,
                      warningPeriod: _period,
                      cooldownPeriod: _cooldownPeriod,
                    ),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await ref
                  .read(monitorControllerProvider.notifier)
                  .remove(widget.app.packageName);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('監視から外す'),
          ),
        ],
      ),
    );
  }
}
