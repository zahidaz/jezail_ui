import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/presentation/tabs/files/file_explorer.dart';

class FilesTab extends StatefulWidget {
  const FilesTab({super.key, required this.repository});
  final FileRepository repository;

  @override
  State<FilesTab> createState() => FilesTabState();
}

class FilesTabState extends State<FilesTab> {
  final GlobalKey<State<FileExplorer>> _explorerKey = GlobalKey<State<FileExplorer>>();

  void navigateToPath(String path) {
    final state = _explorerKey.currentState;
    if (state != null) {
      (state as dynamic).navigateToPath(path);
    }
  }

  void _onPathChanged(String path) {
    // Update URL with current path
    if (path == '/') {
      context.go('/files');
    } else {
      context.go('/files?path=$path');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FileExplorer(
      key: _explorerKey,
      repository: widget.repository,
      onPathChanged: _onPathChanged,
    );
  }
}
