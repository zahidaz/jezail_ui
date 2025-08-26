import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:jezail_ui/services/api_service.dart';
import 'package:jezail_ui/core/log.dart';

class FilesService {

  final ApiService _api;

  FilesService(this._api);

  Future<dynamic> getFileInfo(String path) =>
      _api.get('/files/info?path=${Uri.encodeComponent(path)}');

  Future<dynamic> listDirectory({String? path}) {
    String endpoint = '/files/list';
    if (path != null) {
      endpoint += '?path=${Uri.encodeComponent(path)}';
    }
    return _api.get(endpoint);
  }

  Future<dynamic> readFile(String path) =>
      _api.get('/files/read?path=${Uri.encodeComponent(path)}');

  Future<dynamic> writeFile(String path, String content) =>
      _api.post('/files/write?path=${Uri.encodeComponent(path)}', body: content);

  Future<dynamic> renameFile(String oldPath, String newPath) =>
      _api.post('/files/rename?oldPath=${Uri.encodeComponent(oldPath)}&newPath=${Uri.encodeComponent(newPath)}');

  Future<dynamic> createDirectory(String path) =>
      _api.post('/files/mkdir?path=${Uri.encodeComponent(path)}');

  Future<dynamic> changePermissions(String path, String permissions) =>
      _api.post('/files/chmod?path=${Uri.encodeComponent(path)}&permissions=$permissions');

  Future<dynamic> changeOwner(String path, String owner) =>
      _api.post('/files/chown?path=${Uri.encodeComponent(path)}&owner=$owner');


  Future<dynamic> changeGroup(String path, String group) =>
      _api.post('/files/chgrp?path=${Uri.encodeComponent(path)}&group=$group');

  Future<dynamic> deleteFile(String path) =>
      _api.delete('/file?path=${Uri.encodeComponent(path)}');

  Future<dynamic> doUpload(String destinationPath, Uint8List fileBytes, {String? filename}) async {
    final uri = Uri.parse('${_api.baseUrl}/files/upload?path=${Uri.encodeComponent(destinationPath)}');
    
    var request = http.MultipartRequest('POST', uri);
    
    if (_api.defaultHeaders.isNotEmpty) {
      request.headers.addAll(_api.defaultHeaders);
    }
    

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename ?? 'upload.bin',
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    return _api.handleResponse(response);
  }

  Future<Uint8List> downloadFile(String path) async {
    final response = await _api.getRaw('/files/download?paths=${Uri.encodeComponent(path)}');
    return response.bodyBytes;
  }

  Future<({Uint8List data, String? filename})> downloadFiles(List<String> paths) async {
    final pathsQuery = paths.map((path) => 'paths=${Uri.encodeComponent(path)}').join('&');
    final response = await _api.getRaw('/files/download?$pathsQuery');
    
    Log.debug('Download response received');
    Log.debug('Response headers: ${response.headers}');
    Log.debug('Content-Type: ${response.headers['content-type']}');
    Log.debug('Content-Disposition: ${response.headers['content-disposition']}');
    Log.debug('Response body size: ${response.bodyBytes.length} bytes');
    
    if (response.bodyBytes.length >= 4) {
      final signature = response.bodyBytes.take(4).toList();
      Log.debug('File signature (first 4 bytes): $signature');
      if (signature[0] == 80 && signature[1] == 75) {
        Log.debug('Data appears to be a ZIP file (PK signature detected)');
      } else {
        Log.warning('Data does not appear to be a ZIP file (no PK signature)');
      }
    }
    
    final filename = _extractFilenameFromHeaders(response.headers);
    return (data: response.bodyBytes, filename: filename);
  }

  String? _extractFilenameFromHeaders(Map<String, String> headers) {
    final contentDisposition = headers['content-disposition'];
    Log.debug('Extracting filename from Content-Disposition: $contentDisposition');
    
    if (contentDisposition != null) {
      if (contentDisposition.contains('filename=')) {
        final parts = contentDisposition.split('filename=');
        if (parts.length > 1) {
          String filename = parts[1].split(';').first.trim();
          Log.debug('Raw filename from header: "$filename"');
          
          if (filename.startsWith('"') && filename.endsWith('"')) {
            filename = filename.substring(1, filename.length - 1);
            Log.debug('Removed double quotes, filename: "$filename"');
          }
          if (filename.startsWith("'") && filename.endsWith("'")) {
            filename = filename.substring(1, filename.length - 1);
            Log.debug('Removed single quotes, filename: "$filename"');
          }
          
          Log.info('Extracted filename from server: "$filename"');
          return filename;
        }
      }
    }
    
    Log.warning('No filename found in server headers');
    return null;
  }
}
