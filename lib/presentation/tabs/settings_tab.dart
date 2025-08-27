import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  static const _apiItems = [
    _ApiItem(
      icon: Icons.dashboard,
      title: 'Swagger UI',
      subtitle: 'Interactive API documentation',
      urlPath: '/api/swagger',
    ),
    _ApiItem(
      icon: Icons.data_object,
      title: 'OpenAPI JSON',
      subtitle: 'Raw OpenAPI specification',
      urlPath: '/api/json',
    ),
  ];

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              _ApiDocumentationCard(
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

class _ApiDocumentationCard extends StatelessWidget {
  const _ApiDocumentationCard({
    required this.items,
    required this.onItemTap,
  });

  final List<_ApiItem> items;
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
              leading: Icon(
                Icons.api,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'API Documentation',
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
                onPressed: () => onItemTap('${Uri.base.origin}${item.urlPath}'),
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

class _ApiItem {
  const _ApiItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.urlPath,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String urlPath;
}