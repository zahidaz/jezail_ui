import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;
import 'package:jezail_ui/models/packages/package_info.dart';
import 'package:jezail_ui/repositories/package_repository.dart';
import 'package:jezail_ui/services/device_service.dart';
import 'package:jezail_ui/core/enums/package_enums.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/tabs/packages/package_list_page.dart';
import 'package:jezail_ui/presentation/tabs/packages/widgets/package_info_widgets.dart';
import 'package:jezail_ui/presentation/tabs/packages/widgets/package_component_item.dart';
import 'package:jezail_ui/presentation/widgets/collapsible_card.dart';

class PackageDetailsPage extends StatefulWidget {
  final PackageInfo? package;
  final PackageRepository repository;
  final DeviceService? deviceService;
  final Function(PackageAction, PackageInfo) onPackageAction;
  final VoidCallback onBack;

  const PackageDetailsPage({
    super.key,
    this.package,
    required this.repository,
    this.deviceService,
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
  List<String>? _appOps;
  bool? _isDebuggable;
  bool? _isRunning;

  final Map<String, bool> _sectionLoading = {};
  final Map<String, String?> _sectionErrors = {};
  final Map<String, bool> _actionLoading = {};
  String _searchQuery = '';
  Timer? _searchDebounce;
  final Set<String> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    if (widget.package != null) {
      _loadPackageData();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(PackageDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.package?.packageName != oldWidget.package?.packageName && widget.package != null) {
      _details = null;
      _permissions = null;
      _signatures = null;
      _processInfo = null;
      _appOps = null;
      _isDebuggable = null;
      _isRunning = null;
      _sectionLoading.clear();
      _sectionErrors.clear();
      _expandedSections.clear();
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
    if (widget.deviceService != null) {
      _loadSection(
        'appOps',
        () => widget.deviceService!.getAppOps(packageName),
      );
    }
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
            case 'appOps':
              _appOps = List<String>.from(result['data'] ?? []);
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
        context.showErrorSnackBar('Failed to load $section');
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
                if (_appOps != null) ...[
                  const SizedBox(height: 16),
                  _buildAppOpsSection(),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (pkg.canLaunch)
          _buildActionButton(
            isRunning ? 'Stop' : 'Start',
            isRunning ? Icons.stop : Icons.play_arrow,
            isRunning ? Colors.red : Colors.green,
            () async {
              final action = isRunning
                  ? PackageAction.stop
                  : PackageAction.start;
              if (mounted) setState(() => _sectionLoading['running'] = true);
              try {
                await widget.onPackageAction(action, pkg);
                await Future.delayed(const Duration(milliseconds: 500));
                await _loadSection(
                  'running',
                  () => widget.repository.isPackageRunning(pkg.packageName),
                );
              } catch (e) {
                if (mounted) setState(() => _sectionLoading['running'] = false);
              }
            },
            isLoading: _sectionLoading['running'] == true,
          ),
        _buildActionButton(
          'Clear Cache',
          Icons.cached,
          Colors.orange,
          _clearCache,
          isLoading: _actionLoading['clearCache'] == true,
        ),
        _buildActionButton(
          'Clear Data',
          Icons.delete_sweep,
          Colors.red,
          _clearData,
          isLoading: _actionLoading['clearData'] == true,
        ),
        _buildActionButton(
          'Download',
          Icons.download,
          Colors.blue,
          _downloadApk,
        ),
        _buildActionButton(
          'Backup',
          Icons.backup,
          Colors.teal,
          _backupApp,
        ),
        if (pkg.canLaunch)
          _buildActionButton(
            'Foreground',
            Icons.open_in_new,
            Colors.indigo,
            _bringToForeground,
            isLoading: _actionLoading['foreground'] == true,
          ),
        _buildActionButton('Uninstall', Icons.delete, Colors.red, () async {
          try {
            await widget.onPackageAction(PackageAction.uninstall, pkg);
            if (mounted) {
              widget.onBack();
            }
          } catch (_) {}
        }),
        IconButton(
          onPressed: _loadPackageData,
          icon: Icon(Icons.refresh, color: cs.primary, size: 20),
          tooltip: 'Refresh package data',
          style: IconButton.styleFrom(
            backgroundColor: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.outline.withAlpha(25)),
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
        ((_signatures?['signatures'] as List?)?.firstOrNull as Map?)?['subject']?.toString().contains('Debug') ??
        false;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        PackageBadge(
          label: pkg.isSystemApp ? 'System' : 'User',
          value: true,
          color: pkg.isSystemApp ? Colors.orange : Colors.blue,
          icon: pkg.isSystemApp ? Icons.settings : Icons.person,
        ),
        if (isDebuggable != null)
          PackageBadge(
            label: 'Debuggable',
            value: isDebuggable,
            color: isDebuggable ? Colors.red : Colors.green,
            icon: isDebuggable ? Icons.bug_report : Icons.verified_user,
          ),
        if (hasDebugCert)
          const PackageBadge(
            label: 'Debug Cert',
            value: true,
            color: Colors.red,
            icon: Icons.warning,
          ),
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
                onChanged: (value) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) setState(() => _searchQuery = value.toLowerCase());
                  });
                },
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
    final version = _details?['versionName'] ?? 'Unknown';
    final versionCode = _details?['versionCode']?.toString() ?? 'Unknown';
    final firstInstall = _formatTimestamp(_details?['firstInstallTime']);
    final lastUpdate = _formatTimestamp(_details?['lastUpdateTime']);
    return _buildCollapsibleCard('Versions', Icons.tag, 'version_install', [
      PackageInfoRow(label: 'Version', value: version),
      PackageInfoRow(label: 'Version Code', value: versionCode),
      PackageInfoRow(label: 'First Install', value: firstInstall),
      PackageInfoRow(label: 'Last Update', value: lastUpdate),
    ], searchableContent: '$version $versionCode $firstInstall $lastUpdate');
  }

  Widget _buildTechnicalInfoSection() {
    final targetSdk = _details?['applicationInfo']?['targetSdkVersion']?.toString() ?? 'Unknown';
    final minSdk = _details?['applicationInfo']?['minSdkVersion']?.toString() ?? 'Unknown';
    final compileSdk = _details?['applicationInfo']?['compileSdkVersion']?.toString() ?? 'Unknown';
    final uid = _details?['applicationInfo']?['uid']?.toString() ?? 'Unknown';
    return _buildCollapsibleCard(
      'Runtime',
      Icons.developer_mode,
      'technical_info',
      [
        PackageInfoRow(label: 'Target SDK', value: targetSdk),
        PackageInfoRow(label: 'Min SDK', value: minSdk),
        PackageInfoRow(label: 'Compile SDK', value: compileSdk),
        PackageInfoRow(label: 'UID', value: uid),
      ],
      searchableContent: '$targetSdk $minSdk $compileSdk $uid',
    );
  }

  Widget _buildSecurityInfoSection() {
    final pkg = widget.package!;
    final isDebuggable = _isDebuggable;
    final hasDebugCert =
        ((_signatures?['signatures'] as List?)?.firstOrNull as Map?)?['subject']?.toString().contains('Debug') ??
        false;

    final debuggableText = isDebuggable != null ? (isDebuggable ? 'YES' : 'NO') : 'Unknown';
    final debugCertText = hasDebugCert ? 'YES' : 'NO';
    final systemAppText = pkg.isSystemApp ? 'YES' : 'NO';
    final enabledText = _details?['applicationInfo']?['enabled'] == true ? 'YES' : 'NO';
    return _buildCollapsibleCard('Security', Icons.security, 'security_info', [
      PackageInfoRow(label: 'Debuggable', value: debuggableText),
      PackageInfoRow(label: 'Debug Certificate', value: debugCertText),
      PackageInfoRow(label: 'System App', value: systemAppText),
      PackageInfoRow(label: 'Enabled', value: enabledText),
    ], searchableContent: 'debuggable $debuggableText debug certificate $debugCertText system $systemAppText enabled $enabledText');
  }

  Widget _buildFileSystemInfoSection() {
    final dataDir = _details?['applicationInfo']?['dataDir']?.toString() ?? '';
    final nativeLibDir = _details?['applicationInfo']?['nativeLibraryDir']?.toString() ?? '';
    final sourceDir = _details?['applicationInfo']?['sourceDir']?.toString() ?? '';
    final publicSourceDir = _details?['applicationInfo']?['publicSourceDir']?.toString() ?? '';
    return _buildCollapsibleCard(
      'Filesystem',
      Icons.folder_outlined,
      'filesystem_info',
      [
        PackagePathRow(label: 'Data Dir', path: _details?['applicationInfo']?['dataDir'], onOpenInFileExplorer: _openInFileExplorer),
        PackagePathRow(label: 'Native Lib Dir', path: _details?['applicationInfo']?['nativeLibraryDir'], onOpenInFileExplorer: _openInFileExplorer),
        PackagePathRow(label: 'Source Dir', path: _details?['applicationInfo']?['sourceDir'], onOpenInFileExplorer: _openInFileExplorer),
        PackagePathRow(label: 'Public Source', path: _details?['applicationInfo']?['publicSourceDir'], onOpenInFileExplorer: _openInFileExplorer),
      ],
      searchableContent: '$dataDir $nativeLibDir $sourceDir $publicSourceDir',
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
              PackageInfoRow(label: 'PID', value: processData['pid']?.toString() ?? 'Unknown'),
              PackageInfoRow(
                label: 'CPU Stats Available',
                value: processData['cpu_stat_available'] == true ? 'YES' : 'NO',
              ),
              PackageInfoRow(label: 'VM Peak', value: processData['VmPeak'] ?? 'Unknown'),
              PackageInfoRow(label: 'VM Size', value: processData['VmSize'] ?? 'Unknown'),
              PackageInfoRow(label: 'VM RSS', value: processData['VmRSS'] ?? 'Unknown'),
            ],
    );
  }

