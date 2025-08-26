import 'package:flutter/material.dart';
import '../../widgets/device/info_card.dart';
import '../../../repositories/device_repository.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  List<Map<String, dynamic>?>? _data;
  String? _error;
  bool _loading = false;

  final _actions = [
    (DeviceRepository r) => r.getDeviceInfo(),
    (DeviceRepository r) => r.getBatteryInfo(),
    (DeviceRepository r) => r.getCpuInfo(),
    (DeviceRepository r) => r.getRamInfo(),
    (DeviceRepository r) => r.getStorageInfo(),
    (DeviceRepository r) => r.getNetworkInfo(),
    (DeviceRepository r) => r.getSelinuxStatus(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _data = await Future.wait(_actions.map((a) => a(widget.repository)));
    } catch (e) {
      _error = 'Load failed: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _loading
      ? const Center(child: CircularProgressIndicator())
      : _error != null
          ? _ErrorView(error: _error!, onRetry: _loadData)
          : _data != null
              ? _OverviewContent(data: _data!)
              : const SizedBox.shrink();
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.data});
  final List<Map<String, dynamic>?> data;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData('Device Info', Icons.phone_android, [
        ['Name', data[0]?['data']?['deviceName']],
        ['Model', data[0]?['data']?['model']],
        ['Android', data[0]?['data']?['androidVersion']],
        ['SDK', data[0]?['data']?['sdkInt']],
        ['Root', (data[0]?['data']?['isRooted'] ?? false) ? 'Yes' : 'No'],
      ]),
      _CardData('Battery', Icons.battery_full, [
        ['Level', '${data[1]?['data']?['level'] ?? 0}%'],
        ['Status', _status(data[1]?['data']?['status'])],
        ['Health', _health(data[1]?['data']?['health'])],
        ['Temp', '${((data[1]?['data']?['temperature'] ?? 0) / 10).toStringAsFixed(1)}°C'],
        ['Voltage', '${data[1]?['data']?['voltage'] ?? 0}mV'],
      ]),
      _CardData('CPU', Icons.memory, [
        ['Architecture', data[2]?['data']?['architecture']],
        ['Cores', data[2]?['data']?['cores']],
        ['64-bit', (data[2]?['data']?['is64Bit'] ?? false) ? 'Yes' : 'No'],
      ]),
      _CardData('RAM', Icons.memory, [
        ['Total', _gb(data[3]?['data']?['totalMem'])],
        ['Available', _gb(data[3]?['data']?['availMem'])],
        ['Used', _gb(data[3]?['data']?['usedMem'])],
      ]),
      _CardData('Network', Icons.wifi, [
        ['WiFi', _connected(data[5]?['data']?['activeConnection']?['hasWifi'])],
        ['Cellular', _connected(data[5]?['data']?['activeConnection']?['hasCellular'])],
        ['SSID', data[5]?['data']?['wifi']?['ssid']],
      ]),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth > 800;
        final width = wide ? (constraints.maxWidth - 32) / 2 : constraints.maxWidth;
        return Wrap(
          runSpacing: 16,
          spacing: 16,
          children: cards
              .map(
                (c) => SizedBox(
                  width: width,
                  child: InfoCard(
                    title: c.title,
                    icon: c.icon,
                    children: c.rows
                        .map((r) => InfoRow(r[0], r[1]?.toString() ?? 'Unknown'))
                        .toList(),
                  ),
                ),
              )
              .toList(),
        );
      }),
    );
  }

  static String _status(int? s) => switch (s) {
        2 => 'Charging',
        3 => 'Discharging',
        4 => 'Not charging',
        5 => 'Full',
        _ => 'Unknown',
      };

  static String _health(int? h) => switch (h) {
        2 => 'Good',
        3 => 'Overheat',
        4 => 'Dead',
        5 => 'Over voltage',
        6 => 'Failure',
        7 => 'Cold',
        _ => 'Unknown',
      };

  static String _gb(int? bytes) => '${((bytes ?? 0) / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';

  static String _connected(bool? s) => s == true ? 'Connected' : 'Disconnected';
}

class _CardData {
  final String title;
  final IconData icon;
  final List<List<dynamic>> rows;
  _CardData(this.title, this.icon, this.rows);
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(error, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
