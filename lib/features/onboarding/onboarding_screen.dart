import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miruna/platform/permission_status.dart';
import 'package:miruna/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
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
      body: SafeArea(
        child: snapshot.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
          data: (data) => _body(context, data.permissions),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, PermissionStatus permissions) {
    final monitor = ref.read(appMonitorProvider);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('ミルナ', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          '対象アプリを閉じてから警告期間内にまた開こうとすると、本当に開くか確認します。',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        if (!permissions.supportsMonitoring)
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const ListTile(
              leading: Icon(Icons.phone_iphone),
              title: Text('監視は Android でのみ利用できます'),
              subtitle: Text('iOS では設定画面だけを用意しています。他アプリの起動には介入できません。'),
            ),
          )
        else ...[
          _PermissionTile(
            title: '使用状況へのアクセス',
            subtitle: 'どのアプリが前面に出たかを知るために必要です。',
            granted: permissions.usageAccess,
            isRequired: true,
            onGrant: () => monitor.openSettings('usageAccess'),
          ),
          _PermissionTile(
            title: '他のアプリの上に表示',
            subtitle: '確認ダイアログを重ねて出すために必要です。',
            granted: permissions.overlay,
            isRequired: true,
            onGrant: () => monitor.openSettings('overlay'),
          ),
          _PermissionTile(
            title: '通知',
            subtitle: '監視サービスが動いていることを知らせます。',
            granted: permissions.notifications,
            isRequired: true,
            onGrant: () async {
              await monitor.requestNotifications();
              await Future<void>.delayed(const Duration(milliseconds: 400));
              await ref.read(monitorControllerProvider.notifier).refresh();
            },
          ),
          _PermissionTile(
            title: 'ユーザー補助',
            subtitle: '起動の検知が速くなります。画面の内容は読みません。',
            granted: permissions.accessibility,
            isRequired: false,
            onGrant: () => monitor.openSettings('accessibility'),
          ),
          _PermissionTile(
            title: '電池の最適化から除外',
            subtitle: '監視がバックグラウンドで止まりにくくなります。',
            granted: permissions.batteryUnrestricted,
            isRequired: false,
            onGrant: () => monitor.openSettings('battery'),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => _finish(permissions),
          child: Text(
            permissions.supportsMonitoring && !permissions.canMonitor
                ? '必要な権限のあとで続ける'
                : '始める',
          ),
        ),
      ],
    );
  }

  Future<void> _finish(PermissionStatus permissions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (permissions.canMonitor) {
      await ref.read(monitorControllerProvider.notifier).setMonitoring(true);
    }
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.isRequired,
    required this.onGrant,
  });

  final String title;
  final String subtitle;
  final bool granted;
  final bool isRequired;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          granted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: granted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(title),
        subtitle: Text(isRequired ? '$subtitle（必須）' : '$subtitle（推奨）'),
        trailing: granted
            ? null
            : TextButton(onPressed: onGrant, child: const Text('許可')),
      ),
    );
  }
}
