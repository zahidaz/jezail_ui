import 'dart:async';
import 'dart:js_interop';
import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:jezail_ui/repositories/files_repository.dart';
import '../../../../models/files/file_explorer_view_state.dart';
import '../../../../models/files/file_operation_result.dart';
import '../../../../core/enums/file_enums.dart';
import '../../../../utils/log.dart';

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
      final sortedFiles = _sortFiles(files, value.sortField, value.sortAscending);
      
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

  Future<void> navigateToPath(String path) async {
    if (path != value.currentPath) {
      await loadDirectory(path);
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

  void clearSelection() {
    value = value.clearSelection();
  }

  void selectAll() {
    value = value.selectAll();
  }

  void toggleViewMode() {
    value = value.toggleViewMode();
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

  Future<FileOperationResult<void>> deleteFile(FileInfo file) async {
    try {
      final filePath = value.getChildPath(file.displayName);
      await _repository.deleteFile(filePath);
      await refreshCurrentDirectory();
      return const Success(null);
    } on Exception catch (e) {
      return Error('Failed to delete file: ${e.toString()}', e);
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

  Future<FileOperationResult<Uint8List>> downloadFile(FileInfo file) async {
    try {
      final filePath = value.getChildPath(file.displayName);
      final data = await _repository.downloadFile(filePath);
      return Success(data);
    } on Exception catch (e) {
      return Error('Failed to download file: ${e.toString()}', e);
    }
  }

  Future<FileOperationResult<void>> downloadSelectedFiles() async {
    try {
      final files = value.selectedFiles.toList();
      if (files.isEmpty) {
        return Error('No files selected for download', null);
      }
      
      if (files.length == 1) {
        final file = files.first;
        final filePath = value.getChildPath(file.displayName);
        final data = await _repository.downloadFile(filePath);
        _triggerWebDownload(data, file.displayName);
      } else {
        final filePaths = files
            .map((file) => value.getChildPath(file.displayName))
            .toList();
        final result = await _repository.downloadFiles(filePaths);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = result.filename ?? 'download_$timestamp.zip';
        
        Log.info('Downloading ${files.length} files');
        Log.debug('Server provided filename: ${result.filename}');
        Log.debug('Final filename used: $filename');
        Log.debug('Data size: ${result.data.length} bytes');
        
        _triggerWebDownload(result.data, filename);
      }
      
      return const Success(null);
    } on Exception catch (e) {
      return Error('Failed to download files: ${e.toString()}', e);
    }
  }
  
  void _triggerWebDownload(Uint8List data, String filename) {
    if (kIsWeb) {
      final mimeType = filename.endsWith('.zip') 
          ? 'application/zip'
          : 'application/octet-stream';
      
      Log.debug('Creating web download: filename=$filename, mimeType=$mimeType, size=${data.length}');
      
      final blob = web.Blob([data.toJS].toJS, web.BlobPropertyBag(type: mimeType));
      final url = web.URL.createObjectURL(blob);
      
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = filename;
      anchor.click();
      
      web.URL.revokeObjectURL(url);
      
      Log.info('Download triggered for: $filename');
    }
  }

  List<FileInfo> _sortFiles(List<FileInfo> files, FileSortField field, bool ascending) {
    final sorted = List<FileInfo>.from(files);
    
    sorted.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      
      final comparison = switch (field) {
        FileSortField.name => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
        FileSortField.size => a.size.compareTo(b.size),
        FileSortField.modified => a.lastModified.compareTo(b.lastModified),
        FileSortField.type => a.type.name.compareTo(b.type.name),
        FileSortField.permissions => a.permissions.compareTo(b.permissions),
      };
      
      return ascending ? comparison : -comparison;
    });
    
    return sorted;
  }
}