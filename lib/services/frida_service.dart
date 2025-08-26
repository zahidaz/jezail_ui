import 'api_service.dart';

class FridaService {
  final ApiService _api;
  FridaService(this._api);

  Future<dynamic> start() => _api.get('/frida/start');
  
  Future<dynamic> stop() => _api.get('/frida/stop');
  
  Future<dynamic> getStatus() => _api.get('/frida/status');
  
  Future<dynamic> getInfo() => _api.get('/frida/info');
  
  Future<dynamic> install() => _api.get('/frida/install');
  
  Future<dynamic> update() => _api.get('/frida/update');

}