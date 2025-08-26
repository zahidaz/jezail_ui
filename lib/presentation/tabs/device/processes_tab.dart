import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:jezail_ui/models/device/process_info.dart';
import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/core/enums/process_enums.dart';
import 'package:jezail_ui/presentation/utils/dialog_utils.dart';

class ProcessesTab extends StatefulWidget {
  const ProcessesTab({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<ProcessesTab> createState() => _ProcessesTabState();
}

class _ProcessesTabState extends State<ProcessesTab> with SingleTickerProviderStateMixin {
  List<ProcessInfo> processes = [];
  String query = '';
  bool loading = false;
  ProcessSort sortBy = ProcessSort.name;
  bool sortAsc = true;
  Timer? debounce;
  late AnimationController anim;

  List<ProcessInfo> get filtered => (query.isEmpty ? processes : processes.where((p) => 
    '${p.name} ${p.user} ${p.pid} ${p.state}'.toLowerCase().contains(query.toLowerCase())).toList())
    ..sort((a, b) {
      final comp = switch (sortBy) {
        ProcessSort.name => a.name.compareTo(b.name),
        ProcessSort.pid => a.pid.compareTo(b.pid),
        ProcessSort.user => (a.user ?? '').compareTo(b.user ?? ''),
        ProcessSort.memory => (a.vsz ?? 0).compareTo(b.vsz ?? 0),
        ProcessSort.state => (a.state ?? '').compareTo(b.state ?? ''),
      };
      return sortAsc ? comp : -comp;
    });

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
      processes = await widget.repository.getProcesses();
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load processes');
    } finally {
      anim.stop();
      if (mounted) setState(() => loading = false);
    }
  }

  void onSearch(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => query = value);
    });
  }

  Future<void> kill(ProcessInfo process) async {
    final confirmed = await DialogUtils.showConfirmationDialog(context,
      title: 'Kill Process', message: 'Kill "${process.name}" (${process.pid})?',
      confirmText: 'Kill', confirmButtonColor: Colors.red);
    if (confirmed && mounted) {
      HapticFeedback.mediumImpact();
      await context.runWithFeedback(
        action: () => widget.repository.killProcess(process.pid),
        successMessage: 'Killed ${process.name}', errorMessage: 'Kill failed');
      load();
    }
  }

  Color _stateColor(String? state) => switch (state?.toLowerCase()) {
    'running' || 'r' => const Color(0xFF4CAF50),
    'sleeping' || 's' => const Color(0xFF2196F3),
    'stopped' || 't' => const Color(0xFFFF9800),
    'zombie' || 'z' => const Color(0xFFF44336),
    _ => const Color(0xFF9E9E9E),
  };

  String _formatMem(int? bytes) => switch (bytes) {
    null || 0 => '0',
    < 1024 => '${bytes}B',
    < 1048576 => '${(bytes / 1024).toStringAsFixed(0)}K',
    _ => '${(bytes / 1048576).toStringAsFixed(1)}M',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outline.withAlpha(25)))),
        child: Column(children: [
          Row(children: [
            Icon(Icons.memory, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            const Text('Processes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
              child: Text('${filtered.length}', style: TextStyle(color: cs.onPrimaryContainer, fontSize: 12)),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => showModalBottomSheet(context: context, showDragHandle: true,
                builder: (_) => Container(padding: const EdgeInsets.all(16), child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sort', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...ProcessSort.values.map((s) => ListTile(
                      leading: Icon(s.icon, size: 20),
                      title: Text(s.label),
                      trailing: sortBy == s ? Icon(sortAsc ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20) : null,
                      onTap: () {
                        setState(() { sortBy == s ? sortAsc = !sortAsc : (sortBy = s, sortAsc = true); });
                        Navigator.pop(context);
                      },
                    )),
                  ],
                ))),
              icon: const Icon(Icons.sort, size: 20),
            ),
            loading ? RotationTransition(turns: anim, child: Icon(Icons.refresh, color: cs.primary, size: 20))
                   : IconButton(onPressed: load, icon: const Icon(Icons.refresh, size: 20)),
          ]),
          const SizedBox(height: 12),
          SearchBar(
            hintText: 'Search...',
            leading: const Icon(Icons.search, size: 18),
            onChanged: onSearch,
            constraints: const BoxConstraints(minHeight: 40),
          ),
        ]),
      ),
      Expanded(
        child: filtered.isEmpty ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: loading ? [
            const CircularProgressIndicator(), const SizedBox(height: 12), const Text('Loading...')
          ] : [
            Icon(query.isNotEmpty ? Icons.search_off : Icons.memory, size: 40, color: cs.outline),
            const SizedBox(height: 12),
            Text(query.isNotEmpty ? 'No matches' : 'No processes'),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh')),
          ],
        )) : ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final p = filtered[i];
            return InkWell(
              onTap: () => showModalBottomSheet(context: context, showDragHandle: true,
                builder: (_) => Container(padding: const EdgeInsets.all(16), child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...{
                      'Name': p.name,
                      'PID': p.pid.toString(),
                      'User': p.user ?? 'Unknown',
                      'State': p.state ?? 'Unknown',
                      'Memory': '${p.vsz ?? 0} bytes',
                    }.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        SizedBox(width: 60, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                        Expanded(child: Text(e.value, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))),
                      ]),
                    )),
                  ],
                ))),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cs.outline.withAlpha(25)),
                ),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text(p.pid.toString(), 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.person, size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(p.user ?? 'Unknown', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: _stateColor(p.state).withAlpha(25), borderRadius: BorderRadius.circular(3)),
                        child: Text(p.state ?? '?', style: TextStyle(fontSize: 10, color: _stateColor(p.state), fontWeight: FontWeight.w500)),
                      ),
                      const Spacer(),
                      Text(_formatMem(p.vsz), style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    ]),
                  ])),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => kill(p),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: Colors.red.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.close, size: 16, color: Colors.red),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

