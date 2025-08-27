import 'package:jezail_ui/main.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  static const _description =
      'An Android penetration testing toolkit that transforms your rooted device into a comprehensive security testing platform. Provides complete device control, system monitoring, application management, and dynamic analysis capabilities through REST API and web interface.';

  static const _links = [
    _LinkData('Source Code', Icons.code, 'https://github.com/zahidaz/jezail'),
    _LinkData('Blog', Icons.article, 'https://blog.azzahid.com'),
    _LinkData('Website', Icons.web, 'https://azzahid.com'),
    _LinkData(
      'YouTube',
      Icons.video_library,
      'https://www.youtube.com/@xahidx',
    ),
  ];

  static const _dependencies = [
    _DependencyData(
      'libsu',
      'https://github.com/topjohnwu/libsu',
      'Root access functionality',
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
              _AppOverviewCard(appName: appName, description: _description),
              const SizedBox(height: 16),
              _DeveloperCard(links: _links, onLinkTap: _launchUrl),
              const SizedBox(height: 16),
              _DependenciesCard(
                dependencies: _dependencies,
                onLinkTap: _launchUrl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppOverviewCard extends StatelessWidget {
  const _AppOverviewCard({required this.appName, required this.description});

  final String appName;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({required this.links, required this.onLinkTap});

  final List<_LinkData> links;
  final Future<void> Function(String) onLinkTap;

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
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Developer: Zahid',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: links
                  .map(
                    (link) => ActionChip(
                      avatar: Icon(link.icon, size: 18),
                      label: Text(link.label),
                      onPressed: () => onLinkTap(link.url),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DependenciesCard extends StatelessWidget {
  const _DependenciesCard({
    required this.dependencies,
    required this.onLinkTap,
  });

  final List<_DependencyData> dependencies;
  final Future<void> Function(String) onLinkTap;

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
                Icons.build_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Built with',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ...dependencies.map(
              (dep) => ListTile(
                contentPadding: const EdgeInsets.only(left: 8.0),
                leading: Icon(
                  Icons.security,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
                title: InkWell(
                  onTap: () => onLinkTap(dep.url),
                  child: Text(
                    dep.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                subtitle: Text(dep.description),
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkData {
  const _LinkData(this.label, this.icon, this.url);

  final String label;
  final IconData icon;
  final String url;
}

class _DependencyData {
  const _DependencyData(this.name, this.url, this.description);

  final String name;
  final String url;
  final String description;
}
