import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jezail_ui/repositories/controls_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/widgets/collapsible_card.dart';

class ControlsTab extends StatefulWidget {
  const ControlsTab({super.key, required this.repository});
  final ControlsRepository repository;

  @override
  State<ControlsTab> createState() => _ControlsTabState();
}

class _ControlsTabState extends State<ControlsTab> with SingleTickerProviderStateMixin {
  final keycodeController = TextEditingController();
  final clipboardController = TextEditingController();
  final propertyKeyController = TextEditingController();
  final propertyValueController = TextEditingController();
  final textInputController = TextEditingController();
  final dnsController = TextEditingController();
  final privateDnsController = TextEditingController();
  final proxyHostController = TextEditingController();
  final proxyPortController = TextEditingController();
  String? selinuxStatus;
  String? clipboardContent;
  Map<String, dynamic>? dnsConfig;
  Map<String, dynamic>? proxyConfig;
  bool loading = false;
  late AnimationController anim;
  Set<String> expandedControls = {};

  @override
  void initState() {
    super.initState();
    anim = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    loadSelinuxStatus();
    loadClipboard();
    loadDnsConfig();
    loadProxyConfig();
  }

  @override
  void dispose() {
    keycodeController.dispose();
    clipboardController.dispose();
    propertyKeyController.dispose();
    propertyValueController.dispose();
    textInputController.dispose();
    dnsController.dispose();
    privateDnsController.dispose();
    proxyHostController.dispose();
    proxyPortController.dispose();
    anim.dispose();
    super.dispose();
  }

