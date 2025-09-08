import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/tabs/device/widgets/search.dart';

class DeviceTab extends StatefulWidget {
  const DeviceTab({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<DeviceTab> createState() => _DeviceTabState();
}

class _DeviceTabState extends State<DeviceTab> with SingleTickerProviderStateMixin {
  final Map<String, Map<String, dynamic>> _allData = {};
  String _searchQuery = '';
  bool _loading = false;
  Timer? _debounce;
  Timer? _refreshTimer;
  late AnimationController _animController;
  Set<String> expandedCards = {};

  final List<_CardConfig> _cardConfigs = [
    _CardConfig('Device', Icons.smartphone, 'device', (data) => {
      'Name': data['deviceName'],
      'Model': data['model'], 
      'Manufacturer': data['manufacturer'],
      'Android Version': data['androidVersion'],
      'SDK Level': data['sdkInt'],
      'Security Patch': data['securityPatch'],
      'Root Access': (data['isRooted'] ?? false) ? 'Yes' : 'No',
      'Debuggable': (data['isDebuggable'] ?? false) ? 'Yes' : 'No',
      'Fingerprint': data['fingerprint'],
    }),
    _CardConfig('Build', Icons.construction, 'build', (data) => {
      'Brand': data['brand'],
      'Device': data['device'],
      'Product': data['product'], 
      'Hardware': data['hardware'],
      'Build ID': data['buildId'],
      'Build Type': data['buildType'],
      'Build Tags': data['buildTags'],
      'Bootloader': data['bootloader'],
      'Radio': data['radio'],
      'Board': data['board'],
      'Build Time': data['time'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(data['time']).toString()
        : null,
    }),
    _CardConfig('Battery', Icons.battery_std, 'battery', (data) => {
      'Level': '${data['level'] ?? 0}%',
      'Status': _getBatteryStatus(data['status']),
      'Health': _getBatteryHealth(data['health']),
      'Temperature': '${((data['temperature'] ?? 0) / 10).toStringAsFixed(1)}°C',
      'Voltage': '${data['voltage'] ?? 0}mV',
      'Technology': data['technology'],
      'Present': (data['present'] ?? false) ? 'Yes' : 'No',
      'Plugged': (data['plugged'] ?? false) ? 'Yes' : 'No',
      'Scale': data['scale']?.toString(),
      'Plugged Type': _getBatteryPluggedType(data['pluggedTypes']),
    }),
    _CardConfig('Processor', Icons.developer_board, 'cpu', (data) => {
      'Architecture': data['architecture'],
      'Cores': data['cores']?.toString(),
      'Processor': data['processor'],
      'Max Frequency': '${data['maxFreq']} GHz',
      '64-bit Support': (data['is64Bit'] ?? false) ? 'Yes' : 'No',
      'Supported ABIs': (data['supportedAbis'] as List?)?.join(', '),
      'Features Count': (data['features'] as List?)?.length.toString(),
      'CPU Features': (data['features'] as List?)?.join(', '),
    }),
    _CardConfig('Memory', Icons.memory, 'memory', (data) => {
      'Total RAM': _formatBytes(data['totalMem']),
      'Available RAM': _formatBytes(data['availMem']),
      'Used RAM': _formatBytes(data['usedMem']),
      'Memory Total': _formatBytes(data['memTotal']),
      'Memory Free': _formatBytes(data['memFree']),
      'Memory Available': _formatBytes(data['memAvailable']),
      'Cached': _formatBytes(data['cached']),
      'Buffers': _formatBytes(data['buffers']),
      'Swap Total': _formatBytes(data['swapTotal']),
      'Swap Free': _formatBytes(data['swapFree']),
      'Low Memory': (data['lowMemory'] ?? false) ? 'Yes' : 'No',
      'Low RAM Device': (data['isLowRamDevice'] ?? false) ? 'Yes' : 'No',
      'Shared Memory': _formatBytes(data['shmem']),
      'Low Memory Threshold': _formatBytes(data['threshold']),
    }),
    _CardConfig('Storage', Icons.folder, 'storageDetails', (data) => {
      'Internal Total': _formatBytes(data['internal']?['totalSpace']),
      'Internal Free': _formatBytes(data['internal']?['freeSpace']),
      'Internal Used': _formatBytes(data['internal']?['usedSpace']),
      'Internal Usable': _formatBytes(data['internal']?['usableSpace']),
      'Internal Path': data['internal']?['path'],
      'External Total': _formatBytes(data['external']?['totalSpace']),
      'External Free': _formatBytes(data['external']?['freeSpace']),
      'External Path': data['external']?['path'],
      'Root Total': _formatBytes(data['root']?['totalSpace']),
      'Root Path': data['root']?['path'],
      'System Total': _formatBytes(data['system']?['totalSpace']),
      'System Path': data['system']?['path'],
      'Data Total': _formatBytes(data['data']?['totalSpace']),
      'Data Free': _formatBytes(data['data']?['freeSpace']),
      'Data Path': data['data']?['path'],
      'Cache Total': _formatBytes(data['cache']?['totalSpace']),
      'Cache Path': data['cache']?['path'],
      'Mount Points': data['mountPoints']?.length?.toString() ?? '0',
    }),
    _CardConfig('Network', Icons.wifi, 'network', (data) => {
      'Has Internet': (data['activeConnection']?['hasInternet'] ?? false) ? 'Yes' : 'No',
      'WiFi Connected': (data['activeConnection']?['hasWifi'] ?? false) ? 'Yes' : 'No',
      'Cellular Connected': (data['activeConnection']?['hasCellular'] ?? false) ? 'Yes' : 'No',
      'Ethernet Connected': (data['activeConnection']?['hasEthernet'] ?? false) ? 'Yes' : 'No',
      'Network Validated': (data['activeConnection']?['validated'] ?? false) ? 'Yes' : 'No',
      'WiFi SSID': data['wifi']?['ssid'],
      'IP Address': data['wifi']?['ipAddress'],
      'RSSI': data['wifi']?['rssi'] != null ? '${data['wifi']['rssi']} dBm' : null,
      'Link Speed': data['wifi']?['linkSpeed'] != null ? '${data['wifi']['linkSpeed']} Mbps' : null,
      'Frequency': data['wifi']?['frequency'] != null ? '${data['wifi']['frequency']} MHz' : null,
      'Network ID': data['wifi']?['networkId']?.toString(),
      'TX Link Speed': data['wifi']?['txLinkSpeed'] != null ? '${data['wifi']['txLinkSpeed']} Mbps' : null,
      'RX Link Speed': data['wifi']?['rxLinkSpeed'] != null ? '${data['wifi']['rxLinkSpeed']} Mbps' : null,
    }),
    _CardConfig('Cellular', Icons.signal_cellular_4_bar, 'network', (data) => {
      'Network Operator': data['cellular']?['networkOperator'],
      'Network Type': data['cellular']?['networkType']?.toString(),
      'Phone Type': data['cellular']?['phoneType']?.toString(),
      'SIM State': data['cellular']?['simState']?.toString(),
      'Roaming': (data['cellular']?['isNetworkRoaming'] ?? false) ? 'Yes' : 'No',
      'Data Enabled': (data['cellular']?['isDataEnabled'] ?? false) ? 'Yes' : 'No',
    }),
    _CardConfig('Network DHCP', Icons.router, 'network', (data) => {
      'DHCP IP': data['dhcp']?['ipAddress'],
      'Gateway': data['dhcp']?['gateway'],
      'MTU': data['dhcp']?['mtu']?.toString(),
      'DHCP DNS': (data['dhcp']?['dnsServers'] as List?)?.join(', '),
    }),
    _CardConfig('Network Interface', Icons.settings_ethernet, 'network', (data) => {
      'Interface Name': data['linkProperties']?['interfaceName'],
      'Link Addresses': (data['linkProperties']?['linkAddresses'] as List?)?.join('\n'),
      'Interface DNS': (data['linkProperties']?['dnsServers'] as List?)?.join(', '),
      'Routes Count': (data['linkProperties']?['routes'] as List?)?.length.toString(),
      'Network Interfaces': (data['interfaces'] as List?)?.length.toString(),
    }),
    _CardConfig('Security', Icons.shield, 'security', (data) => {
      'SELinux Status': data['status']?.toString() ?? 'Unknown',
    }),
    _CardConfig('System Properties', Icons.settings_applications, 'properties', (data) => {
      'Build User': data['ro.build.user'],
      'Build Host': data['ro.build.host'],
      'Kernel Version': data['ro.kernel.version'],
      'Init RC': data['ro.build.version.incremental'],
      'Display ID': data['ro.build.display.id'],
      'Secure': data['ro.secure'],
      'Debuggable System': data['ro.debuggable'],
      'ADB Enabled': data['ro.adb.secure'],
      'Zygote': data['ro.zygote'],
      'Dalvik Heap Size': data['dalvik.vm.heapsize'],
      'OpenGL Version': data['ro.opengles.version'],
      'WiFi Direct': data['wifi.direct.interface'],
      'Total Properties': data.length.toString(),
    }),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    _loadAllData();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _animController.dispose();
    _debounce?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (_loading) return;
    setState(() => _loading = true);
    _animController.repeat();
    
    try {
      final results = await Future.wait([
        widget.repository.getDeviceInfo(),
        widget.repository.getBuildInfo(),
        widget.repository.getBatteryInfo(),
        widget.repository.getCpuInfo(),
        widget.repository.getRamInfo(),
        widget.repository.getStorageDetails(),
        widget.repository.getNetworkInfo(),
        widget.repository.getSelinuxStatus(),
        widget.repository.getSystemProperties(),
      ]);

      if (mounted) {
        setState(() {
          _allData['device'] = results[0]['data'] ?? {};
          _allData['build'] = results[1]['data'] ?? {};
          _allData['battery'] = results[2]['data'] ?? {};
          _allData['cpu'] = results[3]['data'] ?? {};
          _allData['memory'] = results[4]['data'] ?? {};
          _allData['storageDetails'] = results[5]['data'] ?? {};
          _allData['network'] = results[6]['data'] ?? {};
          _allData['security'] = {'status': results[7]['data'] ?? 'Unknown'};
          _allData['properties'] = results[8]['data'] ?? {};
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load device information: $e');
    } finally {
      _animController.stop();
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value.toLowerCase());
    });
  }

  bool _matchesSearch(String title, Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;
    
    final searchText = '$title ${data.entries.map((e) => '${e.key} ${e.value}').join(' ')}'.toLowerCase();
    return searchText.contains(_searchQuery);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    context.showSuccessSnackBar('$label copied to clipboard');
  }

  static String _formatBytes(dynamic bytes) {
    if (bytes == null || bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = (bytes as num).toDouble();
    var suffixIndex = 0;
    while (size >= 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }
    return '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[suffixIndex]}';
  }

  static String _getBatteryStatus(int? status) => switch (status) {
    2 => 'Charging',
    3 => 'Discharging', 
    4 => 'Not charging',
    5 => 'Full',
    _ => 'Unknown',
  };

  static String _getBatteryHealth(int? health) => switch (health) {
    2 => 'Good',
    3 => 'Overheat',
    4 => 'Dead',
    5 => 'Over voltage',
    6 => 'Failure',
    7 => 'Cold',
    _ => 'Unknown',
  };

  static String _getBatteryPluggedType(int? pluggedTypes) => switch (pluggedTypes) {
    0 => 'None',
    1 => 'AC',
    2 => 'USB',
    4 => 'Wireless',
    _ => 'Unknown',
  };

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_loading) {
        _refreshDynamicData();
      }
    });
  }

  Future<void> _refreshDynamicData() async {
    try {
      final results = await Future.wait([
        widget.repository.getBatteryInfo(),
        widget.repository.getRamInfo(),
      ]);

      if (mounted) {
        setState(() {
          _allData['battery'] = results[0]['data'] ?? {};
          _allData['memory'] = results[1]['data'] ?? {};
        });
      }
    } catch (_) {}
  }

  Widget _buildStatusRow() {
    final batteryData = _allData['battery'] ?? {};
    final memoryData = _allData['memory'] ?? {};
    final networkData = _allData['network'] ?? {};
    final deviceData = _allData['device'] ?? {};
    final securityData = _allData['security'] ?? {};
    
    final batteryLevel = (batteryData['level'] as num?)?.toDouble() ?? 0;
    final isCharging = batteryData['plugged'] == true;
    final batteryTemp = ((batteryData['temperature'] as num?)?.toDouble() ?? 0) / 10;
    
    final totalRam = (memoryData['totalMem'] as num?)?.toInt() ?? 1;
    final availableRam = (memoryData['availMem'] as num?)?.toInt() ?? 0;
    final usedRam = totalRam - availableRam;
    final ramUsagePercent = (usedRam / totalRam * 100).clamp(0, 100);
    
    final hasInternet = networkData['activeConnection']?['hasInternet'] == true;
    final hasWifi = networkData['activeConnection']?['hasWifi'] == true;
    final wifiRssi = networkData['wifi']?['rssi'] as int?;
    
    final selinuxStatus = (securityData['status']?.toString() ?? '').toLowerCase();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _CircularStatusIndicator(
            icon: _getSelinuxIcon(selinuxStatus),
            value: _getSelinuxProgress(selinuxStatus),
            color: _getSelinuxColor(selinuxStatus),
            centerText: _getSelinuxText(selinuxStatus),
            label: 'SELinux',
            details: [
              'Status: ${_formatSelinuxStatus(selinuxStatus)}',
              selinuxStatus.contains('enforcing') ? 'Security Active' : 
              selinuxStatus.contains('permissive') ? 'Security Passive' : 'Security Disabled',
              deviceData['isRooted'] == true ? 'Device Rooted' : 'Device Not Rooted',
            ],
          ),
          _CircularStatusIndicator(
            icon: Icons.memory,
            value: ramUsagePercent / 100,
            color: _getRamColor(ramUsagePercent.toDouble()),
            centerText: '${ramUsagePercent.toInt()}%',
            label: 'RAM',
            details: [
              '${_formatBytes(usedRam)} used',
              '${_formatBytes(availableRam)} free',
              '${_formatBytes(totalRam)} total',
            ],
          ),
          _CircularStatusIndicator(
            icon: Icons.storage,
            value: _getStorageProgress(),
            color: _getStorageColor(),
            centerText: _getStorageUsage(),
            label: 'Storage',
            details: [
              _getStorageSubtitle(),
              '${_formatBytes(_getStorageUsed())} used',
              '${_formatBytes(_getStorageTotal())} total',
            ],
          ),
          _CircularStatusIndicator(
            icon: isCharging ? Icons.battery_charging_full : Icons.battery_std,
            value: batteryLevel / 100,
            color: _getBatteryColor(batteryLevel, isCharging),
            centerText: '${batteryLevel.toInt()}%',
            label: 'Battery',
            details: [
              if (isCharging) 'Charging',
              '${batteryTemp.toStringAsFixed(1)}°C',
              _getBatteryStatus(batteryData['status']),
            ],
          ),
          _CircularStatusIndicator(
            icon: hasInternet ? (hasWifi ? Icons.wifi : Icons.signal_cellular_4_bar) : Icons.signal_wifi_off,
            value: hasInternet ? 1.0 : 0.0,
            color: hasInternet ? (hasWifi ? Colors.blue : Colors.green) : Colors.red,
            centerText: hasInternet ? (hasWifi ? 'WiFi' : '4G') : 'Off',
            label: 'Network',
            details: [
              hasInternet ? 'Connected' : 'Disconnected',
              if (hasWifi && wifiRssi != null) '$wifiRssi dBm',
              if (hasWifi) networkData['wifi']?['ssid']?.toString() ?? 'Unknown SSID',
            ],
          ),
        ],
      ),
    );
  }

  int _getStorageUsed() {
    final storageData = _allData['storageDetails'] ?? {};
    final internal = storageData['internal'] ?? {};
    final totalSpace = (internal['totalSpace'] as num?)?.toInt() ?? 1;
    final freeSpace = (internal['freeSpace'] as num?)?.toInt() ?? 0;
    return totalSpace - freeSpace;
  }

  int _getStorageTotal() {
    final storageData = _allData['storageDetails'] ?? {};
    final internal = storageData['internal'] ?? {};
    return (internal['totalSpace'] as num?)?.toInt() ?? 0;
  }


  IconData _getSelinuxIcon(String status) {
    if (status.contains('enforcing')) return Icons.security;
    if (status.contains('permissive')) return Icons.security_outlined;
    return Icons.security_update_warning;
  }

  double _getSelinuxProgress(String status) {
    if (status.contains('enforcing')) return 1.0;
    if (status.contains('permissive')) return 0.5;
    return 0.0;
  }

  Color _getSelinuxColor(String status) {
    if (status.contains('enforcing')) return Colors.green;
    if (status.contains('permissive')) return Colors.orange;
    return Colors.red;
  }

  String _getSelinuxText(String status) {
    if (status.contains('enforcing')) return 'ON';
    if (status.contains('permissive')) return 'PERM';
    return 'OFF';
  }

  String _formatSelinuxStatus(String status) {
    if (status.contains('enforcing')) return 'Enforcing';
    if (status.contains('permissive')) return 'Permissive';
    if (status.contains('disabled')) return 'Disabled';
    return 'Unknown';
  }

  Color _getBatteryColor(double level, bool charging) {
    if (charging) return Colors.green;
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  Color _getRamColor(double usage) {
    if (usage > 85) return Colors.red;
    if (usage > 70) return Colors.orange;
    return Colors.green;
  }

  String _getStorageUsage() {
    final storageData = _allData['storageDetails'] ?? {};
    final internal = storageData['internal'] ?? {};
    final totalSpace = (internal['totalSpace'] as num?)?.toInt() ?? 1;
    final freeSpace = (internal['freeSpace'] as num?)?.toInt() ?? 0;
    final usedSpace = totalSpace - freeSpace;
    final usagePercent = (usedSpace / totalSpace * 100).clamp(0, 100);
    return '${usagePercent.toInt()}%';
  }

  double _getStorageProgress() {
    final storageData = _allData['storageDetails'] ?? {};
    final internal = storageData['internal'] ?? {};
    final totalSpace = (internal['totalSpace'] as num?)?.toInt() ?? 1;
    final freeSpace = (internal['freeSpace'] as num?)?.toInt() ?? 0;
    final usedSpace = totalSpace - freeSpace;
    return (usedSpace / totalSpace).clamp(0.0, 1.0);
  }

  Color _getStorageColor() {
    final progress = _getStorageProgress();
    if (progress > 0.9) return Colors.red;
    if (progress > 0.8) return Colors.orange;
    return Colors.green;
  }

  String _getStorageSubtitle() {
    final storageData = _allData['storageDetails'] ?? {};
    final internal = storageData['internal'] ?? {};
    final freeSpace = (internal['freeSpace'] as num?)?.toInt() ?? 0;
    return '${_formatBytes(freeSpace)} free';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _allData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading device information...'),
          ],
        ),
      );
    }

    final filteredCards = _cardConfigs.where((config) {
      final data = _allData[config.dataKey] ?? {};
      final processedData = config.processor(data);
      return _matchesSearch(config.title, processedData);
    }).toList();

    return Column(
      children: [
        if (_allData.isNotEmpty) _buildStatusRow(),
        CustomSearchField(
          hintText: 'Search device information...',
          onChanged: _onSearchChanged,
          onRefresh: _loadAllData,
          isLoading: _loading,
          animationController: _animController,
        ),
        Expanded(
          child: filteredCards.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No matching information found'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredCards.length,
                  itemBuilder: (context, index) {
                    final config = filteredCards[index];
                    final rawData = _allData[config.dataKey] ?? {};
                    final data = config.processor(rawData);
                    
                    final cs = Theme.of(context).colorScheme;
                    final isExpanded = expandedCards.contains(config.dataKey);
                    final nonEmptyEntries = data.entries
                        .where((e) => e.value != null && e.value.toString().isNotEmpty)
                        .toList();
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cs.outline.withAlpha(25)),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() {
                              if (isExpanded) {
                                expandedCards.remove(config.dataKey);
                              } else {
                                expandedCards.add(config.dataKey);
                              }
                            }),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(6)),
                                  child: Center(child: Icon(config.icon, size: 16, color: cs.onPrimaryContainer)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(config.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('${nonEmptyEntries.length} properties', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                ])),
                                const SizedBox(width: 8),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: cs.onSurfaceVariant,
                                  size: 20,
                                ),
                              ]),
                            ),
                          ),
                          if (isExpanded) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withAlpha(25),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 1,
                                    color: cs.outline.withAlpha(25),
                                    margin: const EdgeInsets.only(bottom: 12),
                                  ),
                                  Text(
                                    '${config.title} Details',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final entry in nonEmptyEntries) 
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: InkWell(
                                        onTap: () => _copyToClipboard(
                                          '${entry.key}: ${entry.value}',
                                          entry.key,
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 120,
                                              child: Text(
                                                entry.key,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                  color: cs.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                entry.value.toString(),
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.copy,
                                              size: 14,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CardConfig {
  final String title;
  final IconData icon;
  final String dataKey;
  final Map<String, dynamic> Function(Map<String, dynamic>) processor;

  _CardConfig(this.title, this.icon, this.dataKey, this.processor);
}

class _CircularStatusIndicator extends StatelessWidget {
  const _CircularStatusIndicator({
    required this.icon,
    required this.value,
    required this.color,
    required this.centerText,
    required this.label,
    required this.details,
  });

  final IconData icon;
  final double value;
  final Color color;
  final String centerText;
  final String label;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label\n${details.where((d) => d.isNotEmpty).join('\n')}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    strokeWidth: 3,
                    backgroundColor: Theme.of(context).colorScheme.outline.withAlpha(30),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withAlpha(25),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withAlpha(25),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      centerText,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}