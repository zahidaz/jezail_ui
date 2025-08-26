class PackageDetails {
  final String packageName;
  final String versionName;
  final int versionCode;
  final AppInfo appInfo;
  final List<Activity> activities;
  final List<Service> services;
  final List<Receiver> receivers;
  final List<Provider> providers;
  final List<String> requestedPermissions;
  final List<PackagePermission> permissions;
  final DateTime firstInstall;
  final DateTime lastUpdate;

  const PackageDetails({
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.appInfo,
    required this.activities,
    required this.services,
    required this.receivers,
    required this.providers,
    required this.requestedPermissions,
    required this.permissions,
    required this.firstInstall,
    required this.lastUpdate,
  });

  factory PackageDetails.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return PackageDetails(
      packageName: data['packageName'] ?? '',
      versionName: data['versionName'] ?? '',
      versionCode: data['versionCode'] ?? 0,
      appInfo: AppInfo.fromJson(data['applicationInfo'] ?? {}),
      activities: (data['activities'] as List? ?? [])
          .map((a) => Activity.fromJson(a))
          .toList(),
      services: (data['services'] as List? ?? [])
          .map((s) => Service.fromJson(s))
          .toList(),
      receivers: (data['receivers'] as List? ?? [])
          .map((r) => Receiver.fromJson(r))
          .toList(),
      providers: (data['providers'] as List? ?? [])
          .map((p) => Provider.fromJson(p))
          .toList(),
      requestedPermissions: List<String>.from(data['requestedPermissions'] ?? []),
      permissions: (data['permissions'] as List? ?? [])
          .map((p) => PackagePermission.fromJson(p))
          .toList(),
      firstInstall: DateTime.fromMillisecondsSinceEpoch(data['firstInstallTime'] ?? 0),
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(data['lastUpdateTime'] ?? 0),
    );
  }
}

class AppInfo {
  final String className;
  final String processName;
  final String sourceDir;
  final String publicSourceDir;
  final String dataDir;
  final String nativeLibraryDir;
  final int uid;
  final int targetSdk;
  final int minSdk;
  final int compileSdk;
  final bool enabled;
  final int flags;
  final int privateFlags;

  const AppInfo({
    required this.className,
    required this.processName,
    required this.sourceDir,
    required this.publicSourceDir,
    required this.dataDir,
    required this.nativeLibraryDir,
    required this.uid,
    required this.targetSdk,
    required this.minSdk,
    required this.compileSdk,
    required this.enabled,
    required this.flags,
    required this.privateFlags,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      className: json['className'] ?? '',
      processName: json['processName'] ?? '',
      sourceDir: json['sourceDir'] ?? '',
      publicSourceDir: json['publicSourceDir'] ?? '',
      dataDir: json['dataDir'] ?? '',
      nativeLibraryDir: json['nativeLibraryDir'] ?? '',
      uid: json['uid'] ?? 0,
      targetSdk: json['targetSdkVersion'] ?? 0,
      minSdk: json['minSdkVersion'] ?? 0,
      compileSdk: json['compileSdkVersion'] ?? 0,
      enabled: json['enabled'] ?? true,
      flags: json['flags'] ?? 0,
      privateFlags: json['privateFlags'] ?? 0,
    );
  }
}

class Activity {
  final String name;
  final String processName;
  final bool exported;
  final bool enabled;
  final String? permission;
  final int launchMode;
  final String taskAffinity;

  const Activity({
    required this.name,
    required this.processName,
    required this.exported,
    required this.enabled,
    this.permission,
    required this.launchMode,
    required this.taskAffinity,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      name: json['name'] ?? '',
      processName: json['processName'] ?? '',
      exported: json['exported'] ?? false,
      enabled: json['enabled'] ?? true,
      permission: json['permission'],
      launchMode: json['launchMode'] ?? 0,
      taskAffinity: json['taskAffinity'] ?? '',
    );
  }
}

class Service {
  final String name;
  final String processName;
  final bool exported;
  final bool enabled;
  final String? permission;

  const Service({
    required this.name,
    required this.processName,
    required this.exported,
    required this.enabled,
    this.permission,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      name: json['name'] ?? '',
      processName: json['processName'] ?? '',
      exported: json['exported'] ?? false,
      enabled: json['enabled'] ?? true,
      permission: json['permission'],
    );
  }
}

class Receiver {
  final String name;
  final String processName;
  final bool exported;
  final bool enabled;
  final String? permission;

