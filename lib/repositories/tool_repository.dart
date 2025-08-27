import 'package:jezail_ui/services/adb_service.dart';
import 'package:jezail_ui/services/frida_service.dart';
import 'package:jezail_ui/models/tools/adb_status.dart';
import 'package:jezail_ui/models/tools/frida_status.dart';
import 'package:jezail_ui/models/tools/frida_info.dart';
import 'package:jezail_ui/core/exceptions/tool_exception.dart';

class ToolRepository {
  final AdbService _adbService;
  final FridaService _fridaService;

  const ToolRepository(this._adbService, this._fridaService);

  Future<AdbStatus> getAdbStatus() async {
    try {
      final result = await _adbService.getStatus();
      final data = result['data'];
      return AdbStatus(
        isRunning: data['isRunning'] == 'true',
        port: data['port'],
      );
    } catch (e) {
      throw ToolOperationException('Failed to get ADB status: $e');
    }
  }

  Future<void> startAdb() async {
    try {
      await _adbService.start();
    } catch (e) {
      throw ToolOperationException('Failed to start ADB: $e');
    }
  }

  Future<void> stopAdb() async {
    try {
      await _adbService.stop();
    } catch (e) {
      throw ToolOperationException('Failed to stop ADB: $e');
    }
  }

  Future<void> installAdbKey(String publicKey) async {
    try {
      await _adbService.installKey(publicKey);
    } catch (e) {
      throw ToolOperationException('Failed to install ADB key: $e');
    }
  }

  Future<FridaStatus> getFridaStatus() async {
    try {
      final result = await _fridaService.getStatus();
      final data = result['data'];
      return FridaStatus(
        isRunning: data['isRunning'],
        port: data['port'],
        version: data['version'],
      );
    } catch (e) {
      throw ToolOperationException('Failed to get Frida status: $e');
    }
  }

  Future<FridaInfo> getFridaInfo() async {
    try {
      final result = await _fridaService.getInfo();
      final data = result['data'];
      return FridaInfo(
        currentVersion: data['currentVersion'],
        latestVersion: data['latestVersion'],
        needsUpdate: data['needsUpdate'],
        installPath: data['installPath'],
      );
    } catch (e) {
      throw ToolOperationException('Failed to get Frida info: $e');
    }
  }

  Future<void> startFrida() async {
    try {
      await _fridaService.start();
    } catch (e) {
      throw ToolOperationException('Failed to start Frida: $e');
    }
  }

  Future<void> stopFrida() async {
    try {
      await _fridaService.stop();
    } catch (e) {
      throw ToolOperationException('Failed to stop Frida: $e');
    }
  }

  Future<void> installFrida() async {
    try {
      await _fridaService.install();
    } catch (e) {
      throw ToolOperationException('Failed to install Frida: $e');
    }
  }

  Future<void> updateFrida() async {
    try {
      await _fridaService.update();
    } catch (e) {
      throw ToolOperationException('Failed to update Frida: $e');
    }
  }
}

