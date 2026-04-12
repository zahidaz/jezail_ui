import 'package:jezail_ui/services/frida_service.dart';
import 'package:jezail_ui/models/tools/frida_status.dart';
import 'package:jezail_ui/models/tools/frida_info.dart';
import 'package:jezail_ui/core/exceptions/tool_exception.dart';

class FridaRepository {
  final FridaService _fridaService;

  const FridaRepository(this._fridaService);

  Future<FridaStatus> getStatus() async {
    try {
      final result = await _fridaService.getStatus();
      final data = result['data'];
      return FridaStatus(
        isRunning: data['isRunning'] as bool? ?? false,
        port: data['port']?.toString() ?? '',
        version: data['version']?.toString() ?? 'unknown',
      );
    } catch (e) {
      throw ToolOperationException('Failed to get Frida status: $e');
    }
  }

  Future<FridaInfo> getInfo() async {
    try {
      final result = await _fridaService.getInfo();
      final data = result['data'];
      return FridaInfo(
        currentVersion: data['currentVersion']?.toString() ?? 'unknown',
        latestVersion: data['latestVersion']?.toString() ?? 'unknown',
        needsUpdate: data['needsUpdate'] as bool? ?? false,
        installPath: data['installPath']?.toString() ?? '',
      );
    } catch (e) {
      throw ToolOperationException('Failed to get Frida info: $e');
    }
  }

  Future<void> start() async {
    try {
      await _fridaService.start();
    } catch (e) {
      throw ToolOperationException('Failed to start Frida: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _fridaService.stop();
    } catch (e) {
      throw ToolOperationException('Failed to stop Frida: $e');
    }
  }

  Future<void> install() async {
    try {
      await _fridaService.install();
    } catch (e) {
      throw ToolOperationException('Failed to install Frida: $e');
    }
  }

  Future<void> update() async {
    try {
      await _fridaService.update();
    } catch (e) {
      throw ToolOperationException('Failed to update Frida: $e');
    }
  }

  Future<Map<String, dynamic>> getConfig() async {
    try {
      final result = await _fridaService.getConfig();
      return Map<String, dynamic>.from(result['data'] ?? {});
    } catch (e) {
      throw ToolOperationException('Failed to get Frida config: $e');
    }
  }

  Future<void> updateConfig(Map<String, dynamic> config) async {
    try {
      await _fridaService.updateConfig(config);
    } catch (e) {
      throw ToolOperationException('Failed to update Frida config: $e');
    }
  }
}