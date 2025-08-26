
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