  Future<void> loadSelinuxStatus() async {
    if (!mounted) return;
    setState(() => loading = true);
    anim.repeat();
    try {
      final result = await widget.repository.getSelinuxStatus();
      if (mounted) setState(() => selinuxStatus = result['data']?.toString());
    } catch (_) {
      if (mounted) setState(() => selinuxStatus = 'Unknown');
    } finally {
      anim.stop();
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> action(String msg, Future<void> Function() fn) =>
      context.runWithFeedback(action: fn, successMessage: msg, errorMessage: 'Failed: $msg');

  Future<void> sendKeycode() async {
    final code = int.tryParse(keycodeController.text);
    if (code == null) return context.showErrorSnackBar('Invalid keycode');

    await action('Keycode $code sent', () => widget.repository.keycode(code));
    keycodeController.clear();
  }

  Future<void> toggleSelinux() async {

    await action('SELinux toggled', () async {
      final currentStatus = selinuxStatus?.toLowerCase() ?? '';
      final enable = !currentStatus.contains('enforcing');
      await widget.repository.toggleSelinux(enable);
      await loadSelinuxStatus();
    });
  }

  Future<void> sendQuickKey(int keycode) async {

    await action('Key sent', () => widget.repository.keycode(keycode));
  }

  Future<void> loadClipboard() async {
    try {
      final content = await widget.repository.getClipboard();
      if (mounted) {
        setState(() {
          clipboardContent = content;
          clipboardController.text = content ?? '';
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load clipboard: $e');
    }
  }

  Future<void> setClipboard() async {

    await action('Clipboard updated', () async {
      await widget.repository.setClipboard(clipboardController.text);
      await loadClipboard();
    });
  }

  Future<void> clearClipboard() async {

    await action('Clipboard cleared', () async {
      await widget.repository.clearClipboard();
      clipboardController.clear();
      await loadClipboard();
    });
  }

  void downloadScreenshot() {

    widget.repository.downloadScreenshot();
    context.showSuccessSnackBar('Screenshot download started');
  }

  Future<void> getSystemProperty() async {
    final key = propertyKeyController.text.trim();
    if (key.isEmpty) return context.showErrorSnackBar('Enter property key');
    

    try {
      final value = await widget.repository.getSystemProperty(key);
      propertyValueController.text = value;
      if (mounted) context.showSuccessSnackBar('Property retrieved: $key');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to get property: $e');
    }
  }

  Future<void> sendText() async {
    final text = textInputController.text;
    if (text.isEmpty) return context.showErrorSnackBar('Enter text to type');

    await action('Text sent', () => widget.repository.typeText(text));
    textInputController.clear();
  }

  Future<void> loadDnsConfig() async {
    try {
      final config = await widget.repository.getDnsConfig();
      if (mounted) {
        setState(() => dnsConfig = config);
        privateDnsController.text = config['privateDnsHost']?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load DNS config: $e');
    }
  }

  Future<void> setDns() async {
    final servers = dnsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (servers.isEmpty) return context.showErrorSnackBar('Enter DNS servers');
    await action('DNS updated', () async {
      await widget.repository.setDns(servers);
      await loadDnsConfig();
      dnsController.clear();
    });
  }

  Future<void> setPrivateDns() async {
    final host = privateDnsController.text.trim();
    if (host.isEmpty) return context.showErrorSnackBar('Enter hostname');
    await action('Private DNS set', () async {
      await widget.repository.setPrivateDns(host);
      await loadDnsConfig();
    });
  }

  Future<void> loadProxyConfig() async {
    try {
      final config = await widget.repository.getProxyConfig();
      if (mounted) {
        setState(() => proxyConfig = config);
        proxyHostController.text = config['host']?.toString() ?? '';
        final port = config['port'];
        proxyPortController.text = (port != null && port != 0) ? port.toString() : '';
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load proxy config: $e');
    }
  }

  Future<void> setProxy() async {
    final host = proxyHostController.text.trim();
    final port = int.tryParse(proxyPortController.text.trim()) ?? 0;
    if (host.isEmpty || port == 0) return context.showErrorSnackBar('Enter host and port');
    await action('Proxy set', () async {
      await widget.repository.setProxy(host, port);
      await loadProxyConfig();
    });
  }

  Future<void> setSystemProperty() async {
    final key = propertyKeyController.text.trim();
    final value = propertyValueController.text.trim();
    if (key.isEmpty) return context.showErrorSnackBar('Enter property key');
    if (value.isEmpty) return context.showErrorSnackBar('Enter property value');
    

    await action('Property set: $key', () => widget.repository.setSystemProperty(key, value));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controls = [
      _ControlConfig('selinux', Icons.security, 'SELinux Control', 'Status: ${selinuxStatus ?? 'Loading...'}'),
      _ControlConfig('textinput', Icons.text_fields, 'Text Input', 'Type text on device'),
      _ControlConfig('keycode', Icons.keyboard_alt, 'Keycode Injection', 'Send key events to device'),
      _ControlConfig('clipboard', Icons.content_paste, 'Clipboard', clipboardContent?.isEmpty == true ? 'Empty' : clipboardContent ?? 'Loading...'),
      _ControlConfig('properties', Icons.settings, 'System Properties', 'Get/Set device system properties'),
      _ControlConfig('dns', Icons.dns, 'DNS Config', dnsConfig?['privateDnsMode']?.toString() ?? 'Loading...'),
      _ControlConfig('proxy', Icons.router, 'Proxy Config', proxyConfig != null ? (proxyConfig!['host']?.toString().isNotEmpty == true ? '${proxyConfig!['host']}:${proxyConfig!['port']}' : 'Not set') : 'Loading...'),
      _ControlConfig('screenshot', Icons.screenshot, 'Screenshot', 'Capture device screen'),
    ];
    
    return Column(children: [
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controls.length,
          itemBuilder: (context, index) {
            final control = controls[index];
            final isExpanded = expandedControls.contains(control.id);

            return CollapsibleCard(
              title: control.title,
              icon: control.icon,
              isExpanded: isExpanded,
              onToggle: () => setState(() {
                if (isExpanded) {
                  expandedControls.remove(control.id);
                } else {
                  expandedControls.add(control.id);
                }
              }),
              subtitle: control.subtitle,
              trailing: control.id == 'selinux'
                  ? (loading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: RotationTransition(
                            turns: anim,
                            child: Icon(Icons.refresh, color: cs.primary, size: 16),
                          ),
                        )
                      : IconButton(
                          onPressed: loadSelinuxStatus,
                          icon: Icon(Icons.refresh, size: 12, color: cs.primary),
                          tooltip: 'Refresh status',
                          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: cs.primary.withAlpha(25),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ))
                  : null,
              children: [_buildControlDetails(control.id, cs)],
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildControlDetails(String controlId, ColorScheme cs) {
    switch (controlId) {
      case 'selinux':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SELinux Control', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.info_outline, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Current Status: ${selinuxStatus ?? 'Unknown'}', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              const Spacer(),
              FilledButton(
                onPressed: selinuxStatus != null ? toggleSelinux : null,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                child: const Text('Toggle', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ],
        );
      case 'textinput':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Text Input', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: textInputController,
                  decoration: const InputDecoration(
                    hintText: 'Text to type on device',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.text_fields),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => sendText(),
                ),
              ),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: textInputController,
                builder: (context, _) => FilledButton(
                  onPressed: textInputController.text.isNotEmpty ? sendText : null,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  child: const Text('Type', style: TextStyle(fontSize: 12)),
                ),
              ),
            ]),
          ],
        );
      case 'keycode':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keycode Injection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: keycodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Enter keycode',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.keyboard),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => sendKeycode(),
                ),
              ),
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: keycodeController,
                builder: (context, _) => FilledButton(
                  onPressed: keycodeController.text.isNotEmpty ? sendKeycode : null,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  child: const Text('Send', style: TextStyle(fontSize: 12)),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _QuickKeyButton('Back', 4, sendQuickKey),
                _QuickKeyButton('Home', 3, sendQuickKey),
                _QuickKeyButton('Menu', 82, sendQuickKey),
                _QuickKeyButton('Power', 26, sendQuickKey),
                _QuickKeyButton('Vol+', 24, sendQuickKey),
                _QuickKeyButton('Vol-', 25, sendQuickKey),
              ],
            ),
          ],
        );
      case 'clipboard':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Clipboard Management', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
              const Spacer(),
              IconButton(
                onPressed: loadClipboard,
                icon: Icon(Icons.refresh, size: 12, color: cs.primary),
                tooltip: 'Refresh clipboard',
                constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: cs.primary.withAlpha(25),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withAlpha(50),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Current:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(
                  clipboardContent?.isEmpty == true ? 'Empty' : clipboardContent ?? 'Loading...',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: clipboardController,
              decoration: const InputDecoration(
                labelText: 'New content',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(children: [
              ListenableBuilder(
                listenable: clipboardController,
                builder: (context, _) => FilledButton(
                  onPressed: clipboardController.text.isNotEmpty ? setClipboard : null,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  child: const Text('Set', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: clearClipboard,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ],
        );
      case 'properties':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('System Properties', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
            const SizedBox(height: 8),
            TextField(
              controller: propertyKeyController,
              decoration: const InputDecoration(
                labelText: 'Property key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
                isDense: true,
                hintText: 'e.g., ro.build.version.release',
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: propertyValueController,
              decoration: const InputDecoration(
                labelText: 'Property value',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.data_object),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: Listenable.merge([propertyKeyController, propertyValueController]),
              builder: (context, _) => Row(children: [
                FilledButton(
                  onPressed: propertyKeyController.text.isNotEmpty ? getSystemProperty : null,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  child: const Text('Get', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: propertyKeyController.text.isNotEmpty && propertyValueController.text.isNotEmpty ? setSystemProperty : null,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  child: const Text('Set', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
          ],
        );
      case 'dns':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('DNS Configuration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
              const Spacer(),
              IconButton(
                onPressed: loadDnsConfig,
                icon: Icon(Icons.refresh, size: 12, color: cs.primary),
                tooltip: 'Refresh DNS config',
                constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: cs.primary.withAlpha(25),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            if (dnsConfig != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh.withAlpha(50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Mode: ${dnsConfig!['privateDnsMode'] ?? 'Unknown'}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: dnsController,
              decoration: const InputDecoration(
                labelText: 'DNS Servers (comma-separated)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns),
                isDense: true,
                hintText: '8.8.8.8, 8.8.4.4',
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(children: [
              ListenableBuilder(
                listenable: dnsController,
                builder: (context, _) => FilledButton(
                  onPressed: dnsController.text.isNotEmpty ? setDns : null,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  child: const Text('Set DNS', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => action('DNS cleared', () async {
                  await widget.repository.clearDns();
                  await loadDnsConfig();
                }),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: privateDnsController,
              decoration: const InputDecoration(
                labelText: 'Private DNS Hostname',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                isDense: true,
                hintText: 'dns.google',
              ),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(children: [
              ListenableBuilder(
                listenable: privateDnsController,
                builder: (context, _) => FilledButton(
                  onPressed: privateDnsController.text.isNotEmpty ? setPrivateDns : null,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  child: const Text('Set Private DNS', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => action('Private DNS cleared', () async {
                  await widget.repository.clearPrivateDns();
                  await loadDnsConfig();
                }),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ]),
          ],
        );
      case 'proxy':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Proxy Configuration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
              const Spacer(),
              IconButton(
                onPressed: loadProxyConfig,
                icon: Icon(Icons.refresh, size: 12, color: cs.primary),
                tooltip: 'Refresh proxy config',
                constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: cs.primary.withAlpha(25),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: proxyHostController,
                  decoration: const InputDecoration(
                    labelText: 'Host',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.router),
                    isDense: true,
                    hintText: '192.168.1.100',
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: proxyPortController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: '8080',
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: Listenable.merge([proxyHostController, proxyPortController]),
              builder: (context, _) => Row(children: [
                FilledButton(
                  onPressed: proxyHostController.text.isNotEmpty && proxyPortController.text.isNotEmpty ? setProxy : null,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  child: const Text('Set Proxy', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: () => action('Proxy cleared', () async {
                    await widget.repository.clearProxy();
                    await loadProxyConfig();
                  }),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
          ],
        );
      case 'screenshot':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Screenshot', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
            const SizedBox(height: 8),
            Text(
              'Capture and download device screen',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: downloadScreenshot,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      default:
        return Container();
    }
  }
}

class _ControlConfig {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  
  _ControlConfig(this.id, this.icon, this.title, this.subtitle);
}

class _QuickKeyButton extends StatelessWidget {
  const _QuickKeyButton(this.label, this.keycode, this.onTap);
  final String label;
  final int keycode;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label, style: const TextStyle(fontSize: 11)),
    onPressed: () => onTap(keycode),
    avatar: const Icon(Icons.touch_app, size: 14),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
}