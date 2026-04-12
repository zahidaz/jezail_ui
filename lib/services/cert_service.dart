import 'dart:typed_data';
import 'package:jezail_ui/services/api_service.dart';

class CertService {
  final ApiService _api;
  CertService(this._api);

  Future<dynamic> getSystemCerts() => _api.get('/certs/system');
  Future<dynamic> getUserCerts() => _api.get('/certs/user');
  Future<dynamic> removeCert(String hash) => _api.delete('/certs/$hash');

  Future<dynamic> installCert(Uint8List certBytes, String filename) =>
      _api.postMultipart('/certs/install', 'file', certBytes, filename);
}
