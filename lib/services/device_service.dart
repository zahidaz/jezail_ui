import 'dart:typed_data';
import 'dart:js_interop';
import 'package:jezail_ui/services/api_service.dart';
import 'package:jezail_ui/core/log.dart';

import 'package:web/web.dart' as web;

class DeviceService {
  final ApiService _api;
  DeviceService(this._api);

  Future<dynamic> getDeviceInfo() => _api.get('/device');
  Future<dynamic> getBuildInfo() => _api.get('/device/build-info');
  Future<dynamic> getSelinuxStatus() => _api.get('/device/selinux');
  Future<dynamic> toggleSelinux(bool enable) =>
      _api.post('/device/selinux/toggle', body: {'enable': enable});

  Future<void> pressHome() => _api.post('/device/keys/home');
  Future<void> pressBack() => _api.post('/device/keys/back');
  Future<void> pressMenu() => _api.post('/device/keys/menu');
  Future<void> pressRecentApps() => _api.post('/device/keys/recent');
  Future<void> pressPower() => _api.post('/device/keys/power');
  Future<void> pressVolumeUp() => _api.post('/device/keys/volume-up');
  Future<void> pressVolumeDown() => _api.post('/device/keys/volume-down');
  Future<void> muteVolume() => _api.post('/device/keys/volume-mute');
  Future<void> unmuteVolume() => _api.post('/device/keys/volume-unmute');
  Future<void> keycode(int code) =>
      _api.post('/device/keys/keycode/$code');

  Future<dynamic> getSystemProperties() =>
      _api.get('/device/system/properties');
  Future<dynamic> getSystemProperty(String key) =>
      _api.get('/device/system/properties/$key');
  Future<void> setSystemProperty(String key, String value) =>
      _api.post('/device/system/properties/$key', body: value);

  Future<dynamic> listProcesses() => _api.get('/device/processes');
  Future<dynamic> getProcess(int pid) =>
      _api.get('/device/processes/$pid');
  Future<void> killProcessByPid(int pid) =>
      _api.delete('/device/processes/$pid');
  Future<void> killProcessByName(String name) =>
      _api.delete('/device/processes/name/$name');

  Future<dynamic> getAllLogs({int? lines, String? filter}) {
    return _api.get(_buildLogUrl('/device/logs', lines: lines, filter: filter));
  }
  
  Future<dynamic> getKernelLogs({int? lines, String? filter}) {
    return _api.get(_buildLogUrl('/device/logs/kernel', lines: lines, filter: filter));
  }
  
  Future<dynamic> getRadioLogs({int? lines, String? filter}) {
    return _api.get(_buildLogUrl('/device/logs/radio', lines: lines, filter: filter));
  }
  
  Future<dynamic> getSystemLogs({int? lines, String? filter}) {
    return _api.get(_buildLogUrl('/device/logs/system', lines: lines, filter: filter));
  }
  
  Future<dynamic> getCrashLogs({int? lines, String? filter}) {
    return _api.get(_buildLogUrl('/device/logs/crash', lines: lines, filter: filter));
  }
  
  Future<dynamic> getEventLogs({int? lines, String? filter}) {
    return _api.get(_buildLogUrl('/device/logs/events', lines: lines, filter: filter));
  }

  String _buildLogUrl(String path, {int? lines, String? filter}) {
    final params = <String>[];
    if (lines != null) params.add('lines=$lines');
    if (filter != null && filter.isNotEmpty) params.add('filter=${Uri.encodeComponent(filter)}');
    return params.isEmpty ? path : '$path?${params.join('&')}';
  }
  Future<void> clearLogs() => _api.delete('/device/logs');

  Future<dynamic> getBattery() => _api.get('/device/battery');
  Future<dynamic> getCpu() => _api.get('/device/cpu');
  Future<dynamic> getRam() => _api.get('/device/ram');
  Future<dynamic> getStorage() => _api.get('/device/storage');
  Future<dynamic> getStorageDetails() =>
      _api.get('/device/storage/details');
  Future<dynamic> getNetwork() => _api.get('/device/network');

  Future<String?> getClipboard() async {
    final res = await _api.get('/device/clipboard');
    return res['data']?['content'];
  }
  Future<void> setClipboard(String text) =>
      _api.post('/device/clipboard', body: text);
  Future<void> clearClipboard() => _api.delete('/device/clipboard');

  Future<Uint8List> getScreenshot() => _api.getBinary('/device/screenshot');

  Future<void> downloadScreenshot() async {
    try {
      Log.info('Taking screenshot and downloading');
      final screenshotBytes = await getScreenshot();
      final blob = web.Blob([screenshotBytes.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
      final url = web.URL.createObjectURL(blob);
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'screenshot_$timestamp.png';
      
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = filename;
      anchor.click();
      
      web.URL.revokeObjectURL(url);
      Log.info('Screenshot downloaded: $filename');
    } catch (e) {
      Log.error('Failed to download screenshot', e);
      rethrow;
    }
  }
}
