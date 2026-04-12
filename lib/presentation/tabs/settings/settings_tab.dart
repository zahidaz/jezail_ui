import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jezail_ui/app_config.dart';
import 'package:jezail_ui/services/api_service.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/main.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, this.apiService});
  final ApiService? apiService;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String? _apiStatus;

  @override
  void initState() {
    super.initState();
    _checkApiStatus();
  }

  Future<void> _checkApiStatus() async {
    if (widget.apiService == null) return;
    try {
      final result = await widget.apiService!.get('/status');
      if (mounted) setState(() => _apiStatus = result?['data']?['status']?.toString() ?? 'ok');
    } catch (_) {
      if (mounted) setState(() => _apiStatus = 'error');
    }
  }

  static const List<_LinkItem> _apiItems = [
    _LinkItem(Icons.dashboard, 'Swagger UI', '/api/swagger'),
    _LinkItem(Icons.data_object, 'OpenAPI JSON', '/api/json'),
  ];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      context.showErrorSnackBar('Could not open URL');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOk = _apiStatus == 'ok';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 12, color: _apiStatus == null ? Colors.grey : isOk ? Colors.green : Colors.red),
                      const SizedBox(width: 12),
                      Text('API Status', style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      Text(
                        _apiStatus ?? 'Checking...',
                        style: TextStyle(
                          color: _apiStatus == null ? cs.onSurfaceVariant : isOk ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _checkApiStatus,
                        icon: Icon(Icons.refresh, size: 18, color: cs.primary),
                        tooltip: 'Refresh status',
                        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ThemeCard(),
              const SizedBox(height: 16),
              _LinkCard(
                icon: Icons.api,
                title: 'API Documentation',
                items: _apiItems,
                onItemTap: _launchUrl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  final IconData icon;
  final String title;
  final List<_LinkItem> items;
  final Future<void> Function(String) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => ActionChip(
                avatar: Icon(item.icon, size: 18),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.title),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ],
                ),
                onPressed: () => onItemTap('${AppConfig.baseUrl}${item.urlPath}'),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 12,
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkItem {
  const _LinkItem(this.icon, this.title, this.urlPath);

  final IconData icon;
  final String title;
  final String urlPath;
}

class _ThemeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = ThemeModeNotifier.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_brightness, size: 18), label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 18), label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 18), label: Text('Dark')),
                ],
                selected: {mode},
                onSelectionChanged: (selection) {
                  themeNotifier.value = selection.first;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}