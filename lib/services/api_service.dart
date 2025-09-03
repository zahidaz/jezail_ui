import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:jezail_ui/core/log.dart';
import 'package:jezail_ui/core/exceptions/api_exception.dart';

class ApiService {
  final String baseUrl;
  final Map<String, String> _defaultHeaders;

  ApiService(this.baseUrl, {Map<String, String>? defaultHeaders})
    : _defaultHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?defaultHeaders,
      };

  Map<String, String> get defaultHeaders => _defaultHeaders;

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    Log.debug('GET $baseUrl$endpoint');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {..._defaultHeaders, ...?headers},
      );
      return _handleResponse(response, 'GET', endpoint);
    } catch (e) {
      Log.error('GET $endpoint failed', e);
      rethrow;
    }
  }

  Future<http.Response> getRaw(String endpoint, {Map<String, String>? headers}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers ?? {},
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    
    throw ApiException(
      'GET $endpoint failed (${response.statusCode} ${response.reasonPhrase ?? ''})',
      response.statusCode,
    );
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    late http.Response response;
    
    if (body is String) {
      response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          ..._defaultHeaders,
          ...?headers,
          'Content-Type': 'text/plain; charset=utf-8',
        },
        body: body,
      );
    } else {
      response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );
    }
    
    return _handleResponse(response, 'POST', endpoint);
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async => _handleResponse(
    await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: {..._defaultHeaders, ...?headers},
      body: body != null ? jsonEncode(body) : null,
    ),
    'PUT',
    endpoint,
  );

  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async => _handleResponse(
    await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {..._defaultHeaders, ...?headers},
      body: body != null ? jsonEncode(body) : null,
    ),
    'PATCH',
    endpoint,
  );

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async => _handleResponse(
    await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {..._defaultHeaders, ...?headers},
    ),
    'DELETE',
    endpoint,
  );

  Future<dynamic> postMultipart(
    String endpoint,
    String fieldName,
    Uint8List fileBytes,
    String filename, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final uriWithParams = queryParams != null 
        ? uri.replace(queryParameters: queryParams)
        : uri;
    
    final request = http.MultipartRequest('POST', uriWithParams);
    
    if (headers != null) {
      final filteredHeaders = <String, String>{};
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() != 'content-type') {
          filteredHeaders[entry.key] = entry.value;
        }
      }
      request.headers.addAll(filteredHeaders);
    }
    
    request.files.add(http.MultipartFile.fromBytes(
      fieldName,
      fileBytes,
      filename: filename,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    return _handleResponse(response, 'POST', endpoint);
  }

  Future<Uint8List> getBinary(String endpoint, {Map<String, String>? headers}) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {..._defaultHeaders, ...?headers},
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    
    throw ApiException(
      'GET $endpoint failed (${response.statusCode} ${response.reasonPhrase ?? ''})',
      response.statusCode,
    );
  }

  dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'data': response.body};
      }
    } else {
      throw ApiException(
        'HTTP ${response.statusCode}: ${response.reasonPhrase ?? ''}',
        response.statusCode,
      );
    }
  }

  dynamic _handleResponse(http.Response res, String method, String endpoint) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      Log.debug('$method $endpoint succeeded (${res.statusCode})');
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return res.body;
      }
    }

    final errorMsg = '$method $endpoint failed (${res.statusCode} ${res.reasonPhrase ?? ''})';
    Log.warning(errorMsg);
    throw ApiException(errorMsg, res.statusCode);
  }
}

