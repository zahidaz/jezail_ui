import 'package:jezail_ui/services/device_service.dart';
import 'package:jezail_ui/models/device/process_info.dart';
import 'package:jezail_ui/core/enums/device_enums.dart';

class DeviceRepository {
  const DeviceRepository(this._deviceService);

  final DeviceService _deviceService;

  Future<Map<String, dynamic>> getDeviceInfo() async => await _deviceService.getDeviceInfo();
  Future<Map<String, dynamic>> getBuildInfo() async => await _deviceService.getBuildInfo();
  Future<Map<String, dynamic>> getBatteryInfo() async => await _deviceService.getBattery();
  Future<Map<String, dynamic>> getCpuInfo() async => await _deviceService.getCpu();
  Future<Map<String, dynamic>> getRamInfo() async => await _deviceService.getRam();
  Future<Map<String, dynamic>> getStorageInfo() async => await _deviceService.getStorage();
  Future<Map<String, dynamic>> getStorageDetails() async => await _deviceService.getStorageDetails();
  Future<Map<String, dynamic>> getNetworkInfo() async => await _deviceService.getNetwork();
  Future<Map<String, dynamic>> getSelinuxStatus() async => await _deviceService.getSelinuxStatus();
  Future<void> toggleSelinux(bool enable) => _deviceService.toggleSelinux(enable);
  Future<Map<String, dynamic>> getSystemProperties() async => await _deviceService.getSystemProperties();

  Future<String> getSystemProperty(String key) async {
    final result = await _deviceService.getSystemProperty(key);
    return result['value'] as String;
  }

  Future<void> setSystemProperty(String key, String value) => 
      _deviceService.setSystemProperty(key, value);

  Future<List<ProcessInfo>> getProcesses() async {
    final result = await _deviceService.listProcesses();
    final processes = List<Map<String, dynamic>>.from(result['data'] ?? []);
    return processes.map(ProcessInfo.fromJson).toList();
  }

  Future<Map<String, dynamic>> getProcessInfo(int pid) async => await _deviceService.getProcess(pid);
  Future<void> killProcess(int pid) => _deviceService.killProcessByPid(pid);
  Future<void> killProcessByName(String name) => _deviceService.killProcessByName(name);

  Future<List<String>> getLogs(LogType logType, {String? filter}) async {
    final result = await switch (logType) {
      LogType.main => _deviceService.getAllLogs(),
      LogType.system => _deviceService.getSystemLogs(),
      LogType.kernel => _deviceService.getKernelLogs(),
      LogType.radio => _deviceService.getRadioLogs(),
      LogType.crash => _deviceService.getCrashLogs(),
      LogType.events => _deviceService.getEventLogs(),
    };
    return List<String>.from(result['data'] ?? []);
  }

  Future<void> clearLogs() => _deviceService.clearLogs();
  Future<String?> getClipboard() => _deviceService.getClipboard();
  Future<void> setClipboard(String text) => _deviceService.setClipboard(text);
  Future<void> clearClipboard() => _deviceService.clearClipboard();

  Future<void> pressHome() => _deviceService.pressHome();
  Future<void> pressBack() => _deviceService.pressBack();
  Future<void> pressMenu() => _deviceService.pressMenu();
  Future<void> pressRecentApps() => _deviceService.pressRecentApps();
  Future<void> pressPower() => _deviceService.pressPower();
  Future<void> pressVolumeUp() => _deviceService.pressVolumeUp();
  Future<void> pressVolumeDown() => _deviceService.pressVolumeDown();
  Future<void> muteVolume() => _deviceService.muteVolume();
  Future<void> unmuteVolume() => _deviceService.unmuteVolume();
  Future<void> keycode(int code) => _deviceService.keycode(code);

  Future<void> downloadScreenshot() => _deviceService.downloadScreenshot();
}