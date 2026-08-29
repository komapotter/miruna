import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miruna/domain/duration_format.dart';
import 'package:miruna/features/common/period_picker.dart';
import 'package:miruna/features/onboarding/onboarding_screen.dart';
import 'package:miruna/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(monitorControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(monitorControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
        data: (data) {
          final p = data.permissions;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'デフォルトの警告期間（${formatWarningPeriod(data.defaultWarningPeriod)}）',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              PeriodPicker(
                value: data.defaultWarningPeriod,
                onChanged: (period) {
                  ref
                      .read(monitorControllerProvider.notifier)
                      .setDefaultWarningPeriod(period);
                },
              ),
              const SizedBox(height: 24),
              Text('権限', style: Theme.of(context).textTheme.titleMedium),
              if (!p.supportsMonitoring)
                const ListTile(
                  leading: Icon(Icons.block),
                  title: Text('この端末では監視できません'),
                  subtitle: Text('監視機能は Android でのみ利用できます。'),
                )
              else ...[
                _StatusTile(
                  title: '使用状況へのアクセス',
                  granted: p.usageAccess,
                  onTap: () =>
                      ref.read(appMonitorProvider).openSettings('usageAccess'),
                ),
                _StatusTile(
                  title: '他のアプリの上に表示',
                  granted: p.overlay,
                  onTap: () =>
                      ref.read(appMonitorProvider).openSettings('overlay'),
                ),
                _StatusTile(
                  title: '通知',
                  granted: p.notifications,
                  onTap: () =>
                      ref.read(appMonitorProvider).requestNotifications(),
                ),
                _StatusTile(
                  title: 'ユーザー補助',
                  granted: p.accessibility,
                  onTap: () =>
                      ref.read(appMonitorProvider).openSettings('accessibility'),
                ),
                _StatusTile(
                  title: '電池の最適化から除外',
                  granted: p.batteryUnrestricted,
                  onTap: () =>
                      ref.read(appMonitorProvider).openSettings('battery'),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OnboardingScreen(),
                    ),
                  );
                },
                child: const Text('セットアップ画面を開く'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.title,
    required this.granted,
    required this.onTap,
  });

  final String title;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(granted ? '許可済み' : '未許可'),
      trailing: granted
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : TextButton(onPressed: onTap, child: const Text('設定')),
    );
  }
}
