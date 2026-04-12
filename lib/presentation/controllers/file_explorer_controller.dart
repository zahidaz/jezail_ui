import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:path/path.dart' as path;
import 'package:jezail_ui/repositories/files_repository.dart';
import 'package:jezail_ui/models/files/file_explorer_view_state.dart';
import 'package:jezail_ui/models/files/file_operation_result.dart';
import 'package:jezail_ui/core/enums/file_enums.dart';

final class FileExplorerController extends ValueNotifier<FileExplorerViewState> {
  FileExplorerController(this._repository) : super(const FileExplorerViewState()) {
    _initialize();
  }

  final FileRepository _repository;

  Future<void> _initialize() async {
    await loadDirectory(value.currentPath);
  }

  Future<void> loadDirectory(String path) async {
    value = value.copyWith(
      filesResult: const Loading<List<FileInfo>>(),
      currentPath: path,
    ).clearSelection();

    try {
      final files = await _repository.listDirectory(path: path);
      final sortedFiles = FileExplorerViewState.sortFiles(files, value.sortField, value.sortAscending);
      
      value = value.copyWith(
        filesResult: Success(sortedFiles),
      );
    } on Exception catch (e) {
      value = value.copyWith(
        filesResult: Error('Failed to load directory: ${e.toString()}', e),
      );
    }
  }

  Future<void> refreshCurrentDirectory() async {
    await loadDirectory(value.currentPath);
  }

  Future<void> navigateToPath(String targetPath) async {
    if (targetPath != value.currentPath) {
      try {
        final fileInfo = await _repository.getFileInfo(targetPath);
        
        if (!fileInfo.isDirectory) {
          final parentPath = path.dirname(targetPath);
          final fileName = path.basename(targetPath);
          
          await loadDirectory(parentPath == '.' ? '/' : parentPath);
          
          await Future.delayed(const Duration(milliseconds: 100));
          _selectFileByName(fileName);
        } else {
          await loadDirectory(targetPath);
        }
      } catch (e) {
        await loadDirectory(targetPath);
      }
    }
  }

  Future<void> navigateUp() async {
    if (value.canNavigateUp) {
      await navigateToPath(value.getParentPath());
    }
  }

  Future<void> navigateToChild(String childName) async {
    await navigateToPath(value.getChildPath(childName));
  }

  void toggleFileSelection(FileInfo file) {
    value = value.toggleSelection(file);
  }

  void _selectFileByName(String fileName) {
    final targetFile = value.files.where((file) => file.displayName == fileName).firstOrNull;
    if (targetFile != null) {
      value = value.clearSelection().toggleSelection(targetFile);
    }
  }

  void clearSelection() {
    value = value.clearSelection();
  }

  void selectSingleFile(FileInfo file) {
    value = value.clearSelection().toggleSelection(file);
  }

  void selectAll() {
    value = value.selectAll();
  }

  void setSortField(FileSortField field) {
    value = value.setSortField(field);
  }

  Future<FileOperationResult<void>> createDirectory(String name) async {
    try {
      final dirPath = value.getChildPath(name);
      await _repository.createDirectory(dirPath);
      await refreshCurrentDirectory();
      return const Success(null);
    } on Exception catch (e) {
      return Error('Failed to create directory: ${e.toString()}', e);
    }
  }

  Future<FileOperationResult<void>> deleteSelectedFiles() async {
    try {
      for (final file in value.selectedFiles) {
        final filePath = value.getChildPath(file.displayName);
        await _repository.deleteFile(filePath);
      }
      await refreshCurrentDirectory();
      return const Success(null);
    } on Exception catch (e) {
      return Error('Failed to delete files: ${e.toString()}', e);
    }
  }

  Future<FileOperationResult<void>> renameFile(FileInfo file, String newName) async {
    try {
      final oldPath = value.getChildPath(file.displayName);
      final newPath = value.getChildPath(newName);
      await _repository.renameFile(oldPath, newPath);
      await refreshCurrentDirectory();
      return const Success(null);
    } on Exception catch (e) {
      return Error('Failed to rename file: ${e.toString()}', e);
    }
  }

  FileOperationResult<String> downloadFiles(List<FileInfo> filesToDownload) {
    try {
      final paths = filesToDownload.map((file) => value.getChildPath(file.displayName)).toList();
      final url = _repository.getDownloadUrl(paths);

      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = '';
      anchor.click();

      final name = filesToDownload.length == 1
          ? filesToDownload.first.displayName
          : '${filesToDownload.length} files';
      return Success(name);
    } on Exception catch (e) {
      return Error('Failed to download files: ${e.toString()}', e);
    }
  }

}