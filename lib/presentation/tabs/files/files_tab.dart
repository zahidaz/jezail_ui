import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/presentation/controllers/file_explorer_controller.dart';
import 'package:jezail_ui/presentation/tabs/files/file_explorer.dart';

class FilesTab extends StatefulWidget {
  const FilesTab({super.key, required this.repository});
  final FileRepository repository;

  @override
  State<FilesTab> createState() => FilesTabState();
}

class FilesTabState extends State<FilesTab> {
  late final FileExplorerController _controller = FileExplorerController(widget.repository);

  void navigateToPath(String path) {
    _controller.navigateToPath(path);
  }

  void _onPathChanged(String path) {
    if (path == '/') {
      context.go('/files');
    } else {
      context.go('/files?path=${Uri.encodeComponent(path)}');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FileExplorer(
      controller: _controller,
      repository: widget.repository,
      onPathChanged: _onPathChanged,
    );
  }
}