  const Receiver({
    required this.name,
    required this.processName,
    required this.exported,
    required this.enabled,
    this.permission,
  });

  factory Receiver.fromJson(Map<String, dynamic> json) {
    return Receiver(
      name: json['name'] ?? '',
      processName: json['processName'] ?? '',
      exported: json['exported'] ?? false,
      enabled: json['enabled'] ?? true,
      permission: json['permission'],
    );
  }
}

class Provider {
  final String name;
  final String processName;
  final String authority;
  final bool exported;
  final bool enabled;
  final bool grantUriPermissions;

  const Provider({
    required this.name,
    required this.processName,
    required this.authority,
    required this.exported,
    required this.enabled,
    required this.grantUriPermissions,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      name: json['name'] ?? '',
      processName: json['processName'] ?? '',
      authority: json['authority'] ?? '',
      exported: json['exported'] ?? false,
      enabled: json['enabled'] ?? true,
      grantUriPermissions: json['grantUriPermissions'] ?? false,
    );
  }
}

class PackagePermission {
  final String name;
  final int protectionLevel;
  final String? description;

  const PackagePermission({
    required this.name,
    required this.protectionLevel,
    this.description,
  });

  factory PackagePermission.fromJson(Map<String, dynamic> json) {
    return PackagePermission(
      name: json['name'] ?? '',
      protectionLevel: json['protectionLevel'] ?? 0,
      description: json['description'],
    );
  }
}

class Permissions {
  final List<String> all;
  final List<String> granted;
  final List<String> denied;

  const Permissions({
    required this.all,
    required this.granted,
    required this.denied,
  });

  factory Permissions.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return Permissions(
      all: List<String>.from(data['all'] ?? []),
      granted: List<String>.from(data['granted'] ?? []),
      denied: List<String>.from(data['denied'] ?? []),
    );
  }
}

class Signature {
  final String md5;
  final String sha1;
  final String sha256;
  final String subject;
  final String issuer;
  final String serialNumber;
  final String notBefore;
  final String notAfter;
  final String algorithm;
  final String version;

  const Signature({
    required this.md5,
    required this.sha1,
    required this.sha256,
    required this.subject,
    required this.issuer,
    required this.serialNumber,
    required this.notBefore,
    required this.notAfter,
    required this.algorithm,
    required this.version,
  });

  factory Signature.fromJson(Map<String, dynamic> json) {
    return Signature(
      md5: json['md5'] ?? '',
      sha1: json['sha1'] ?? '',
      sha256: json['sha256'] ?? '',
      subject: json['subject'] ?? '',
      issuer: json['issuer'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      notBefore: json['notBefore'] ?? '',
      notAfter: json['notAfter'] ?? '',
      algorithm: json['algorithm'] ?? '',
      version: json['version'] ?? '',
    );
  }

  bool get isDebugCert => subject.contains('Android Debug');
}

class Signatures {
  final String packageName;
  final List<Signature> signatures;
  final int count;

  const Signatures({
    required this.packageName,
    required this.signatures,
    required this.count,
  });

  factory Signatures.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return Signatures(
      packageName: data['packageName'] ?? '',
      signatures: (data['signatures'] as List? ?? [])
          .map((s) => Signature.fromJson(s))
          .toList(),
      count: data['signatureCount'] ?? 0,
    );
  }

  bool get hasDebugCert => signatures.any((sig) => sig.isDebugCert);
}

class ProcessInfo {
  final bool running;
  final int? pid;
  final bool cpuStatAvailable;
  final String? vmPeak;
  final String? vmSize;
  final String? vmRss;

  const ProcessInfo({
    required this.running,
    this.pid,
    required this.cpuStatAvailable,
    this.vmPeak,
    this.vmSize,
    this.vmRss,
  });

  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return ProcessInfo(
      running: data['running'] == 'true' || data['running'] == true,
      pid: data['pid'],
      cpuStatAvailable: data['cpu_stat_available'] ?? false,
      vmPeak: data['VmPeak'],
      vmSize: data['VmSize'],
      vmRss: data['VmRSS'],
    );
  }

  String get memoryUsage {
    if (vmRss == null) return 'Unknown';
    return vmRss!.replaceAll(' kB', ' KB');
  }

  String get memoryPeak {
    if (vmPeak == null) return 'Unknown';
    return vmPeak!.replaceAll(' kB', ' KB');
  }

  String get memorySize {
    if (vmSize == null) return 'Unknown';
    return vmSize!.replaceAll(' kB', ' KB');
  }
}