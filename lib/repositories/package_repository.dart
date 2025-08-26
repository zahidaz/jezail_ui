import 'dart:typed_data';
import 'package:jezail_ui/models/packages/package_info.dart';

import '../services/package_service.dart';

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

  Future<void> launchPackage(String packageName) async {
    await _packageService.launchPackage(packageName);
  }

  Future<void> stopPackage(String packageName) async {
    await _packageService.stopPackage(packageName);
  }

  Future<Map<String, dynamic>> getPackageDetails(String packageName) async {
    return await _packageService.getPackageDetails(packageName);
  }

  Future<Map<String, dynamic>> getAllPermissions(String packageName) async {
    return await _packageService.getAllPackagePermissions(packageName);
  }

  Future<Map<String, dynamic>> getPackageSignatures(String packageName) async {
    return await _packageService.getPackageSignatures(packageName);
  }

  Future<bool> isPackageDebuggable(String packageName) async {
    final result = await _packageService.isPackageDebuggable(packageName);
    return result['debuggable'] ?? false;
  }

  Future<bool> isPackageRunning(String packageName) async {
    final result = await _packageService.isPackageRunning(packageName);
    return result['data']?['running'] ?? false;
  }

  Future<Map<String, dynamic>> getPackageProcessInfo(String packageName) async {
    return await _packageService.getPackageProcessInfo(packageName);
  }

  Future<void> installApk(Uint8List apkBytes) async {
    await _packageService.installApk(apkBytes);
  }

  Future<void> uninstallPackage(String packageName) async {
    await _packageService.uninstallPackage(packageName);
  }

  Future<void> grantPermission(String packageName, String permission) async {
    await _packageService.grantPermission(packageName, permission);
  }

  Future<void> revokePermission(String packageName, String permission) async {
    await _packageService.revokePermission(packageName, permission);
  }

  Future<void> clearPackageData(String packageName) async {
    await _packageService.clearPackageData(packageName);
  }

  Future<void> clearPackageCache(String packageName) async {
    await _packageService.clearPackageCache(packageName);
  }
}