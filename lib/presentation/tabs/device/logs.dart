import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:jezail_ui/core/enums/device_enums.dart';
import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/tabs/device/widgets/search.dart';

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
  int logLimit = 1000;
  final logLimitController = TextEditingController(text: '1000');

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
    logLimitController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (loading) return;
    setState(() => loading = true);
    anim.repeat();
    try {
      allLogs = await widget.repository.getLogs(type, lines: logLimit);
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
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: CompactSearchField(
                hintText: 'Filter logs...',
                onChanged: onSearch,
                onRefresh: null,
                isLoading: false,
                animationController: null,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextField(
                controller: logLimitController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Lines',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  labelStyle: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                style: const TextStyle(fontSize: 12),
                onSubmitted: (value) {
                  final newLimit = int.tryParse(value) ?? 1000;
                  if (newLimit > 0 && newLimit <= 10000) {
                    logLimit = newLimit;
                    load();
                  } else {
                    logLimitController.text = logLimit.toString();
                    context.showErrorSnackBar('Lines must be 1-10000');
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline.withAlpha(25)),
              ),
              child: GestureDetector(
                onTap: load,
                child: loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: RotationTransition(
                          turns: anim,
                          child: Icon(
                            Icons.refresh,
                            color: cs.primary,
                            size: 18,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: cs.primary,
                        size: 18,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => context.runWithFeedback(
                action: widget.repository.clearLogs,
                successMessage: 'Cleared', errorMessage: 'Clear failed'),
              icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
              tooltip: 'Clear logs',
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          Wrap(
            spacing: 8,
            children: LogType.values.map((t) {
              final isSelected = t == type;
              return FilterChip(
                selected: isSelected,
                onSelected: (_) => setState(() { 
                  type = t; 
                  filter = ''; 
                  load(); 
                }),
                label: Text(
                  isSelected ? '${t.displayName} (${allLogs.length})' : t.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
                avatar: Icon(t.icon, size: 14),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                showCheckmark: false,
              );
            }).toList(),
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
