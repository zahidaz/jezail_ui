import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:jezail_ui/core/enums/device_enums.dart';
import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

class LogsTab extends StatefulWidget {
  const LogsTab({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> with SingleTickerProviderStateMixin {
  List<String> allLogs = [];
  LogType type = LogType.main;
  String filter = '';
  bool loading = false;
  Timer? debounce;
  late AnimationController anim;

  List<String> get logs => filter.isEmpty ? allLogs : 
    allLogs.where((log) => log.toLowerCase().contains(filter.toLowerCase())).toList();

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
      allLogs = await widget.repository.getLogs(type);
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load logs');
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

  void copy(String log) {
    Clipboard.setData(ClipboardData(text: log));
    HapticFeedback.lightImpact();
    context.showSuccessSnackBar('Copied');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outline.withAlpha(25)))),
        child: Column(children: [
          Row(children: [
            Icon(Icons.article, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Text('${logs.length}', style: TextStyle(color: cs.onPrimaryContainer, fontSize: 12)),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => context.runWithFeedback(
                action: widget.repository.clearLogs,
                successMessage: 'Cleared', errorMessage: 'Clear failed'),
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
            loading ? RotationTransition(turns: anim, child: Icon(Icons.refresh, color: cs.primary, size: 20))
                   : IconButton(onPressed: load, icon: const Icon(Icons.refresh, size: 20)),
          ]),
          const SizedBox(height: 12),
          SearchBar(
            hintText: 'Filter logs...',
            leading: const Icon(Icons.search, size: 18),
            onChanged: onSearch,
            constraints: const BoxConstraints(minHeight: 40),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: LogType.values.map((t) => FilterChip(
              selected: t == type,
              onSelected: (_) => setState(() { type = t; filter = ''; load(); }),
              label: Text(t.displayName, style: const TextStyle(fontSize: 12)),
              avatar: Icon(t.icon, size: 14),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              showCheckmark: false,
            )).toList(),
          ),
        ]),
      ),
      Expanded(
        child: logs.isEmpty ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: loading ? [
            const CircularProgressIndicator(), const SizedBox(height: 12), const Text('Loading...')
          ] : [
            Icon(Icons.article_outlined, size: 40, color: cs.outline),
            const SizedBox(height: 12),
            Text(filter.isNotEmpty ? 'No matches' : 'No logs'),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh')),
          ],
        )) : ListView.builder(
          itemCount: logs.length,
          itemBuilder: (_, i) => InkWell(
            onTap: () => copy(logs[i]),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cs.outline.withAlpha(25)),
              ),
              child: Row(children: [
                Container(
                  width: 3, height: 16,
                  decoration: BoxDecoration(
                    color: _getLogColor(logs[i]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(logs[i], style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                Icon(Icons.copy, size: 14, color: cs.onSurfaceVariant),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  Color _getLogColor(String log) {
    final l = log.toLowerCase();
    if (l.contains(' e ') || l.contains('error')) return const Color(0xFFF44336);
    if (l.contains(' w ') || l.contains('warn')) return const Color(0xFFFF9800);
    if (l.contains(' i ') || l.contains('info')) return const Color(0xFF2196F3);
    if (l.contains(' d ') || l.contains('debug')) return const Color(0xFF4CAF50);
    return const Color(0xFF9E9E9E);
  }
}
