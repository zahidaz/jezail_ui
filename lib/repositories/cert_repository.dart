import 'dart:typed_data';
import 'package:jezail_ui/services/cert_service.dart';

class CertRepository {
  final CertService _certService;

  const CertRepository(this._certService);

  Future<List<Map<String, dynamic>>> getSystemCerts() async {
    final result = await _certService.getSystemCerts();
    if (result is List) return List<Map<String, dynamic>>.from(result);
    return List<Map<String, dynamic>>.from(result['data'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getUserCerts() async {
    final result = await _certService.getUserCerts();
    if (result is List) return List<Map<String, dynamic>>.from(result);
    return List<Map<String, dynamic>>.from(result['data'] ?? []);
  }

  Future<void> installCert(Uint8List certBytes, String filename) async {
    await _certService.installCert(certBytes, filename);
  }

  Future<void> removeCert(String hash) async {
    await _certService.removeCert(hash);
  }
}
