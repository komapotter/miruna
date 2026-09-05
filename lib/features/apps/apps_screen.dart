import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miruna/domain/cooldown.dart';
import 'package:miruna/domain/duration_format.dart';
import 'package:miruna/domain/watched_app.dart';
import 'package:miruna/features/apps/add_app_screen.dart';
import 'package:miruna/features/apps/app_edit_screen.dart';
import 'package:miruna/features/settings/settings_screen.dart';
import 'package:miruna/providers.dart';

class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(monitorControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('見たな'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: snapshot.maybeWhen(
        data: (data) => data.permissions.supportsMonitoring
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AddAppScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
        orElse: () => null,
      ),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(monitorControllerProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              if (!data.permissions.supportsMonitoring)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('監視機能は Android でのみ利用できます'),
                    subtitle: Text('iOS では他アプリの起動に介入できないため、設定の確認のみできます。'),
                  ),
                )
              else ...[
                SwitchListTile(
                  title: const Text('監視する'),
                  subtitle: Text(
                    data.permissions.canMonitor
                        ? '対象アプリの再起動を確認します'
                        : '必要な権限が不足しています。設定から許可してください。',
                  ),
                  value: data.monitoring,
                  onChanged: (enabled) async {
                    final ok = await ref
                        .read(monitorControllerProvider.notifier)
                        .setMonitoring(enabled);
                    if (!context.mounted) return;
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('使用状況へのアクセスと、他のアプリの上に表示が必要です。'),
                        ),
                      );
                    }
                  },
                ),
                if (!data.permissions.canMonitor)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      child: const Text('権限を確認する'),
                    ),
                  ),
              ],
              if (data.apps.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text('監視するアプリを追加してください'),
                  ),
                )
              else
                for (final app in data.apps)
                  _WatchedAppTile(app: app),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchedAppTile extends ConsumerWidget {
  const _WatchedAppTile({required this.app});

  final WatchedApp app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = Cooldown.remainingCooldown(
      lastClosedAt: app.lastClosedAt,
      warningPeriod: app.warningPeriod,
      now: DateTime.now(),
    );
    return Card(
      child: ListTile(
        title: Text(app.displayName),
        subtitle: Text(
          [
            '警告期間 ${formatWarningPeriod(app.warningPeriod)}',
            if (!app.enabled) 'オフ',
            if (remaining != null) remainingLabel(remaining),
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AppEditScreen(app: app),
            ),
          );
        },
      ),
    );
  }
}
