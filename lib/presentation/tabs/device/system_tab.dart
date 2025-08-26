import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

class SystemTab extends StatefulWidget {
  const SystemTab({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<SystemTab> with SingleTickerProviderStateMixin {
  Map<String, dynamic> buildInfo = {};
  Map<String, dynamic> allProps = {};
  String filter = '';
  bool loading = false;
  Timer? debounce;
  late AnimationController anim;

  Map<String, dynamic> get filteredProps => filter.isEmpty ? allProps : 
    Map.fromEntries(allProps.entries.where((e) => 
      '${e.key} ${e.value}'.toLowerCase().contains(filter.toLowerCase())));

  @override
  void initState() {
    super.initState();
    anim = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    load();
  }

  @override
  void dispose() {
    anim.dispose();
    debounce?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    if (loading) return;
    setState(() => loading = true);
    anim.repeat();
    try {
      final results = await Future.wait([
        widget.repository.getBuildInfo(),
        widget.repository.getSystemProperties(),
      ]);
      if (mounted) {
        setState(() {
          buildInfo = results[0]['data'] ?? {};
          allProps = results[1]['data'] ?? {};
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load system info');
    } finally {
      anim.stop();
      if (mounted) setState(() => loading = false);
    }
  }

  void onSearch(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => filter = value);
    });
  }

  void copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    context.showSuccessSnackBar('$label copied');
  }

  String formatLabel(String key) => switch (key) {
    'sdkInt' => 'SDK Int',
    'androidVersion' => 'Android Version',
    'securityPatch' => 'Security Patch',
    'buildType' => 'Build Type',
    'buildTags' => 'Build Tags',
    'buildId' => 'Build ID',
    'supportedAbis' => 'Supported ABIs',
    'isDebuggable' => 'Debuggable',
    _ => key.replaceAllMapped(RegExp(r'(?=[A-Z])'), (m) => ' ').trim()
        .split(' ').map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1)).join(' '),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        if (loading) ...[
          const SizedBox(height: 100),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Loading system info...'),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withAlpha(25)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.info, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Build Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                loading ? RotationTransition(turns: anim, child: Icon(Icons.refresh, color: cs.primary, size: 20))
                       : IconButton(onPressed: load, icon: const Icon(Icons.refresh, size: 20)),
              ]),
              const SizedBox(height: 12),
              ...buildInfo.entries.map((e) => InkWell(
                onTap: () => copy('${e.key}=${e.value}', e.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    SizedBox(width: 120, child: Text(formatLabel(e.key), 
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                    Expanded(child: Text(e.value?.toString() ?? 'Unknown', 
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                    Icon(Icons.copy, size: 14, color: cs.onSurfaceVariant),
                  ]),
                ),
              )),
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
                Icon(Icons.settings, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text('System Properties', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: Text('${filteredProps.length}', style: TextStyle(color: cs.onPrimaryContainer, fontSize: 12)),
                ),
                const Spacer(),
                IconButton(onPressed: load, icon: const Icon(Icons.refresh, size: 20)),
              ]),
              const SizedBox(height: 12),
              SearchBar(
                hintText: 'Filter properties...',
                leading: const Icon(Icons.search, size: 18),
                onChanged: onSearch,
                constraints: const BoxConstraints(minHeight: 40),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 400,
                child: filteredProps.isEmpty ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 40, color: cs.outline),
                    const SizedBox(height: 12),
                    const Text('No matching properties'),
                  ],
                )) : ListView.builder(
                  itemCount: filteredProps.length,
                  itemBuilder: (_, i) {
                    final e = filteredProps.entries.elementAt(i);
                    return InkWell(
                      onTap: () => copy('${e.key}=${e.value}', 'Property'),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.key, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Row(children: [
                            Expanded(child: Text(e.value.toString(), 
                              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: cs.onSurfaceVariant))),
                            Icon(Icons.copy, size: 12, color: cs.onSurfaceVariant),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}
