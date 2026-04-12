import 'dart:typed_data';
import 'package:jezail_ui/models/packages/package_info.dart';
import 'package:jezail_ui/services/package_service.dart';

class PackageRepository {
  final PackageService _packageService;

  PackageRepository(this._packageService);

  Future<List<PackageInfo>> getAllPackages() async {
    final response = await _packageService.getAllPackages();
    final List<dynamic> packagesList = response['data'] ?? [];

    final packages = packagesList
        .map((json) => PackageInfo.fromJson(json as Map<String, dynamic>))
        .toList();

    final uniquePackages = <String, PackageInfo>{};
    for (final package in packages) {
      uniquePackages[package.packageName] = package;
    }

    return uniquePackages.values.toList();
  }

  Future<void> launchPackage(String packageName) =>
      _packageService.launchPackage(packageName);

  Future<void> stopPackage(String packageName) =>
      _packageService.stopPackage(packageName);

  Future<dynamic> getPackageDetails(String packageName) =>
      _packageService.getPackageDetails(packageName);

  Future<dynamic> getAllPermissions(String packageName) =>
      _packageService.getAllPackagePermissions(packageName);

  Future<dynamic> getPackageSignatures(String packageName) =>
      _packageService.getPackageSignatures(packageName);

  Future<bool> isPackageDebuggable(String packageName) async {
    final result = await _packageService.isPackageDebuggable(packageName);
    return result['debuggable'] ?? false;
  }

  Future<bool> isPackageRunning(String packageName) async {
    final result = await _packageService.isPackageRunning(packageName);
    return result['data']?['running'] ?? false;
  }

  Future<dynamic> getPackageProcessInfo(String packageName) =>
      _packageService.getPackageProcessInfo(packageName);

  Future<void> installApk(Uint8List apkBytes) =>
      _packageService.installApk(apkBytes);

  Future<void> uninstallPackage(String packageName) =>
      _packageService.uninstallPackage(packageName);

  Future<void> grantPermission(String packageName, String permission) =>
      _packageService.grantPermission(packageName, permission);

  Future<void> revokePermission(String packageName, String permission) =>
      _packageService.revokePermission(packageName, permission);

  Future<void> clearPackageData(String packageName) =>
      _packageService.clearPackageData(packageName);

  Future<void> clearPackageCache(String packageName) =>
      _packageService.clearPackageCache(packageName);

  String getApkDownloadUrl(String packageName) =>
      _packageService.getApkDownloadUrl(packageName);

  String getBackupUrl(String packageName) =>
      _packageService.getBackupUrl(packageName);

  Future<void> bringToForeground(String packageName) =>
      _packageService.bringToForeground(packageName);
}
