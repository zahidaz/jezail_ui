import 'package:jezail_ui/services/device_service.dart';
import 'package:jezail_ui/core/enums/device_enums.dart';

class LogsRepository {
  const LogsRepository(this._deviceService);

  final DeviceService _deviceService;

  Future<List<String>> getLogs(LogType logType, {String? filter, int? lines}) async {
    final result = await switch (logType) {
      LogType.main => _deviceService.getAllLogs(lines: lines, filter: filter),
      LogType.system => _deviceService.getSystemLogs(lines: lines, filter: filter),
      LogType.kernel => _deviceService.getKernelLogs(lines: lines, filter: filter),
      LogType.radio => _deviceService.getRadioLogs(lines: lines, filter: filter),
      LogType.crash => _deviceService.getCrashLogs(lines: lines, filter: filter),
      LogType.events => _deviceService.getEventLogs(lines: lines, filter: filter),
    };
    return List<String>.from(result['data'] ?? []);
  }

  Future<void> clearLogs() async {
    await _deviceService.clearLogs();
  }
}