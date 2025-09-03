import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:jezail_ui/services/api_service.dart';

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
      _api.delete('/files?path=${Uri.encodeComponent(path)}');

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

  Future<({Uint8List data, String filename})> download(List<String> paths) async {
    final pathsQuery = paths.map((path) => 'paths=${Uri.encodeComponent(path)}').join('&');
    final response = await _api.getRaw('/files/download?$pathsQuery');
    
    String filename = 'downloaded_${DateTime.now().millisecondsSinceEpoch}';
    
    final contentDisposition = response.headers['content-disposition'];
    if (contentDisposition != null && contentDisposition.contains('filename=')) {
      final parts = contentDisposition.split('filename=')[1].split(';')[0].trim();
      if (parts.startsWith("'") || parts.startsWith('"')) {
        filename = parts.substring(1, parts.endsWith(parts[0]) ? parts.length - 1 : parts.length);
      } else {
        filename = parts;
      }
      if (filename.isEmpty) filename = 'downloaded_${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return (data: response.bodyBytes, filename: filename);
  }
}
