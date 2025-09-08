import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jezail_ui/repositories/controls_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

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
  String? selinuxStatus;
  String? clipboardContent;
  bool loading = false;
  late AnimationController anim;
  Set<String> expandedControls = {};

  @override
  void initState() {
    super.initState();
    anim = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    loadSelinuxStatus();
    loadClipboard();
  }

  @override
  void dispose() {
    keycodeController.dispose();
    clipboardController.dispose();
    propertyKeyController.dispose();
    propertyValueController.dispose();
    anim.dispose();
    super.dispose();
  }

  Future<void> loadSelinuxStatus() async {
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
    HapticFeedback.lightImpact();
    await action('Keycode $code sent', () => widget.repository.keycode(code));
    keycodeController.clear();
  }

  Future<void> toggleSelinux() async {
    HapticFeedback.mediumImpact();
    await action('SELinux toggled', () async {
      final currentStatus = selinuxStatus?.toLowerCase() ?? '';
      final enable = !currentStatus.contains('enforcing');
      await widget.repository.toggleSelinux(enable);
      await loadSelinuxStatus();
    });
  }

  Future<void> sendQuickKey(int keycode) async {
    HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
    await action('Clipboard updated', () async {
      await widget.repository.setClipboard(clipboardController.text);
      await loadClipboard();
    });
  }

  Future<void> clearClipboard() async {
    HapticFeedback.mediumImpact();
    await action('Clipboard cleared', () async {
      await widget.repository.clearClipboard();
      clipboardController.clear();
      await loadClipboard();
    });
  }

  Future<void> downloadScreenshot() async {
    HapticFeedback.heavyImpact();
    await action('Screenshot downloaded', () => widget.repository.takeScreenshot());
  }

  Future<void> getSystemProperty() async {
    final key = propertyKeyController.text.trim();
    if (key.isEmpty) return context.showErrorSnackBar('Enter property key');
    
    HapticFeedback.lightImpact();
    try {
      final value = await widget.repository.getSystemProperty(key);
      propertyValueController.text = value;
      if (mounted) context.showSuccessSnackBar('Property retrieved: $key');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to get property: $e');
    }
  }

  Future<void> setSystemProperty() async {
    final key = propertyKeyController.text.trim();
    final value = propertyValueController.text.trim();
    if (key.isEmpty) return context.showErrorSnackBar('Enter property key');
    if (value.isEmpty) return context.showErrorSnackBar('Enter property value');
    
    HapticFeedback.mediumImpact();
    await action('Property set: $key', () => widget.repository.setSystemProperty(key, value));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controls = [
      _ControlConfig('selinux', Icons.security, 'SELinux Control', 'Status: ${selinuxStatus ?? 'Loading...'}'),
      _ControlConfig('keycode', Icons.keyboard_alt, 'Keycode Injection', 'Send key events to device'),
      _ControlConfig('clipboard', Icons.content_paste, 'Clipboard', clipboardContent?.isEmpty == true ? 'Empty' : clipboardContent ?? 'Loading...'),
      _ControlConfig('properties', Icons.settings, 'System Properties', 'Get/Set device system properties'),
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
            
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
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
                        expandedControls.remove(control.id);
                      } else {
                        expandedControls.add(control.id);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(6)),
                          child: Center(child: Icon(control.icon, size: 16, color: cs.onPrimaryContainer)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(control.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(control.subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        const SizedBox(width: 8),
                        if (control.id == 'selinux' && loading)
                          SizedBox(
                            width: 16, height: 16,
                            child: RotationTransition(turns: anim, child: Icon(Icons.refresh, color: cs.primary, size: 16)),
                          )
                        else if (control.id == 'selinux')
                          GestureDetector(
                            onTap: loadSelinuxStatus,
                            child: Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(color: cs.primary.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                              child: Icon(Icons.refresh, size: 12, color: cs.primary),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                      ]),
                    ),
                  ),
                  if (isExpanded) ...{
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
                          _buildControlDetails(control.id, cs),
                        ],
                      ),
                    ),
                  },
                ],
              ),
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
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => sendKeycode(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: keycodeController.text.isNotEmpty ? sendKeycode : null,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: const Text('Send', style: TextStyle(fontSize: 12)),
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
              GestureDetector(
                onTap: loadClipboard,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: cs.primary.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                  child: Icon(Icons.refresh, size: 12, color: cs.primary),
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
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(children: [
              FilledButton(
                onPressed: clipboardController.text.isNotEmpty ? setClipboard : null,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                child: const Text('Set', style: TextStyle(fontSize: 12)),
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
              onChanged: (_) => setState(() {}),
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
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Row(children: [
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