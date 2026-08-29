import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miruna/domain/watched_app.dart';
import 'package:miruna/features/common/app_icon.dart';
import 'package:miruna/platform/installed_app.dart';
import 'package:miruna/providers.dart';

class AddAppScreen extends ConsumerStatefulWidget {
  const AddAppScreen({super.key});

  @override
  ConsumerState<AddAppScreen> createState() => _AddAppScreenState();
}

class _AddAppScreenState extends ConsumerState<AddAppScreen> {
  final _query = TextEditingController();
  late final Future<List<InstalledApp>> _appsFuture;

  @override
  void initState() {
    super.initState();
    _appsFuture = ref.read(appMonitorProvider).listInstalledApps();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(monitorControllerProvider).value;
    final watched = {
      for (final app in snapshot?.apps ?? const <WatchedApp>[]) app.packageName,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('アプリを追加')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _query,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'アプリ名で検索',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<InstalledApp>>(
              future: _appsFuture,
              builder: (context, result) {
                if (result.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (result.hasError) {
                  return Center(child: Text('アプリ一覧を取得できませんでした: ${result.error}'));
                }
                final q = _query.text.trim().toLowerCase();
                final apps = (result.data ?? const <InstalledApp>[])
                    .where(
                      (app) =>
                          q.isEmpty || app.label.toLowerCase().contains(q),
                    )
                    .toList();
                if (apps.isEmpty) {
                  return const Center(child: Text('該当するアプリがありません'));
                }
                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    final already = watched.contains(app.packageName);
                    return ListTile(
                      leading: AppIconImage(bytes: app.iconBytes),
                      title: Text(app.label),
                      subtitle: Text(app.packageName),
                      trailing: already ? const Text('追加済み') : const Icon(Icons.add),
                      onTap: already
                          ? null
                          : () async {
                              final period =
                                  snapshot?.defaultWarningPeriod ??
                                  const Duration(hours: 1);
                              await ref
                                  .read(monitorControllerProvider.notifier)
                                  .upsert(
                                    WatchedApp(
                                      packageName: app.packageName,
                                      displayName: app.label,
                                      warningPeriod: period,
                                    ),
                                  );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
