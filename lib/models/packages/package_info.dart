
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

