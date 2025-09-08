import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:jezail_ui/models/device/process_info.dart';
import 'package:jezail_ui/repositories/processes_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/core/enums/process_enums.dart';
import 'package:jezail_ui/presentation/utils/dialog_utils.dart';
import 'package:jezail_ui/presentation/tabs/device/widgets/search.dart';

class ProcessesTab extends StatefulWidget {
  const ProcessesTab({super.key, required this.repository});
  final ProcessesRepository repository;

  @override
  State<ProcessesTab> createState() => _ProcessesTabState();
}

class _ProcessesTabState extends State<ProcessesTab> with SingleTickerProviderStateMixin {
  List<ProcessInfo> processes = [];
  String query = '';
  bool loading = false;
  ProcessSort sortBy = ProcessSort.name;
  ProcessFilter filterBy = ProcessFilter.all;
  bool sortAsc = true;
  Timer? debounce;
  late AnimationController anim;
  Set<int> expandedProcesses = {};

  List<ProcessInfo> get filtered {
    var filteredList = processes.where((p) {
      switch (filterBy) {
        case ProcessFilter.all:
          break;
        case ProcessFilter.system:
          if (p.user != 'root' && p.user != 'system') return false;
          break;
        case ProcessFilter.user:
          if (p.user == 'root' || p.user == 'system') return false;
          break;
      }
      
      if (query.isNotEmpty) {
        if (!'${p.name} ${p.user} ${p.pid} ${p.state}'.toLowerCase().contains(query.toLowerCase())) {
          return false;
        }
      }
      
      return true;
    }).toList();

    filteredList.sort((a, b) {
      final comp = switch (sortBy) {
        ProcessSort.name => a.name.compareTo(b.name),
        ProcessSort.pid => a.pid.compareTo(b.pid),
        ProcessSort.user => (a.user ?? '').compareTo(b.user ?? ''),
        ProcessSort.memory => (a.vsz ?? 0).compareTo(b.vsz ?? 0),
        ProcessSort.state => (a.state ?? '').compareTo(b.state ?? ''),
      };
      return sortAsc ? comp : -comp;
    });

    return filteredList;
  }

  int _getFilterCount(ProcessFilter filter) {
    return processes.where((p) {
      switch (filter) {
        case ProcessFilter.all:
          return true;
        case ProcessFilter.system:
          return p.user == 'root' || p.user == 'system';
        case ProcessFilter.user:
          return p.user != 'root' && p.user != 'system';
      }
    }).length;
  }

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

  List<Widget> _buildProcessDetails(ProcessInfo p, ColorScheme cs) {
    final details = {
      'Process ID': p.pid.toString(),
      'Process Name': p.name,
      'User': p.user ?? 'Unknown',
      'State': p.state ?? 'Unknown',
      'Memory (VSZ)': '${p.vsz ?? 0} bytes',
      'Memory (Formatted)': _formatMem(p.vsz),
    };

    return details.entries.map((entry) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              entry.key,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              entry.value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      CompactSearchField(
        hintText: 'Search processes...',
        onChanged: onSearch,
        onRefresh: load,
        isLoading: loading,
        animationController: anim,
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          Wrap(
            spacing: 8,
            children: ProcessFilter.values.map((f) {
              final count = _getFilterCount(f);
              final isSelected = f == filterBy;
              return FilterChip(
                selected: isSelected,
                onSelected: (_) => setState(() {
                  filterBy = f;
                  query = '';
                }),
                label: Text(
                  isSelected ? '${f.displayName} ($count)' : f.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
                avatar: Icon(f.icon, size: 14),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                showCheckmark: false,
              );
            }).toList(),
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
            final isExpanded = expandedProcesses.contains(p.pid);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                        expandedProcesses.remove(p.pid);
                      } else {
                        expandedProcesses.add(p.pid);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
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
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
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
                  ),
                  if (isExpanded) ...[
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
                          Text(
                            'Process Details',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._buildProcessDetails(p, cs),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ]);
  }
}