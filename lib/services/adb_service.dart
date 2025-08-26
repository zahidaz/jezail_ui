import 'api_service.dart';

class AdbService {
  final ApiService _api;
  AdbService(this._api);

  Future<dynamic> start() => _api.get('/adb/start');
  
  Future<dynamic> stop() => _api.get('/adb/stop');
  
  Future<dynamic> getStatus() => _api.get('/adb/status');
  
  Future<dynamic> installKey(String publicKey) => 
      _api.post('/adb/key?publicKey=$publicKey');
}