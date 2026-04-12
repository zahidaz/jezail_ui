import 'dart:convert';
import 'dart:typed_data';

class PackageInfo {
  final String packageName;
  final String name;
  final String iconBase64;
  final bool isRunning;
  final bool canLaunch;
  final bool isSystemApp;
  final bool isUpdatedSystemApp;
  final String? version;
  final bool? isDebuggable;

  PackageInfo({
    required this.packageName,
    required this.name,
    required this.iconBase64,
    required this.isRunning,
    required this.canLaunch,
    required this.isSystemApp,
    required this.isUpdatedSystemApp,
    this.version,
    this.isDebuggable,
  });

  late final Uint8List? iconBytes = _decodeIcon();

  Uint8List? _decodeIcon() {
    if (iconBase64.isEmpty) return null;
    try {
      final data = iconBase64.contains(',')
          ? iconBase64.split(',').last
          : iconBase64;
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }

  PackageInfo copyWith({
    String? packageName,
    String? name,
    String? iconBase64,
    bool? isRunning,
    bool? canLaunch,
    bool? isSystemApp,
    bool? isUpdatedSystemApp,
    String? version,
    bool? isDebuggable,
  }) {
    return PackageInfo(
      packageName: packageName ?? this.packageName,
      name: name ?? this.name,
      iconBase64: iconBase64 ?? this.iconBase64,
      isRunning: isRunning ?? this.isRunning,
      canLaunch: canLaunch ?? this.canLaunch,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isUpdatedSystemApp: isUpdatedSystemApp ?? this.isUpdatedSystemApp,
      version: version ?? this.version,
      isDebuggable: isDebuggable ?? this.isDebuggable,
    );
  }

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      packageName: json['packageName'] ?? '',
      name: json['name'] ?? '',
      iconBase64: json['icon'] ?? '',
      isRunning: json['isRunning'] ?? false,
      canLaunch: json['canLaunch'] ?? true,
      isSystemApp: json['isSystemApp'] ?? false,
      isUpdatedSystemApp: json['isUpdatedSystemApp'] ?? false,
      version: json['version'],
      isDebuggable: json['isDebuggable'],
    );
  }
}

