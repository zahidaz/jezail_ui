import 'package:flutter/material.dart';
import 'package:jezail_ui/services/service_registry.dart';
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/repositories/package_repository.dart';
import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/repositories/processes_repository.dart';
import 'package:jezail_ui/repositories/logs_repository.dart';
import 'package:jezail_ui/repositories/controls_repository.dart';
import 'package:jezail_ui/repositories/adb_repository.dart';
import 'package:jezail_ui/repositories/frida_repository.dart';
import 'package:jezail_ui/repositories/cert_repository.dart';
import 'package:jezail_ui/presentation/tabs/packages/packages_tab.dart';
import 'package:jezail_ui/presentation/tabs/files/files_tab.dart';
import 'package:jezail_ui/presentation/tabs/device/device_tab.dart';
import 'package:jezail_ui/presentation/tabs/processes/processes_tab.dart';
import 'package:jezail_ui/presentation/tabs/logs/logs_tab.dart';
import 'package:jezail_ui/presentation/tabs/controls/controls_tab.dart';
import 'package:jezail_ui/presentation/tabs/adb/adb_tool.dart';
import 'package:jezail_ui/presentation/tabs/frida/frida_tool.dart';
import 'package:jezail_ui/presentation/tabs/certs/certs_tab.dart';
import 'package:jezail_ui/presentation/tabs/settings/settings_tab.dart';
import 'package:jezail_ui/presentation/tabs/about/about_tab.dart';

class TabInfo {
  final String title;
  final String path;
  final IconData icon;
  final Widget Function(ServiceRegistry, {Key? key, ValueNotifier<bool>? isActiveNotifier}) builder;
  final bool hasSubroutes;

  const TabInfo({
    required this.title,
    required this.path,
    required this.icon,
    required this.builder,
    this.hasSubroutes = false,
  });
}

final tabsConfig = [
  TabInfo(
    title: 'Device',
    path: '/device',
    icon: Icons.phone_android,
    builder: (services, {Key? key, ValueNotifier<bool>? isActiveNotifier}) =>
        DeviceTab(key: key, repository: DeviceRepository(services.device), isActiveNotifier: isActiveNotifier),
  ),
  TabInfo(
    title: 'Packages',
    path: '/packages',
    icon: Icons.inventory_2,
    builder: (services, {Key? key, ValueNotifier<bool>? isActiveNotifier}) => PackagesTab(
      key: key,
      packageRepository: PackageRepository(services.packages),
      deviceService: services.device,
    ),
    hasSubroutes: true,
  ),
  TabInfo(
    title: 'Files',
    path: '/files',
    icon: Icons.folder_open,
    builder: (services, {Key? key, ValueNotifier<bool>? isActiveNotifier}) =>
        FilesTab(key: key, repository: FileRepository(services.files)),
  ),
  TabInfo(
    title: 'Processes',
    path: '/processes',
    icon: Icons.list,
    builder: (services, {Key? key, ValueNotifier<bool>? isActiveNotifier}) => ProcessesTab(
      key: key,
      repository: ProcessesRepository(services.device),
    ),
  ),
  TabInfo(
    title: 'Logs',
    path: '/logs',
    icon: Icons.article,
    builder: (services, {Key? key, ValueNotifier<bool>? isActiveNotifier}) =>
        LogsTab(key: key, repository: LogsRepository(services.device)),
  ),
  TabInfo(
    title: 'Frida',
    path: '/frida',
    icon: Icons.api,
    builder: (services, {Key? key, ValueNotifier<bool>? isActiveNotifier}) =>
        FridaTab(key: key, repository: FridaRepository(services.frida)),
  ),
  TabInfo(
    title: 'ADB',
    path: '/adb',
    icon: Icons.terminal,
    builder: (services, {Key? key, ValueNotifier<bool>? isActiveNotifier}) =>
        AdbTab(key: key, repository: AdbRepository(services.adb)),
  ),
  TabInfo(
    title: 'Certificates',
    path: '/certs',
    icon: Icons.verified_user,
    builder: (services, {Key? key, ValueNotifier<bool>? isActiveNotifier}) =>
        CertsTab(key: key, repository: CertRepository(services.certs)),
  ),
  TabInfo(
    title: 'Controls',
    path: '/controls',
    icon: Icons.gamepad,
    builder: (services, {Key? key, ValueNotifier<bool>? isActiveNotifier}) =>
        ControlsTab(key: key, repository: ControlsRepository(services.device)),
  ),
  TabInfo(
    title: 'Settings',
    path: '/settings',
    icon: Icons.settings,
    builder: (services, {Key? key, ValueNotifier<bool>? isActiveNotifier}) => SettingsTab(key: key, apiService: services.api),
  ),
  TabInfo(
    title: 'About',
    path: '/about',
    icon: Icons.info,
    builder: (_, {Key? key, ValueNotifier<bool>? isActiveNotifier}) => AboutTab(key: key),
  ),
];
