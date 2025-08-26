import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

class ControlsTab extends StatefulWidget {
  const ControlsTab({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<ControlsTab> createState() => _ControlsTabState();
}

class _ControlsTabState extends State<ControlsTab> with SingleTickerProviderStateMixin {
  final keycodeController = TextEditingController();
  String? selinuxStatus;
  bool loading = false;
  late AnimationController anim;

  @override
  void initState() {
    super.initState();
    anim = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    loadSelinuxStatus();
  }

  @override
  void dispose() {
    keycodeController.dispose();
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
      await widget.repository.toggleSelinux();
      await loadSelinuxStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withAlpha(25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.security, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              const Text('SELinux Control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const Spacer(),
              loading ? RotationTransition(turns: anim, child: Icon(Icons.refresh, color: cs.primary, size: 20))
                     : IconButton(onPressed: loadSelinuxStatus, icon: const Icon(Icons.refresh, size: 20)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text('Status: ${selinuxStatus ?? 'Loading...'}', 
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
              const Spacer(),
              FilledButton(
                onPressed: selinuxStatus != null ? toggleSelinux : null,
                child: const Text('Toggle'),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withAlpha(25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.keyboard_alt, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Keycode Injection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: keycodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Enter keycode (e.g., 4 for Back)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.keyboard),
                    suffixIcon: keycodeController.text.isNotEmpty ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => keycodeController.clear()),
                    ) : null,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => sendKeycode(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: keycodeController.text.isNotEmpty ? sendKeycode : null,
                child: const Text('Send'),
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickKeyButton('Back', 4, sendQuickKey),
                _QuickKeyButton('Home', 3, sendQuickKey),
                _QuickKeyButton('Menu', 82, sendQuickKey),
                _QuickKeyButton('Power', 26, sendQuickKey),
                _QuickKeyButton('Vol+', 24, sendQuickKey),
                _QuickKeyButton('Vol-', 25, sendQuickKey),
              ],
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> sendQuickKey(int keycode) async {
    HapticFeedback.lightImpact();
    await action('Key sent', () => widget.repository.keycode(keycode));
  }
}

class _QuickKeyButton extends StatelessWidget {
  const _QuickKeyButton(this.label, this.keycode, this.onTap);
  final String label;
  final int keycode;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label, style: const TextStyle(fontSize: 12)),
    onPressed: () => onTap(keycode),
    avatar: const Icon(Icons.touch_app, size: 16),
  );
}
