import 'dart:typed_data';
import 'package:jezail_ui/models/files/file_info.dart';

import '../services/file_service.dart';
import '../services/api_service.dart';
import '../core/exceptions/file_exception.dart';

class FileRepository {
    final FileService _fileService;
  FileRepository(this._fileService);

  Future<FileInfo> getFileInfo(String path) async {
    try {
      final result = await _fileService.getFileInfo(path);
      final data = result['data'] ?? result;
      return FileInfo.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw FileOperationException('Access denied: Root permissions required for $path');
      }
      throw FileOperationException('Failed to get file info for $path: ${e.errorMessage}');
    } catch (e) {
      throw FileOperationException('Failed to get file info for $path: $e');
    }
  }

  Future<List<FileInfo>> listDirectory({String? path}) async {
    try {
      final result = await _fileService.listDirectory(path: path);
      final data = List<Map<String, dynamic>>.from(result['data'] ?? []);
      return data.map(FileInfo.fromJson).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw FileOperationException('Access denied: Root permissions required for ${path ?? "/"}');
      }
      throw FileOperationException('Failed to list directory ${path ?? "/"}: ${e.errorMessage}');
    } catch (e) {
      throw FileOperationException('Failed to list directory ${path ?? "/"}: $e');
    }
  }

  Future<String> readFile(String path) async {
    try {
      final result = await _fileService.readFile(path);
      final data = result['data'] ?? result;
      return data['content']?.toString() ?? '';
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        throw FileOperationException('Access denied: Root permissions required to read $path');
      }
      throw FileOperationException('Failed to read file $path: ${e.errorMessage}');
    } catch (e) {
      throw FileOperationException('Failed to read file $path: $e');
    }
  }

  Future<void> writeFile(String path, String content) async {
    try {
      await _fileService.writeFile(path, content);
    } catch (e) {
      throw FileOperationException('Failed to write file $path: $e');
    }
  }

  Future<void> renameFile(String oldPath, String newPath) async {
    try {
      await _fileService.renameFile(oldPath, newPath);
    } catch (e) {
      throw FileOperationException('Failed to rename $oldPath to $newPath: $e');
    }
  }

  Future<void> createDirectory(String path) async {
    try {
      await _fileService.createDirectory(path);
    } catch (e) {
      throw FileOperationException('Failed to create directory $path: $e');
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      await _fileService.deleteFile(path);
    } catch (e) {
      throw FileOperationException('Failed to delete $path: $e');
    }
  }

  Future<void> changePermissions(String path, String permissions) async {
    try {
      await _fileService.changePermissions(path, permissions);
    } catch (e) {
      throw FileOperationException('Failed to change permissions for $path: $e');
    }
  }

  Future<void> changeOwner(String path, String owner) async {
    try {
      await _fileService.changeOwner(path, owner);
    } catch (e) {
      throw FileOperationException('Failed to change owner for $path: $e');
    }
  }

  Future<void> changeGroup(String path, String group) async {
    try {
      await _fileService.changeGroup(path, group);
    } catch (e) {
      throw FileOperationException('Failed to change group for $path: $e');
    }
  }

  Future<void> uploadFile(String remotePath, Uint8List fileBytes, {String? filename}) async {
    try {
      await _fileService.doUpload(remotePath, fileBytes, filename: filename);
    } catch (e) {
      throw FileOperationException('Failed to upload file to $remotePath: $e');
    }
  }

  Future<Uint8List> downloadFile(String path) async {
    try {
      return await _fileService.downloadFile(path);
    } catch (e) {
      throw FileOperationException('Failed to download file $path: $e');
    }
  }

  Future<({Uint8List data, String? filename})> downloadFiles(List<String> paths) async {
    try {
      return await _fileService.downloadFiles(paths);
    } catch (e) {
      throw FileOperationException('Failed to download files: $e');
    }
  }

  Future<bool> fileExists(String path) async {
    try {
      await getFileInfo(path);
      return true;
    } on FileOperationException {
      return false;
    }
  }

  Future<void> copyFile(String sourcePath, String destinationPath) async {
    final content = await readFile(sourcePath);
    await writeFile(destinationPath, content);
  }

  Future<void> moveFile(String sourcePath, String destinationPath) async {
    await renameFile(sourcePath, destinationPath);
  }
}