  Widget _buildActivitiesSection() {
    final activities = (_details?['activities'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList() ?? [];

    return _buildCollapsibleCard(
      'Activities',
      Icons.launch,
      'activities',
      activities
          .map((activity) => PackageComponentItem(component: activity, type: 'Activity'))
          .toList(),
      count: activities.length,
      searchableContent: activities.map((a) => a['name']?.toString() ?? '').join(' '),
    );
  }

  Widget _buildProvidersSection() {
    final providers = (_details?['providers'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList() ?? [];

    return _buildCollapsibleCard(
      'Providers',
      Icons.cloud_outlined,
      'providers',
      providers
          .map((provider) => PackageComponentItem(component: provider, type: 'Provider'))
          .toList(),
      count: providers.length,
      searchableContent: providers.map((p) => p['name']?.toString() ?? '').join(' '),
    );
  }

  Widget _buildReceiversSection() {
    final receivers = (_details?['receivers'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .toList() ?? [];

    return _buildCollapsibleCard(
      'Receivers',
      Icons.sensors,
      'receivers',
      receivers
          .map((receiver) => PackageComponentItem(component: receiver, type: 'Receiver'))
          .toList(),
      count: receivers.length,
      searchableContent: receivers.map((r) => r['name']?.toString() ?? '').join(' '),
    );
  }

  Widget _buildCollapsibleCard(
    String title,
    IconData icon,
    String sectionKey,
    List<Widget> children, {
    int? count,
    String? searchableContent,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isExpanded = _expandedSections.contains(sectionKey);

    if (_searchQuery.isNotEmpty) {
      final searchText = '$title ${searchableContent ?? ''}'.toLowerCase();
      if (!searchText.contains(_searchQuery)) {
        return const SizedBox.shrink();
      }
    }

    final displayTitle = count != null ? '$title ($count)' : title;

    return CollapsibleCard(
      title: displayTitle,
      icon: icon,
      isExpanded: isExpanded,
      onToggle: () => setState(() {
        if (isExpanded) {
          _expandedSections.remove(sectionKey);
        } else {
          _expandedSections.add(sectionKey);
        }
      }),
      subtitle: '${children.length} ${children.length == 1 ? 'item' : 'items'}',
      children: [
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
    );
  }

  void _openInFileExplorer(String path) {
    context.go('/files?path=${Uri.encodeComponent(path)}');
  }

  void _downloadApk() {
    if (widget.package == null) return;
    final url = widget.repository.getApkDownloadUrl(widget.package!.packageName);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = '${widget.package!.packageName}.apk';
    anchor.click();
    context.showSuccessSnackBar('APK download started');
  }

  void _backupApp() {
    if (widget.package == null) return;
    final url = widget.repository.getBackupUrl(widget.package!.packageName);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = '${widget.package!.packageName}_backup.zip';
    anchor.click();
    context.showSuccessSnackBar('Backup download started');
  }

  Future<void> _bringToForeground() async {
    if (widget.package == null) return;
    setState(() => _actionLoading['foreground'] = true);
    await context.runWithFeedback(
      action: () => widget.repository.bringToForeground(widget.package!.packageName),
      successMessage: '${widget.package!.name} brought to foreground',
      errorMessage: 'Failed to bring app to foreground',
    );
    if (mounted) setState(() => _actionLoading['foreground'] = false);
  }

  Widget _buildAppOpsSection() {
    final ops = _appOps ?? [];
    return _buildCollapsibleCard(
      'App Ops',
      Icons.app_settings_alt,
      'app_ops',
      ops.map((op) => PackageInfoRow(
        label: op.contains(':') ? op.split(':').first.trim() : op,
        value: op.contains(':') ? op.split(':').sublist(1).join(':').trim() : '',
      )).toList(),
      count: ops.length,
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
                      PackageInfoRow(label: 'Algorithm', value: sig['algorithm'] ?? 'Unknown'),
                      PackageInfoRow(label: 'Subject', value: sig['subject'] ?? 'Unknown'),
                      PackageInfoRow(label: 'Issuer', value: sig['issuer'] ?? 'Unknown'),
                      PackageInfoRow(
                        label: 'Valid From',
                        value: sig['notBefore'] ?? 'Unknown',
                      ),
                      PackageInfoRow(
                        label: 'Valid Until',
                        value: sig['notAfter'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 8),
                      PackageInfoRow(label: 'MD5', value: sig['md5'] ?? 'Unknown'),
                      PackageInfoRow(label: 'SHA1', value: sig['sha1'] ?? 'Unknown'),
                      PackageInfoRow(label: 'SHA256', value: sig['sha256'] ?? 'Unknown'),
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
    final allPerms = permissions != null ? List<String>.from(permissions['all'] ?? []) : <String>[];

    return _buildCollapsibleCard(
      'Permissions',
      Icons.lock,
      'permissions',
      permissions == null
          ? [const Center(child: CircularProgressIndicator())]
          : allPerms.map((perm) {
              final isGranted = Set<String>.from(
                permissions['granted'] ?? [],
              ).contains(perm);
              return _buildPermissionRow(perm, isGranted);
            }).toList(),
      count: permissions != null ? allPerms.length : null,
      searchableContent: allPerms.join(' '),
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

    return TextButton.icon(
      onPressed: isLoading
          ? null
          : () => _togglePermission(permission, isGranted),
      icon: isLoading
          ? SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
              ),
            )
          : Icon(buttonIcon, size: 12, color: buttonColor),
      label: Text(
        buttonText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: buttonColor,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: buttonColor.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: buttonColor.withAlpha(50)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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


  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    context.showInfoSnackBar('$label copied to clipboard');
  }

  Future<void> _clearCache() async {
    setState(() => _actionLoading['clearCache'] = true);
    try {
      await widget.repository.clearPackageCache(widget.package!.packageName);
      if (mounted) {
        context.showSuccessSnackBar('Cache cleared successfully');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) setState(() => _actionLoading['clearCache'] = false);
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
      setState(() => _actionLoading['clearData'] = true);
      try {
        await widget.repository.clearPackageData(widget.package!.packageName);
        if (mounted) {
          context.showSuccessSnackBar('Data cleared successfully');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar(e.toString());
        }
      } finally {
        if (mounted) setState(() => _actionLoading['clearData'] = false);
      }
    }
  }
}
