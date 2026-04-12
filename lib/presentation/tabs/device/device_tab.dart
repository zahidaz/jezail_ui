import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/core/log.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/tabs/device/device_card_configs.dart';
import 'package:jezail_ui/presentation/tabs/device/widgets/circular_status_indicator.dart';
import 'package:jezail_ui/presentation/tabs/device/widgets/device_formatters.dart';
import 'package:jezail_ui/presentation/tabs/device/widgets/search.dart';
import 'package:jezail_ui/presentation/widgets/collapsible_card.dart';

class DeviceTab extends StatefulWidget {
  const DeviceTab({super.key, required this.repository, this.isActiveNotifier});
  final DeviceRepository repository;
  final ValueNotifier<bool>? isActiveNotifier;

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
        widget.repository.getEnvironmentVariables(),
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
          final selinuxData = results[7]['data'];
          final selinuxStatus = selinuxData is String
              ? selinuxData
              : (selinuxData is Map ? selinuxData['status']?.toString() : null) ?? 'Unknown';
          _allData['security'] = {'status': selinuxStatus};
          _allData['properties'] = results[8]['data'] ?? {};
          _allData['env'] = results[9]['data'] ?? {};
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

    context.showSuccessSnackBar('$label copied to clipboard');
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final isActive = widget.isActiveNotifier?.value ?? true;
      if (mounted && !_loading && isActive) {
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
    } catch (e) {
      Log.warning('Dynamic data refresh failed: $e');
    }
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
            CircularStatusIndicator(
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
            const SizedBox(width: 16),
            CircularStatusIndicator(
              icon: Icons.memory,
              value: ramUsagePercent / 100,
              color: _getRamColor(ramUsagePercent.toDouble()),
              centerText: '${ramUsagePercent.toInt()}%',
              label: 'RAM',
              details: [
                '${formatBytes(usedRam)} used',
                '${formatBytes(availableRam)} free',
                '${formatBytes(totalRam)} total',
              ],
            ),
            const SizedBox(width: 16),
            CircularStatusIndicator(
              icon: Icons.storage,
              value: _getStorageProgress(),
              color: _getStorageColor(),
              centerText: _getStorageUsage(),
              label: 'Storage',
              details: [
                _getStorageSubtitle(),
                '${formatBytes(_storageStats.used)} used',
                '${formatBytes(_storageStats.total)} total',
              ],
            ),
            const SizedBox(width: 16),
            CircularStatusIndicator(
              icon: isCharging ? Icons.battery_charging_full : Icons.battery_std,
              value: batteryLevel / 100,
              color: _getBatteryColor(batteryLevel, isCharging),
              centerText: '${batteryLevel.toInt()}%',
              label: 'Battery',
              details: [
                if (isCharging) 'Charging',
                '${batteryTemp.toStringAsFixed(1)}°C',
                getBatteryStatus(batteryData['status']),
              ],
            ),
            const SizedBox(width: 16),
            CircularStatusIndicator(
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
        );
          final minWidth = 5 * 80.0;
          if (constraints.maxWidth < minWidth) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minWidth),
                child: content,
              ),
            );
          }
          return content;
        },
      ),
    );
  }

  ({int used, int total, int free}) get _storageStats {
    final internal = (_allData['storageDetails'] ?? {})['internal'] ?? {};
    final total = (internal['totalSpace'] as num?)?.toInt() ?? 1;
    final free = (internal['freeSpace'] as num?)?.toInt() ?? 0;
    return (used: total - free, total: total, free: free);
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
    final s = _storageStats;
    final usagePercent = (s.used / s.total * 100).clamp(0, 100);
    return '${usagePercent.toInt()}%';
  }

  double _getStorageProgress() {
    final s = _storageStats;
    return (s.used / s.total).clamp(0.0, 1.0);
  }

  Color _getStorageColor() {
    final progress = _getStorageProgress();
    if (progress > 0.9) return Colors.red;
    if (progress > 0.8) return Colors.orange;
    return Colors.green;
  }

  String _getStorageSubtitle() => '${formatBytes(_storageStats.free)} free';

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

    final filteredCards = deviceCardConfigs.where((config) {
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

                    return CollapsibleCard(
                      title: config.title,
                      icon: config.icon,
                      isExpanded: isExpanded,
                      onToggle: () => setState(() {
                        if (isExpanded) {
                          expandedCards.remove(config.dataKey);
                        } else {
                          expandedCards.add(config.dataKey);
                        }
                      }),
                      subtitle: '${nonEmptyEntries.length} properties',
                      children: [
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
                    );
                  },
                ),
        ),
      ],
    );
  }
}
