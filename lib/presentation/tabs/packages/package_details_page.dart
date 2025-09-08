import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:jezail_ui/models/packages/package_info.dart';
import 'package:jezail_ui/repositories/package_repository.dart';
import 'package:jezail_ui/core/enums/package_enums.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/tabs/packages/package_list_page.dart';

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

class _PackageDetailsPageState extends State<PackageDetailsPage> {
  Map<String, dynamic>? _details;
  Map<String, dynamic>? _permissions;
  Map<String, dynamic>? _signatures;
  Map<String, dynamic>? _processInfo;
  bool? _isDebuggable;
  bool? _isRunning;

  final Map<String, bool> _sectionLoading = {};
  final Map<String, String?> _sectionErrors = {};
  String _searchQuery = '';
  final Set<String> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    if (widget.package != null) {
      _loadPackageData();
    }
  }

  Future<void> _loadPackageData() async {
    if (widget.package == null) return;

    final packageName = widget.package!.packageName;
    _loadSection(
      'details',
      () => widget.repository.getPackageDetails(packageName),
    );
    _loadSection(
      'permissions',
      () => widget.repository.getAllPermissions(packageName),
    );
    _loadSection(
      'signatures',
      () => widget.repository.getPackageSignatures(packageName),
    );
    _loadSection(
      'processInfo',
      () => widget.repository.getPackageProcessInfo(packageName),
    );
    _loadSection(
      'debuggable',
      () => widget.repository.isPackageDebuggable(packageName),
    );
    _loadSection(
      'running',
      () => widget.repository.isPackageRunning(packageName),
    );
  }

  Future<void> _loadSection(
    String section,
    Future<dynamic> Function() loader,
  ) async {
    setState(() {
      _sectionLoading[section] = true;
      _sectionErrors[section] = null;
    });

    try {
      final result = await loader();

      if (mounted) {
        setState(() {
          switch (section) {
            case 'details':
              _details = result['data'];
              break;
            case 'permissions':
              _permissions = result['data'];
              break;
            case 'signatures':
              _signatures = result['data'];
              break;
            case 'processInfo':
              _processInfo = result['data'];
              break;
            case 'debuggable':
              _isDebuggable = result;
              break;
            case 'running':
              _isRunning = result;
              break;
          }
          _sectionLoading[section] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sectionLoading[section] = false;
          _sectionErrors[section] = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.package == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFileSystemInfoSection(),
                const SizedBox(height: 16),
                _buildPermissionsCard(),
                const SizedBox(height: 16),
                _buildActivitiesSection(),
                const SizedBox(height: 16),
                _buildReceiversSection(),
                const SizedBox(height: 16),
                _buildProvidersSection(),
                const SizedBox(height: 16),
                _buildSignatureCard(),
                const SizedBox(height: 16),
                _buildSecurityInfoSection(),
                const SizedBox(height: 16),
                _buildVersionInstallSection(),
                const SizedBox(height: 16),
                _buildTechnicalInfoSection(),
                if (_processInfo != null && _isRunning == true) ...[
                  const SizedBox(height: 16),
                  _buildProcessInfoCard(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.android, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No package selected',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;
    final pkg = widget.package!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(bottom: BorderSide(color: cs.outline.withAlpha(25))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          const SizedBox(width: 12),
          _buildPackageIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              pkg.packageName,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                                fontFamily: 'monospace',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () =>
                                  _copy(pkg.packageName, 'Package name'),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHeaderBadges(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildPackageIcon() {
    return PackageIcon(pkg: widget.package!, radius: 24);
  }

  Widget _buildQuickActions() {
    final cs = Theme.of(context).colorScheme;
    final pkg = widget.package!;
    final isRunning = _isRunning ?? pkg.isRunning;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pkg.canLaunch) ...[
          _buildActionButton(
            isRunning ? 'Stop' : 'Start',
            isRunning ? Icons.stop : Icons.play_arrow,
            isRunning ? Colors.red : Colors.green,
            () async {
              final action = isRunning
                  ? PackageAction.stop
                  : PackageAction.start;
              setState(() {
                _isRunning = !isRunning;
              });
              try {
                await widget.onPackageAction(action, pkg);
                await Future.delayed(const Duration(milliseconds: 500));
                _loadSection(
                  'running',
                  () => widget.repository.isPackageRunning(pkg.packageName),
                );
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isRunning = isRunning;
                  });
                }
              }
            },
            isLoading: _sectionLoading['running'] == true,
          ),
          const SizedBox(width: 8),
        ],
        _buildActionButton(
          'Clear Cache',
          Icons.cached,
          Colors.orange,
          _clearCache,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          'Clear Data',
          Icons.delete_sweep,
          Colors.red,
          _clearData,
        ),
        const SizedBox(width: 8),
        _buildActionButton('Uninstall', Icons.delete, Colors.red, () async {
          try {
            await widget.onPackageAction(PackageAction.uninstall, pkg);
            // Navigate back to list page after successful uninstall
            if (mounted) {
              widget.onBack();
            }
          } catch (e) {
            // Error is already handled by the parent's onPackageAction
          }
        }),
        const SizedBox(width: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withAlpha(25)),
            ),
            child: GestureDetector(
              onTap: _loadPackageData,
              child: Icon(Icons.refresh, color: cs.primary, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderBadges() {
    final pkg = widget.package!;
    final isDebuggable = _isDebuggable;
    final hasDebugCert =
        _signatures?['signatures']?.first?['subject']?.contains('Debug') ??
        false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadge(
          pkg.isSystemApp ? 'System' : 'User',
          true,
          pkg.isSystemApp ? Colors.orange : Colors.blue,
          pkg.isSystemApp ? Icons.settings : Icons.person,
        ),
        SizedBox(width: 4),
        if (isDebuggable != null)
          _buildBadge(
            'Debuggable',
            isDebuggable,
            isDebuggable ? Colors.red : Colors.green,
            isDebuggable ? Icons.bug_report : Icons.verified_user,
          ),
        if (isDebuggable != null) const SizedBox(width: 4),
        if (hasDebugCert) ...[
          _buildBadge('Debug Cert', true, Colors.red, Icons.warning),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outline.withAlpha(25))),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withAlpha(25)),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search package information...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintStyle: TextStyle(
                    color: cs.onSurfaceVariant.withAlpha(150),
                    fontSize: 14,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInstallSection() {
    return _buildCollapsibleCard('Versions', Icons.tag, 'version_install', [
      _buildInfoRow('Version', _details?['versionName'] ?? 'Unknown'),
      _buildInfoRow(
        'Version Code',
        _details?['versionCode']?.toString() ?? 'Unknown',
      ),
      _buildInfoRow(
        'First Install',
        _formatTimestamp(_details?['firstInstallTime']),
      ),
      _buildInfoRow(
        'Last Update',
        _formatTimestamp(_details?['lastUpdateTime']),
      ),
    ]);
  }

  Widget _buildTechnicalInfoSection() {
    return _buildCollapsibleCard(
      'Runtime',
      Icons.developer_mode,
      'technical_info',
      [
        _buildInfoRow(
          'Target SDK',
          _details?['applicationInfo']?['targetSdkVersion']?.toString() ??
              'Unknown',
        ),
        _buildInfoRow(
          'Min SDK',
          _details?['applicationInfo']?['minSdkVersion']?.toString() ??
              'Unknown',
        ),
        _buildInfoRow(
          'Compile SDK',
          _details?['applicationInfo']?['compileSdkVersion']?.toString() ??
              'Unknown',
        ),
        _buildInfoRow(
          'UID',
          _details?['applicationInfo']?['uid']?.toString() ?? 'Unknown',
        ),
      ],
    );
  }

  Widget _buildSecurityInfoSection() {
    final pkg = widget.package!;
    final isDebuggable = _isDebuggable;
    final hasDebugCert =
        _signatures?['signatures']?.first?['subject']?.contains('Debug') ??
        false;

    return _buildCollapsibleCard('Security', Icons.security, 'security_info', [
      _buildInfoRow(
        'Debuggable',
        isDebuggable != null ? (isDebuggable ? 'YES' : 'NO') : 'Unknown',
      ),
      _buildInfoRow('Debug Certificate', hasDebugCert ? 'YES' : 'NO'),
      _buildInfoRow('System App', pkg.isSystemApp ? 'YES' : 'NO'),
      _buildInfoRow(
        'Enabled',
        _details?['applicationInfo']?['enabled'] == true ? 'YES' : 'NO',
      ),
    ]);
  }

  Widget _buildFileSystemInfoSection() {
    return _buildCollapsibleCard(
      'Filesystem',
      Icons.folder_outlined,
      'filesystem_info',
      [
        _buildPathRow('Data Dir', _details?['applicationInfo']?['dataDir']),
        _buildPathRow(
          'Native Lib Dir',
          _details?['applicationInfo']?['nativeLibraryDir'],
        ),
        _buildPathRow('Source Dir', _details?['applicationInfo']?['sourceDir']),
        _buildPathRow(
          'Public Source',
          _details?['applicationInfo']?['publicSourceDir'],
        ),
      ],
    );
  }

  Widget _buildProcessInfoCard() {
    final processData = _processInfo ?? {};
    final running = processData['running']?.toString().toLowerCase() == 'true';

    return _buildCollapsibleCard(
      'Process',
      Icons.memory,
      'process_info',
      !running
          ? [
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('App is not currently running'),
                ),
              ),
            ]
          : [
              _buildInfoRow('PID', processData['pid']?.toString() ?? 'Unknown'),
              _buildInfoRow(
                'CPU Stats Available',
                processData['cpu_stat_available'] == true ? 'YES' : 'NO',
              ),
              _buildInfoRow('VM Peak', processData['VmPeak'] ?? 'Unknown'),
              _buildInfoRow('VM Size', processData['VmSize'] ?? 'Unknown'),
              _buildInfoRow('VM RSS', processData['VmRSS'] ?? 'Unknown'),
            ],
    );
  }

  Widget _buildActivitiesSection() {
    final activities = List<Map<String, dynamic>>.from(
      _details?['activities'] ?? [],
    );

    return _buildCollapsibleCard(
      'Activities',
      Icons.launch,
      'activities',
      activities
          .map((activity) => _buildComponentItem(activity, 'Activity'))
          .toList(),
      count: activities.length,
    );
  }

  Widget _buildProvidersSection() {
    final providers = List<Map<String, dynamic>>.from(
      _details?['providers'] ?? [],
    );

    return _buildCollapsibleCard(
      'Providers',
      Icons.cloud_outlined,
      'providers',
      providers
          .map((provider) => _buildComponentItem(provider, 'Provider'))
          .toList(),
      count: providers.length,
    );
  }

  Widget _buildReceiversSection() {
    final receivers = List<Map<String, dynamic>>.from(
      _details?['receivers'] ?? [],
    );

    return _buildCollapsibleCard(
      'Receivers',
      Icons.sensors,
      'receivers',
      receivers
          .map((receiver) => _buildComponentItem(receiver, 'Receiver'))
          .toList(),
      count: receivers.length,
    );
  }

  Widget _buildComponentItem(Map<String, dynamic> component, String type) {
    final cs = Theme.of(context).colorScheme;
    final name = component['name'] ?? 'Unknown';
    final exported = component['exported'] == true;
    final enabled = component['enabled'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outline.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.split('.').last,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (exported)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'EXPORTED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              if (!enabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'DISABLED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleCard(
    String title,
    IconData icon,
    String sectionKey,
    List<Widget> children, {
    int? count,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isExpanded = _expandedSections.contains(sectionKey);

    if (_searchQuery.isNotEmpty) {
      final searchText = '$title ${children.toString()}'.toLowerCase();
      if (!searchText.contains(_searchQuery)) {
        return const SizedBox.shrink();
      }
    }

    final displayTitle = count != null ? '$title ($count)' : title;

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
                _expandedSections.remove(sectionKey);
              } else {
                _expandedSections.add(sectionKey);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Icon(icon, size: 16, color: cs.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${children.length} ${children.length == 1 ? 'item' : 'items'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
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
                    '$title Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...children,
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPathRow(String label, String? path) {
    if (path == null || path.isEmpty) return _buildInfoRow(label, 'Unknown');

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _openInFileExplorer(path),
                child: Text(
                  _formatPath(path),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: cs.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _openInFileExplorer(path),
            child: Icon(Icons.folder_open, size: 14, color: cs.primary),
          ),
        ],
      ),
    );
  }

  void _openInFileExplorer(String path) {
    context.go('/files?path=$path');
  }

  Widget _buildBadge(String label, bool value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData? icon,
    Color color,
    VoidCallback? onTap, {
    bool isLoading = false,
  }) {
    Widget iconChild;
    if (isLoading) {
      iconChild = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    } else if (icon != null) {
      iconChild = Icon(icon, size: 16, color: color);
    } else {
      iconChild = const SizedBox.shrink();
    }

    return FilledButton.tonalIcon(
      onPressed: isLoading ? null : onTap,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          return color.withAlpha(25);
        }),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: color),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
        minimumSize: WidgetStateProperty.all(Size.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: iconChild,
      label: Text(
        isLoading ? 'Loading...' : label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSignatureCard() {
    final signatures = _signatures;
    final signaturesList = signatures != null
        ? List<Map<String, dynamic>>.from(signatures['signatures'] ?? [])
        : <Map<String, dynamic>>[];

    final signatureWidgets = signatures == null
        ? [const Center(child: CircularProgressIndicator())]
        : signaturesList
              .map(
                (sig) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withAlpha(15),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Algorithm', sig['algorithm'] ?? 'Unknown'),
                      _buildInfoRow('Subject', sig['subject'] ?? 'Unknown'),
                      _buildInfoRow('Issuer', sig['issuer'] ?? 'Unknown'),
                      _buildInfoRow(
                        'Valid From',
                        sig['notBefore'] ?? 'Unknown',
                      ),
                      _buildInfoRow(
                        'Valid Until',
                        sig['notAfter'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('MD5', sig['md5'] ?? 'Unknown'),
                      _buildInfoRow('SHA1', sig['sha1'] ?? 'Unknown'),
                      _buildInfoRow('SHA256', sig['sha256'] ?? 'Unknown'),
                    ],
                  ),
                ),
              )
              .toList();

    return _buildCollapsibleCard(
      'Signatures',
      Icons.verified_user,
      'signatures',
      signatureWidgets,
      count: signatures != null ? (signatures['signatureCount'] ?? 0) : null,
    );
  }

  Widget _buildPermissionsCard() {
    final permissions = _permissions;

    return _buildCollapsibleCard(
      'Permissions',
      Icons.lock,
      'permissions',
      permissions == null
          ? [const Center(child: CircularProgressIndicator())]
          : List<String>.from(permissions['all'] ?? []).map((perm) {
              final isGranted = Set<String>.from(
                permissions['granted'] ?? [],
              ).contains(perm);
              return _buildPermissionRow(perm, isGranted);
            }).toList(),
      count: permissions != null
          ? List<String>.from(permissions['all'] ?? []).length
          : null,
    );
  }

  Widget _buildPermissionRow(String permission, bool isGranted) {
    final cs = Theme.of(context).colorScheme;
    final color = isGranted ? Colors.green : Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outline.withAlpha(15)),
      ),
      child: Row(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.split('.').last,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  permission,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildPermissionActionButton(permission, isGranted),
        ],
      ),
    );
  }

  Widget _buildPermissionActionButton(String permission, bool isGranted) {
    final isLoading = _sectionLoading['perm_$permission'] == true;
    final buttonColor = isGranted ? Colors.red : Colors.green;
    final buttonText = isGranted ? 'Revoke' : 'Grant';
    final buttonIcon = isGranted ? Icons.block : Icons.check;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () => _togglePermission(permission, isGranted),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: buttonColor.withAlpha(25),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: buttonColor.withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
                  ),
                )
              else
                Icon(buttonIcon, size: 12, color: buttonColor),
              const SizedBox(width: 4),
              Text(
                buttonText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: buttonColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePermission(
    String permission,
    bool isCurrentlyGranted,
  ) async {
    if (widget.package == null) return;

    setState(() {
      _sectionLoading['perm_$permission'] = true;
      _sectionErrors['perm_$permission'] = null;
    });

    try {
      final packageName = widget.package!.packageName;

      if (isCurrentlyGranted) {
        await widget.repository.revokePermission(packageName, permission);
      } else {
        await widget.repository.grantPermission(packageName, permission);
      }

      _loadSection(
        'permissions',
        () => widget.repository.getAllPermissions(packageName),
      );

      if (mounted) {
        context.showSuccessSnackBar(
          '${isCurrentlyGranted ? 'Revoked' : 'Granted'} $permission',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sectionErrors['perm_$permission'] = e.toString();
        });
        context.showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _sectionLoading['perm_$permission'] = false;
        });
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _copy('$label: $value', label),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            Icon(Icons.copy, size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatPath(String? path) {
    if (path == null || path.isEmpty) return 'Unknown';
    // Shorten long paths for better display
    if (path.length > 40) {
      final parts = path.split('/');
      if (parts.length > 3) {
        return '.../${parts[parts.length - 2]}/${parts.last}';
      }
    }
    return path;
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    context.showInfoSnackBar('$label copied to clipboard');
  }

  Future<void> _clearCache() async {
    try {
      await widget.repository.clearPackageCache(widget.package!.packageName);
      if (mounted) {
        context.showSuccessSnackBar('Cache cleared successfully');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString());
      }
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Data'),
        content: Text(
          'Are you sure you want to clear all data for ${widget.package!.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.repository.clearPackageData(widget.package!.packageName);
        if (mounted) {
          context.showSuccessSnackBar('Data cleared successfully');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar(e.toString());
        }
      }
    }
  }
}
