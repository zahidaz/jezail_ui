import 'package:jezail_ui/services/device_service.dart';
import 'package:jezail_ui/models/device/process_info.dart';

class ProcessesRepository {
  const ProcessesRepository(this._deviceService);

  final DeviceService _deviceService;

  Future<List<ProcessInfo>> getProcesses() async {
    final result = await _deviceService.listProcesses();
    final processes = List<Map<String, dynamic>>.from(result['data'] ?? []);
    return processes.map(ProcessInfo.fromJson).toList();
  }

  Future<Map<String, dynamic>> getProcessInfo(int pid) async => 
      await _deviceService.getProcess(pid);

  Future<void> killProcess(int pid) => _deviceService.killProcessByPid(pid);

  Future<void> killProcessByName(String name) => 
      _deviceService.killProcessByName(name);
}