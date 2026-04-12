import 'package:jezail_ui/services/device_service.dart';

class DeviceRepository {
  const DeviceRepository(this._deviceService);

  final DeviceService _deviceService;

  Future<dynamic> getDeviceInfo() => _deviceService.getDeviceInfo();
  Future<dynamic> getBuildInfo() => _deviceService.getBuildInfo();
  Future<dynamic> getBatteryInfo() => _deviceService.getBattery();
  Future<dynamic> getCpuInfo() => _deviceService.getCpu();
  Future<dynamic> getRamInfo() => _deviceService.getRam();
  Future<dynamic> getStorageInfo() => _deviceService.getStorage();
  Future<dynamic> getStorageDetails() => _deviceService.getStorageDetails();
  Future<dynamic> getNetworkInfo() => _deviceService.getNetwork();
  Future<dynamic> getSelinuxStatus() => _deviceService.getSelinuxStatus();
  Future<void> toggleSelinux(bool enable) => _deviceService.toggleSelinux(enable);
  Future<dynamic> getSystemProperties() => _deviceService.getSystemProperties();
  Future<dynamic> getEnvironmentVariables() => _deviceService.getEnvironmentVariables();

  void downloadScreenshot() => _deviceService.downloadScreenshot();
}
