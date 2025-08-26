import 'package:jezail_ui/main.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildClickableText(String text, String url, BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _launchUrl(url),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.blue.shade700,
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildLinkChip({
    required IconData icon,
    required String label,
    required String url,
    required BuildContext context,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => _launchUrl(url),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
        fontSize: 12,
      ),
    );
  }

  Widget _buildAppOverview(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
            'An Android penetration testing toolkit that transforms your rooted device into a comprehensive security testing platform. Provides complete device control, system monitoring, application management, and dynamic analysis capabilities through REST API and web interface.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDependenciesSection(BuildContext context) {
    return _buildSection(
      context: context,
      icon: Icons.build_circle,
      title: 'Built with',
      child: Row(
        children: [
          Icon(
            Icons.security,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
          ),
          const SizedBox(width: 8),
          _buildClickableText(
            'libsu',
            'https://github.com/topjohnwu/libsu',
            context,
          ),
          Text(
            ' - Root access functionality',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection(BuildContext context) {
    return _buildSection(
      context: context,
      icon: Icons.person,
      title: 'Developer: Zahid',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildLinkChip(
            icon: Icons.code,
            label: 'Source Code',
            url: 'https://github.com/zahidaz/jezail',
            context: context,
          ),
          _buildLinkChip(
            icon: Icons.article,
            label: 'Blog',
            url: 'https://blog.azzahid.com',
            context: context,
          ),
          _buildLinkChip(
            icon: Icons.web,
            label: 'Website',
            url: 'https://azzahid.com',
            context: context,
          ),
          _buildLinkChip(
            icon: Icons.video_library,
            label: 'YouTube',
            url: 'https://www.youtube.com/@xahidx',
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppOverview(context),
              const SizedBox(height: 16),
              _buildDeveloperSection(context),
              const SizedBox(height: 16),
              _buildDependenciesSection(context),
            ],
          ),
        ),
      ),
    );
  }
}
