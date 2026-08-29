import 'dart:typed_data';

class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    this.iconBytes,
  });

  final String packageName;
  final String label;
  final Uint8List? iconBytes;

  factory InstalledApp.fromChannelMap(Map<Object?, Object?> map) {
    final icon = map['icon'];
    return InstalledApp(
      packageName: map['packageName'] as String,
      label: map['label'] as String,
      iconBytes: icon is Uint8List ? icon : null,
    );
  }
}
