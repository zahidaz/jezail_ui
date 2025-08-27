import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jezail_ui/models/packages/package_info.dart';
import 'package:jezail_ui/models/packages/details.dart';
import 'package:jezail_ui/repositories/package_repository.dart';
import 'package:jezail_ui/core/enums/package_enums.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

class PackageDetailsPage extends StatefulWidget {
  final PackageInfo? package;
  final PackageRepository repository;
  final Function(PackageAction, PackageInfo) onPackageAction;
  final VoidCallback onBack;

  const PackageDetailsPage({
    super.key,
    this.package,
    required this.repository,
    required this.onPackageAction,
    required this.onBack,
  });

  @override
  State<PackageDetailsPage> createState() => _PackageDetailsPageState();
}

class _PackageDetailsPageState extends State<PackageDetailsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  PackageDetails? details;
  Permissions? permissions;
  Signatures? signatures;
  ProcessInfo? processInfo;
  bool isDebuggable = false;
  bool isRunning = false;
  bool isLoading = true;
  String? error;

  // Filter states
  String _permissionFilter = '';
  String _componentFilter = '';
  bool _showOnlyExported = false;
  bool _showOnlyDangerous = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    if (widget.package != null) {
      _loadPackageData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPackageData() async {
    if (widget.package == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final results = await Future.wait([
        widget.repository.getPackageDetails(widget.package!.packageName),
        widget.repository.getAllPermissions(widget.package!.packageName),
        widget.repository.getPackageSignatures(widget.package!.packageName),
        widget.repository.isPackageDebuggable(widget.package!.packageName),
        widget.repository.isPackageRunning(widget.package!.packageName),
        widget.repository.getPackageProcessInfo(widget.package!.packageName),
      ]);

      setState(() {
        details = PackageDetails.fromJson(results[0] as Map<String, dynamic>);
        permissions = Permissions.fromJson(results[1] as Map<String, dynamic>);
        signatures = Signatures.fromJson(results[2] as Map<String, dynamic>);
        isDebuggable = results[3] as bool;
        isRunning = results[4] as bool;
        processInfo = ProcessInfo.fromJson(results[5] as Map<String, dynamic>);
        isLoading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load package details: $e';
        isLoading = false;
      });
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    context.showInfoSnackBar('$label copied to clipboard');
  }

  List<String> get _filteredPermissions {
    if (permissions == null) return [];
    var perms = permissions!.all;
    
    if (_permissionFilter.isNotEmpty) {
      perms = perms.where((p) => 
        p.toLowerCase().contains(_permissionFilter.toLowerCase())).toList();
    }
    
    if (_showOnlyDangerous) {
      perms = perms.where((p) => _isDangerous(p)).toList();
    }
    
    return perms;
  }

  bool _isDangerous(String permission) {
    const dangerous = [
      'CAMERA', 'MICROPHONE', 'RECORD_AUDIO', 'LOCATION', 'CONTACTS',
      'PHONE', 'SMS', 'CALENDAR', 'CALL_LOG', 'SENSORS', 'STORAGE',
      'EXTERNAL_STORAGE', 'MANAGE_EXTERNAL_STORAGE', 'SYSTEM_ALERT_WINDOW',
      'WRITE_SETTINGS', 'INSTALL_PACKAGES', 'DELETE_PACKAGES', 'BODY_SENSORS',
      'READ_PHONE_STATE', 'CALL_PHONE', 'SEND_SMS', 'READ_SMS'
    ];
    return dangerous.any((d) => permission.contains(d));
  }

  Color _getPermissionColor(String permission) {
    if (permissions?.denied.contains(permission) == true) {
      return Colors.red;
    } else if (_isDangerous(permission)) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.package == null) {
      return const Center(child: Text('No package selected'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.package!.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Security'),
            Tab(text: 'Permissions'),
            Tab(text: 'Components'),
            Tab(text: 'File System'),
            Tab(text: 'Runtime'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildSecurityTab(),
                    _buildPermissionsTab(),
                    _buildComponentsTab(),
                    _buildFileSystemTab(),
                    _buildRuntimeTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Basic Information', [
            _buildInfoRow('Package Name', widget.package!.packageName, copyable: true),
            _buildInfoRow('Display Name', widget.package!.name),
            _buildInfoRow('Version', details?.versionName ?? 'Unknown'),
            _buildInfoRow('Version Code', details?.versionCode.toString() ?? 'Unknown'),
            _buildInfoRow('System Package', widget.package!.isSystemApp ? 'Yes' : 'No'),
            _buildInfoRow('Running', isRunning ? 'YES - ACTIVE' : 'No', 
              color: isRunning ? Colors.green : Colors.grey),
            _buildInfoRow('Debuggable', isDebuggable ? 'YES - SECURITY RISK' : 'No',
              color: isDebuggable ? Colors.red : Colors.green),
            if (processInfo?.pid != null)
              _buildInfoRow('Process ID', processInfo!.pid.toString(), copyable: true),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Installation Details', [
            _buildInfoRow('First Install', _formatDate(details?.firstInstall)),
            _buildInfoRow('Last Update', _formatDate(details?.lastUpdate)),
            _buildInfoRow('Target SDK', details?.appInfo.targetSdk.toString() ?? 'Unknown'),
            _buildInfoRow('Min SDK', details?.appInfo.minSdk.toString() ?? 'Unknown'),
            _buildInfoRow('Compile SDK', details?.appInfo.compileSdk.toString() ?? 'Unknown'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Security Status', [
            _buildInfoRow('Debuggable', isDebuggable ? 'YES - SECURITY RISK' : 'No',
              color: isDebuggable ? Colors.red : Colors.green),
            _buildInfoRow('Debug Certificate', signatures?.hasDebugCert == true ? 'YES - DEBUG BUILD' : 'No',
              color: signatures?.hasDebugCert == true ? Colors.red : Colors.green),
            _buildInfoRow('System Package', widget.package!.isSystemApp ? 'Yes' : 'No'),
            _buildInfoRow('UID', details?.appInfo.uid.toString() ?? 'Unknown'),
          ]),
          const SizedBox(height: 16),
          if (signatures != null) _buildSignaturesCard(),
        ],
      ),
    );
  }

  Widget _buildSignaturesCard() {
    return _buildInfoCard('Signatures (${signatures!.count})', 
      signatures!.signatures.map((sig) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Algorithm', sig.algorithm),
          _buildInfoRow('Subject', sig.subject, copyable: true),
          _buildInfoRow('Issuer', sig.issuer, copyable: true),
          _buildInfoRow('Serial Number', sig.serialNumber, copyable: true),
          _buildInfoRow('Valid From', sig.notBefore),
          _buildInfoRow('Valid Until', sig.notAfter),
          _buildInfoRow('MD5', sig.md5, copyable: true, monospace: true),
          _buildInfoRow('SHA1', sig.sha1, copyable: true, monospace: true),
          _buildInfoRow('SHA256', sig.sha256, copyable: true, monospace: true),
          if (sig != signatures!.signatures.last) const Divider(),
        ],
      )).toList(),
    );
  }

  Widget _buildPermissionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Filter permissions',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _permissionFilter = value),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Show only dangerous'),
                      value: _showOnlyDangerous,
                      onChanged: (value) => setState(() => _showOnlyDangerous = value ?? false),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredPermissions.length,
            itemBuilder: (context, index) {
              final permission = _filteredPermissions[index];
              final isGranted = permissions?.granted.contains(permission) ?? false;
              final isDangerous = _isDangerous(permission);
              
              return ListTile(
                leading: Icon(
                  isGranted ? Icons.check_circle : Icons.cancel,
                  color: _getPermissionColor(permission),
                ),
                title: Text(
                  permission,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: isDangerous ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  '${isGranted ? 'GRANTED' : 'DENIED'}${isDangerous ? ' • DANGEROUS' : ''}',
                  style: TextStyle(
                    color: _getPermissionColor(permission),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDangerous)
                      IconButton(
                        icon: Icon(isGranted ? Icons.block : Icons.check),
                        tooltip: isGranted ? 'Revoke Permission' : 'Grant Permission',
                        onPressed: () => isGranted
                            ? _revokePermission(permission)
                            : _grantPermission(permission),
                      ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy Permission',
                      onPressed: () => _copy(permission, 'Permission'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComponentsTab() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Activities'),
              Tab(text: 'Services'),
              Tab(text: 'Receivers'),
              Tab(text: 'Providers'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Filter components',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _componentFilter = value),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Show only exported (attack surface)'),
                  value: _showOnlyExported,
                  onChanged: (value) => setState(() => _showOnlyExported = value ?? false),
                  dense: true,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildActivitiesList(),
                _buildServicesList(),
                _buildReceiversList(),
                _buildProvidersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList() {
    if (details == null) return const SizedBox();
    
    var activities = details!.activities
        .where((a) => _componentFilter.isEmpty || 
            a.name.toLowerCase().contains(_componentFilter.toLowerCase()))
        .where((a) => !_showOnlyExported || a.exported)
        .toList();

    return ListView.builder(
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildComponentTile(
          activity.name,
          activity.exported,
          activity.enabled,
          activity.permission,
          [
            'Process: ${activity.processName}',
            'Launch Mode: ${activity.launchMode}',
            'Task Affinity: ${activity.taskAffinity}',
          ],
        );
      },
    );
  }

  Widget _buildServicesList() {
    if (details == null) return const SizedBox();
    
    var services = details!.services
        .where((s) => _componentFilter.isEmpty || 
            s.name.toLowerCase().contains(_componentFilter.toLowerCase()))
        .where((s) => !_showOnlyExported || s.exported)
        .toList();

    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildComponentTile(
          service.name,
          service.exported,
          service.enabled,
          service.permission,
          ['Process: ${service.processName}'],
        );
      },
    );
  }

  Widget _buildReceiversList() {
    if (details == null) return const SizedBox();
    
    var receivers = details!.receivers
        .where((r) => _componentFilter.isEmpty || 
            r.name.toLowerCase().contains(_componentFilter.toLowerCase()))
        .where((r) => !_showOnlyExported || r.exported)
        .toList();

    return ListView.builder(
      itemCount: receivers.length,
      itemBuilder: (context, index) {
        final receiver = receivers[index];
        return _buildComponentTile(
          receiver.name,
          receiver.exported,
          receiver.enabled,
          receiver.permission,
          ['Process: ${receiver.processName}'],
        );
      },
    );
  }

  Widget _buildProvidersList() {
    if (details == null) return const SizedBox();
    
    var providers = details!.providers
        .where((p) => _componentFilter.isEmpty || 
            p.name.toLowerCase().contains(_componentFilter.toLowerCase()) ||
            p.authority.toLowerCase().contains(_componentFilter.toLowerCase()))
        .where((p) => !_showOnlyExported || p.exported)
        .toList();

    return ListView.builder(
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        return _buildComponentTile(
          provider.name,
          provider.exported,
          provider.enabled,
          null,
          [
            'Authority: ${provider.authority}',
            'Process: ${provider.processName}',
            'Grant URI Permissions: ${provider.grantUriPermissions}',
          ],
        );
      },
    );
  }

  Widget _buildComponentTile(
    String name,
    bool exported,
    bool enabled,
    String? permission,
    List<String> details,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          exported ? Icons.public : Icons.lock,
          color: exported ? Colors.red : Colors.green,
        ),
        title: Text(
          name.split('.').last,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exported: ${exported ? 'YES - ATTACK SURFACE' : 'No'}',
              style: TextStyle(
                color: exported ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (permission != null)
              Text('Permission: $permission', 
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  name,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 8),
                ...details.map((detail) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(detail, style: const TextStyle(fontSize: 12)),
                )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _copy(name, 'Component name'),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSystemTab() {
    if (details == null) return const SizedBox();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('APK & Installation', [
            _buildInfoRow('Source Dir', details!.appInfo.sourceDir, copyable: true),
            _buildInfoRow('Public Source Dir', details!.appInfo.publicSourceDir, copyable: true),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Data Directories', [
            _buildInfoRow('Data Dir', details!.appInfo.dataDir, copyable: true),
            _buildInfoRow('Native Library Dir', details!.appInfo.nativeLibraryDir, copyable: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildRuntimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Runtime Status', [
            _buildInfoRow('Running', isRunning ? 'YES - ACTIVE' : 'No',
              color: isRunning ? Colors.green : Colors.grey),
            _buildInfoRow('Process ID', processInfo?.pid?.toString() ?? 'Unknown'),
            _buildInfoRow('Process Name', details?.appInfo.processName ?? 'Unknown'),
            _buildInfoRow('UID', details?.appInfo.uid.toString() ?? 'Unknown'),
            _buildInfoRow('Enabled', details?.appInfo.enabled == true ? 'Yes' : 'No'),
          ]),
          if (processInfo != null && processInfo!.running) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Memory Usage', [
              _buildInfoRow('Current RSS', processInfo!.memoryUsage, 
                color: processInfo!.vmRss != null ? Colors.blue : null),
              _buildInfoRow('Peak Memory', processInfo!.memoryPeak,
                color: processInfo!.vmPeak != null ? Colors.orange : null),
              _buildInfoRow('Virtual Size', processInfo!.memorySize,
                color: processInfo!.vmSize != null ? Colors.purple : null),
              _buildInfoRow('CPU Stats Available', processInfo!.cpuStatAvailable ? 'Yes' : 'No'),
            ]),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isRunning 
                      ? () => widget.onPackageAction(PackageAction.stop, widget.package!)
                      : () => widget.onPackageAction(PackageAction.start, widget.package!),
                  icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(isRunning ? 'Stop Package' : 'Start Package'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRunning ? Colors.red[100] : Colors.green[100],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _loadPackageData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showClearDataDialog(),
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[100],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showClearCacheDialog(),
                  icon: const Icon(Icons.cached),
                  label: const Text('Clear Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[100],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label, 
    String? value, {
    bool copyable = false, 
    Color? color,
    bool monospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value ?? 'Unknown',
              style: TextStyle(
                color: color,
                fontFamily: monospace ? 'monospace' : null,
                fontSize: monospace ? 12 : null,
              ),
            ),
          ),
          if (copyable && value != null)
            IconButton(
              onPressed: () => _copy(value, label),
              icon: const Icon(Icons.copy, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Package Data'),
        content: Text('Are you sure you want to clear all data for ${widget.package!.name}?\n\nThis will remove all app data including settings, accounts, databases, etc. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.repository.clearPackageData(widget.package!.packageName);
        if (mounted) {
          context.showSuccessSnackBar('Cleared data for ${widget.package!.name}');
          await _loadPackageData();
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Failed to clear data: $e');
        }
      }
    }
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Package Cache'),
        content: Text('Are you sure you want to clear the cache for ${widget.package!.name}?\n\nThis will remove temporary files but preserve app data and settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.repository.clearPackageCache(widget.package!.packageName);
        if (mounted) {
          context.showSuccessSnackBar('Cleared cache for ${widget.package!.name}');
          await _loadPackageData();
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Failed to clear cache: $e');
        }
      }
    }
  }

  Future<void> _grantPermission(String permission) async {
    try {
      await widget.repository.grantPermission(widget.package!.packageName, permission);
      if (mounted) {
        context.showSuccessSnackBar('Granted permission: $permission');
        await _loadPackageData();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to grant permission: $e');
      }
    }
  }

  Future<void> _revokePermission(String permission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Permission'),
        content: Text('Are you sure you want to revoke this dangerous permission?\n\n$permission\n\nThis may cause the app to malfunction.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.repository.revokePermission(widget.package!.packageName, permission);
        if (mounted) {
          context.showSuccessSnackBar('Revoked permission: $permission');
          await _loadPackageData();
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Failed to revoke permission: $e');
        }
      }
    }
  }
}