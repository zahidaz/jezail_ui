import 'dart:typed_data';
import 'package:jezail_ui/services/device_service.dart';

class ControlsRepository {
  const ControlsRepository(this._deviceService);

  final DeviceService _deviceService;

  Future<Uint8List> takeScreenshot() => _deviceService.getScreenshot();
  void downloadScreenshot() => _deviceService.downloadScreenshot();

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

  Future<String?> getClipboard() => _deviceService.getClipboard();
  Future<void> setClipboard(String text) => _deviceService.setClipboard(text);
  Future<void> clearClipboard() => _deviceService.clearClipboard();

  Future<dynamic> getSelinuxStatus() => _deviceService.getSelinuxStatus();
  Future<void> toggleSelinux(bool enable) => _deviceService.toggleSelinux(enable);

  Future<String> getSystemProperty(String key) async {
    final result = await _deviceService.getSystemProperty(key);
    final data = result['data'];
    if (data is Map) return data['value']?.toString() ?? '';
    return data?.toString() ?? '';
  }

  Future<void> setSystemProperty(String key, String value) =>
      _deviceService.setSystemProperty(key, value);

  Future<void> typeText(String text) => _deviceService.typeText(text);

  Future<Map<String, dynamic>> getDnsConfig() async {
    final result = await _deviceService.getDnsConfig();
    return Map<String, dynamic>.from(result['data'] ?? {});
  }

  Future<void> setDns(List<String> servers) =>
      _deviceService.setDns({'servers': servers});
  Future<void> clearDns() => _deviceService.clearDns();
  Future<void> setPrivateDns(String hostname) =>
      _deviceService.setPrivateDns(hostname);
  Future<void> clearPrivateDns() => _deviceService.clearPrivateDns();

  Future<Map<String, dynamic>> getProxyConfig() async {
    final result = await _deviceService.getProxyConfig();
    return Map<String, dynamic>.from(result['data'] ?? {});
  }

  Future<void> setProxy(String host, int port) =>
      _deviceService.setProxy({'host': host, 'port': port});
  Future<void> clearProxy() => _deviceService.clearProxy();
}
