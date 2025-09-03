import 'package:jezail_ui/models/files/file_info.dart';
import 'package:flutter/foundation.dart';
import 'package:jezail_ui/core/enums/file_enums.dart';
import 'package:jezail_ui/models/files/file_operation_result.dart';

final class FileExplorerViewState {
  const FileExplorerViewState({
    this.filesResult = const Loading<List<FileInfo>>(),
    this.currentPath = '/data/local/tmp',
    this.selectedFiles = const <FileInfo>{},
    this.sortField = FileSortField.name,
    this.sortAscending = true,
  });

  final FileOperationResult<List<FileInfo>> filesResult;
  final String currentPath;
  final Set<FileInfo> selectedFiles;
  final FileSortField sortField;
  final bool sortAscending;

  List<FileInfo> get files => filesResult.dataOrNull ?? <FileInfo>[];
  bool get isLoading => filesResult.isLoading;
  String? get error => filesResult.errorOrNull;
  bool get hasError => filesResult.isError;
  bool get canNavigateUp => 
      currentPath != '/' && 
      currentPath != '/data/local/tmp';

  FileExplorerViewState copyWith({
    FileOperationResult<List<FileInfo>>? filesResult,
    String? currentPath,
    Set<FileInfo>? selectedFiles,
    FileSortField? sortField,
    bool? sortAscending,
  }) {
    return FileExplorerViewState(
      filesResult: filesResult ?? this.filesResult,
      currentPath: currentPath ?? this.currentPath,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  FileExplorerViewState toggleSelection(FileInfo file) {
    if (selectedFiles.contains(file)) {
      if (selectedFiles.length == 1) {
        return copyWith(selectedFiles: <FileInfo>{});
      } else {
        final newSelection = Set<FileInfo>.from(selectedFiles)..remove(file);
        return copyWith(selectedFiles: newSelection);
      }
    } else {
      if (selectedFiles.isEmpty) {
        return copyWith(selectedFiles: {file});
      } else {
        final newSelection = Set<FileInfo>.from(selectedFiles)..add(file);
        return copyWith(selectedFiles: newSelection);
      }
    }
  }

  FileExplorerViewState clearSelection() {
    return copyWith(selectedFiles: <FileInfo>{});
  }

  FileExplorerViewState selectAll() {
    return copyWith(selectedFiles: files.toSet());
  }


  FileExplorerViewState setSortField(FileSortField field) {
    final ascending = sortField == field ? !sortAscending : true;
    return copyWith(
      sortField: field,
      sortAscending: ascending,
      filesResult: Success(_sortFiles(files, field, ascending)),
    );
  }

  String getParentPath() {
    if (!canNavigateUp) return currentPath;
    
    final parts = currentPath.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '/';
    
    parts.removeLast();
    return parts.isEmpty ? '/' : '/${parts.join('/')}';
  }

  String getChildPath(String childName) {
    return currentPath == '/' 
        ? '/$childName' 
        : '$currentPath/$childName';
  }

  static List<FileInfo> _sortFiles(List<FileInfo> files, FileSortField field, bool ascending) {
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileExplorerViewState &&
          runtimeType == other.runtimeType &&
          filesResult == other.filesResult &&
          currentPath == other.currentPath &&
          setEquals(selectedFiles, other.selectedFiles) &&
          sortField == other.sortField &&
          sortAscending == other.sortAscending;

  @override
  int get hashCode => Object.hash(
        filesResult,
        currentPath,
        selectedFiles,
        sortField,
        sortAscending,
      );
}