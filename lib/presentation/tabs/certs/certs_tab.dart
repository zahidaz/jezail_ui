import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

import 'package:jezail_ui/repositories/cert_repository.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/utils/dialog_utils.dart';

class CertsTab extends StatefulWidget {
  const CertsTab({super.key, required this.repository});
  final CertRepository repository;

  @override
  State<CertsTab> createState() => _CertsTabState();
}

class _CertsTabState extends State<CertsTab> {
  List<Map<String, dynamic>> systemCerts = [];
  List<Map<String, dynamic>> userCerts = [];
  bool loading = false;
  String query = '';
  String activeTab = 'system';

  @override
  void initState() {
    super.initState();
    _loadCerts();
  }

  Future<void> _loadCerts() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final results = await Future.wait([
        widget.repository.getSystemCerts(),
        widget.repository.getUserCerts(),
      ]);
      if (mounted) {
        setState(() {
          systemCerts = results[0];
          userCerts = results[1];
        });
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to load certificates');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCerts {
    final certs = activeTab == 'system' ? systemCerts : userCerts;
    if (query.isEmpty) return certs;
    final q = query.toLowerCase();
    return certs.where((c) {
      final subject = (c['subject'] ?? '').toString().toLowerCase();
      final issuer = (c['issuer'] ?? '').toString().toLowerCase();
      final hash = (c['hash'] ?? '').toString().toLowerCase();
      return subject.contains(q) || issuer.contains(q) || hash.contains(q);
    }).toList();
  }

  Future<void> _installCert() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result?.files.single.bytes case final bytes? when mounted) {
      final filename = result!.files.single.name;
      await context.runWithFeedback(
        action: () async {
          await widget.repository.installCert(bytes, filename);
          await _loadCerts();
        },
        successMessage: 'Certificate installed',
        errorMessage: 'Failed to install certificate',
      );
    }
  }

  Future<void> _removeCert(Map<String, dynamic> cert) async {
    final hash = cert['hash']?.toString() ?? '';
    if (hash.isEmpty) return;
    final subject = cert['subject'] ?? hash;
    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      title: 'Remove Certificate',
      message: 'Remove "$subject"?',
      confirmText: 'Remove',
      confirmButtonColor: Colors.red,
    );
    if (confirmed && mounted) {
      await context.runWithFeedback(
        action: () async {
          await widget.repository.removeCert(hash);
          await _loadCerts();
        },
        successMessage: 'Certificate removed',
        errorMessage: 'Failed to remove certificate',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredCerts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withAlpha(25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: cs.onSurfaceVariant, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => query = v),
                          decoration: InputDecoration(
                            hintText: 'Search certificates...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            hintStyle: TextStyle(
                              color: cs.onSurfaceVariant.withAlpha(150),
                              fontSize: 13,
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _loadCerts,
                icon: Icon(Icons.refresh, color: cs.primary, size: 18),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outline.withAlpha(25)),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    selected: activeTab == 'system',
                    onSelected: (_) => setState(() => activeTab = 'system'),
                    label: Text(
                      activeTab == 'system'
                          ? 'System (${systemCerts.length})'
                          : 'System',
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: const Icon(Icons.shield, size: 14),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    showCheckmark: false,
                  ),
                  FilterChip(
                    selected: activeTab == 'user',
                    onSelected: (_) => setState(() => activeTab = 'user'),
                    label: Text(
                      activeTab == 'user'
                          ? 'User (${userCerts.length})'
                          : 'User',
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: const Icon(Icons.person, size: 14),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    showCheckmark: false,
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _installCert,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Install', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: loading && (activeTab == 'system' ? systemCerts.isEmpty : userCerts.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        query.isNotEmpty ? 'No matches' : 'No certificates',
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _CertItem(
                        cert: filtered[i],
                        onRemove: _removeCert,
                        onCopy: (text, label) {
                          Clipboard.setData(ClipboardData(text: text));
                          context.showSuccessSnackBar('$label copied');
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _CertItem extends StatelessWidget {
  const _CertItem({
    required this.cert,
    required this.onRemove,
    required this.onCopy,
  });

  final Map<String, dynamic> cert;
  final Function(Map<String, dynamic>) onRemove;
  final Function(String, String) onCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subject = cert['subject']?.toString() ?? 'Unknown';
    final hash = cert['hash']?.toString() ?? '';
    final notAfter = cert['notAfter']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withAlpha(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(Icons.verified_user, size: 16, color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _extractCN(subject),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _extractOrg(subject),
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          hash,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (notAfter.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Expires: $notAfter',
                          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => onCopy(subject, 'Subject'),
              icon: Icon(Icons.copy, size: 14, color: cs.primary),
              tooltip: 'Copy subject',
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: cs.primary.withAlpha(25),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => onRemove(cert),
              icon: const Icon(Icons.delete, size: 14, color: Colors.red),
              tooltip: 'Remove certificate',
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withAlpha(25),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractCN(String subject) {
    final match = RegExp(r'CN=([^,]+)').firstMatch(subject);
    return match?.group(1) ?? subject;
  }

  String _extractOrg(String subject) {
    final match = RegExp(r'O=([^,]+)').firstMatch(subject);
    return match?.group(1) ?? '';
  }
}
