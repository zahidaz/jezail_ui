import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/repositories/package_repository.dart';
import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/repositories/tool_repository.dart';
import 'package:jezail_ui/services/api_service.dart';
import 'package:jezail_ui/services/file_service.dart';
import 'package:jezail_ui/services/package_service.dart';
import 'package:jezail_ui/services/device_service.dart';
import 'package:jezail_ui/services/adb_service.dart';
import 'package:jezail_ui/services/frida_service.dart';
import 'package:jezail_ui/presentation/tabs/packages/packages_tab.dart';
import 'package:jezail_ui/presentation/tabs/files/files_tab.dart';
import 'package:jezail_ui/presentation/tabs/device/device_tab.dart';
import 'package:jezail_ui/presentation/tabs/tools/tools_tab.dart';
import 'package:jezail_ui/presentation/tabs/settings/settings_tab.dart';
import 'package:jezail_ui/presentation/tabs/about/about_tab.dart';

class TabInfo {
  final String title;
  final String path;
  final IconData icon;
  final Widget Function(ApiService) builder;

  const TabInfo({
    required this.title,
    required this.path,
    required this.icon,
    required this.builder,
  });
}

final tabsConfig = [
  TabInfo(
    title: 'Packages',
    path: '/packages',
    icon: Icons.apps,
    builder: (apiService) => PackagesTab(
      packageRepository: PackageRepository(PackageService(apiService)),
    ),
  ),
  TabInfo(
    title: 'Files',
    path: '/files',
    icon: Icons.folder,
    builder: (apiService) => FilesTab(
      repository: FileRepository(FilesService(apiService)),
    ),
  ),
  TabInfo(
    title: 'Device',
    path: '/device',
    icon: Icons.phone_android,
    builder: (apiService) => DeviceTab(
      repository: DeviceRepository(DeviceService(apiService)),
    ),
  ),
  TabInfo(
    title: 'Tools',
    path: '/tools',
    icon: Icons.build,
    builder: (apiService) => ToolsTab(
      repository: ToolRepository(AdbService(apiService), FridaService(apiService)),
    ),
  ),
  TabInfo(
    title: 'Settings',
    path: '/settings',
    icon: Icons.settings,
    builder: (_) => const SettingsTab(),
  ),
  TabInfo(
    title: 'About',
    path: '/about',
    icon: Icons.info,
    builder: (_) => const AboutTab(),
  ),
];