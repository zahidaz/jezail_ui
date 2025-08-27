import 'package:flutter/material.dart';
import 'package:jezail_ui/presentation/tabs/device/widgets/info_card.dart';
import 'package:jezail_ui/repositories/device_repository.dart';

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
    (DeviceRepository r) => r.getBuildInfo(),
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
        ['Manufacturer', data[0]?['data']?['manufacturer']],
        ['Android', data[0]?['data']?['androidVersion']],
        ['SDK', data[0]?['data']?['sdkInt']],
        ['Security Patch', data[0]?['data']?['securityPatch']],
        ['Root', (data[0]?['data']?['isRooted'] ?? false) ? 'Yes' : 'No'],
        ['Debuggable', (data[0]?['data']?['isDebuggable'] ?? false) ? 'Yes' : 'No'],
        ['SELinux', data[0]?['data']?['seLinuxStatus']],
        ['Supported ABIs', (data[0]?['data']?['supportedAbis'] as List?)?.join(', ')],
        ['64-bit', (data[0]?['data']?['is64Bit'] ?? false) ? 'Yes' : 'No'],
      ]),
      _CardData('Build Info', Icons.build, [
        ['Brand', data[1]?['data']?['brand']],
        ['Device', data[1]?['data']?['device']],
        ['Product', data[1]?['data']?['product']],
        ['Hardware', data[1]?['data']?['hardware']],
        ['Build ID', data[1]?['data']?['buildId']],
        ['Build Type', data[1]?['data']?['buildType']],
        ['Build Tags', data[1]?['data']?['buildTags']],
        ['Bootloader', data[1]?['data']?['bootloader']],
        ['Radio', data[1]?['data']?['radio']],
        ['Board', data[1]?['data']?['board']],
      ]),
      _CardData('Battery', Icons.battery_full, [
        ['Level', '${data[2]?['data']?['level'] ?? 0}%'],
        ['Status', _status(data[2]?['data']?['status'])],
        ['Health', _health(data[2]?['data']?['health'])],
        ['Temperature', '${((data[2]?['data']?['temperature'] ?? 0) / 10).toStringAsFixed(1)}°C'],
        ['Voltage', '${data[2]?['data']?['voltage'] ?? 0}mV'],
        ['Technology', data[2]?['data']?['technology']],
        ['Present', (data[2]?['data']?['present'] ?? false) ? 'Yes' : 'No'],
        ['Plugged', (data[2]?['data']?['plugged'] ?? false) ? 'Yes' : 'No'],
        ['Scale', data[2]?['data']?['scale']],
      ]),
      _CardData('CPU', Icons.memory, [
        ['Architecture', data[3]?['data']?['architecture']],
        ['Cores', data[3]?['data']?['cores']],
        ['64-bit', (data[3]?['data']?['is64Bit'] ?? false) ? 'Yes' : 'No'],
        ['Processor', data[3]?['data']?['processor']],
        ['Max Frequency', '${data[3]?['data']?['maxFreq']} GHz'],
        ['Features Count', (data[3]?['data']?['features'] as List?)?.length.toString()],
      ]),
      _CardData('Memory', Icons.memory, [
        ['Total RAM', _gb(data[4]?['data']?['totalMem'])],
        ['Available RAM', _gb(data[4]?['data']?['availMem'])],
        ['Used RAM', _gb(data[4]?['data']?['usedMem'])],
        ['Low Memory', (data[4]?['data']?['lowMemory'] ?? false) ? 'Yes' : 'No'],
        ['Low RAM Device', (data[4]?['data']?['isLowRamDevice'] ?? false) ? 'Yes' : 'No'],
        ['Memory Free', _gb(data[4]?['data']?['memFree'])],
        ['Cached', _gb(data[4]?['data']?['cached'])],
        ['Buffers', _gb(data[4]?['data']?['buffers'])],
        ['Swap Total', _gb(data[4]?['data']?['swapTotal'])],
        ['Swap Free', _gb(data[4]?['data']?['swapFree'])],
      ]),
      _CardData('Storage', Icons.storage, [
        ['Internal Total', _gb(data[0]?['data']?['internalStorage']?['totalSpace'])],
        ['Internal Free', _gb(data[0]?['data']?['internalStorage']?['freeSpace'])],
        ['Internal Used', _gb(data[0]?['data']?['internalStorage']?['usedSpace'])],
        ['Internal Path', data[0]?['data']?['internalStorage']?['path']],
        ['Internal Writable', (data[0]?['data']?['internalStorage']?['writable'] ?? false) ? 'Yes' : 'No'],
        ['Internal Readable', (data[0]?['data']?['internalStorage']?['readable'] ?? false) ? 'Yes' : 'No'],
      ]),
      _CardData('Network Status', Icons.wifi, [
        ['Internet', _connected(data[0]?['data']?['hasInternet'])],
        ['WiFi', _connected(data[6]?['data']?['activeConnection']?['hasWifi'])],
        ['Cellular', _connected(data[6]?['data']?['activeConnection']?['hasCellular'])],
        ['Ethernet', _connected(data[6]?['data']?['activeConnection']?['hasEthernet'])],
        ['Validated', _connected(data[6]?['data']?['activeConnection']?['validated'])],
        ['SSID', data[0]?['data']?['wifiSSID']],
      ]),
      _CardData('WiFi Details', Icons.wifi, [
        ['SSID', data[6]?['data']?['wifi']?['ssid']],
        ['IP Address', data[6]?['data']?['wifi']?['ipAddress']],
        ['RSSI', '${data[6]?['data']?['wifi']?['rssi']} dBm'],
        ['Link Speed', '${data[6]?['data']?['wifi']?['linkSpeed']} Mbps'],
        ['TX Link Speed', '${data[6]?['data']?['wifi']?['txLinkSpeed']} Mbps'],
        ['RX Link Speed', '${data[6]?['data']?['wifi']?['rxLinkSpeed']} Mbps'],
        ['Frequency', '${data[6]?['data']?['wifi']?['frequency']} MHz'],
        ['Network ID', data[6]?['data']?['wifi']?['networkId']],
      ]),
      _CardData('Cellular', Icons.signal_cellular_alt, [
        ['Network Operator', data[6]?['data']?['cellular']?['networkOperator']],
        ['Network Type', data[6]?['data']?['cellular']?['networkType']],
        ['Phone Type', data[6]?['data']?['cellular']?['phoneType']],
        ['SIM State', data[6]?['data']?['cellular']?['simState']],
        ['Roaming', (data[6]?['data']?['cellular']?['isNetworkRoaming'] ?? false) ? 'Yes' : 'No'],
        ['Data Enabled', (data[6]?['data']?['cellular']?['isDataEnabled'] ?? false) ? 'Yes' : 'No'],
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
