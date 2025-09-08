import 'dart:typed_data';
import 'package:jezail_ui/services/device_service.dart';

class ControlsRepository {
  const ControlsRepository(this._deviceService);

  final DeviceService _deviceService;

  Future<Uint8List> takeScreenshot() async => await _deviceService.getScreenshot();

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

  Future<String?> getClipboard() async => await _deviceService.getClipboard();
  
  Future<void> setClipboard(String text) => _deviceService.setClipboard(text);
      
  Future<void> clearClipboard() => _deviceService.clearClipboard();

  Future<Map<String, dynamic>> getSelinuxStatus() async => 
      await _deviceService.getSelinuxStatus();
      
  Future<void> toggleSelinux(bool enable) => _deviceService.toggleSelinux(enable);

  Future<String> getSystemProperty(String key) async {
    final result = await _deviceService.getSystemProperty(key);
    return result.toString();
  }

  Future<void> setSystemProperty(String key, String value) => 
      _deviceService.setSystemProperty(key, value);
}