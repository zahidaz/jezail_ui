import 'package:jezail_ui/services/adb_service.dart';
import 'package:jezail_ui/models/tools/adb_status.dart';
import 'package:jezail_ui/core/exceptions/tool_exception.dart';

class AdbRepository {
  final AdbService _adbService;

  const AdbRepository(this._adbService);

  Future<AdbStatus> getStatus() async {
    try {
      final result = await _adbService.getStatus();
      final data = result['data'];
      return AdbStatus(
        isRunning: data['isRunning'] as bool? ?? false,
        port: (data['preferredPort'] ?? data['port'] ?? '').toString(),
      );
    } catch (e) {
      throw ToolOperationException('Failed to get ADB status: $e');
    }
  }

  Future<void> start() async {
    try {
      await _adbService.start();
    } catch (e) {
      throw ToolOperationException('Failed to start ADB: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _adbService.stop();
    } catch (e) {
      throw ToolOperationException('Failed to stop ADB: $e');
    }
  }

  Future<void> installKey(String publicKey) async {
    try {
      await _adbService.installKey(publicKey);
    } catch (e) {
      throw ToolOperationException('Failed to install ADB key: $e');
    }
  }

  Future<int> getPort() async {
    try {
      final result = await _adbService.getPort();
      return (result['data']?['port'] as int?) ?? 5555;
    } catch (e) {
      throw ToolOperationException('Failed to get ADB port: $e');
    }
  }

  Future<void> setPort(int port) async {
    try {
      await _adbService.setPort(port);
    } catch (e) {
      throw ToolOperationException('Failed to set ADB port: $e');
    }
  }
}