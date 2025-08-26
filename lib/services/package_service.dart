import 'dart:typed_data';
import 'package:jezail_ui/services/api_service.dart';

class PackageService {
  final ApiService _api;
  PackageService(this._api);

  Future<dynamic> getAllPackages() => _api.get('/package/list');
  
  Future<dynamic> getUserPackages() => _api.get('/package/list/user');
  
  Future<dynamic> getSystemPackages() => _api.get('/package/list/system');

  Future<dynamic> getPackage(String package) => _api.get('/package/$package');
  
  Future<dynamic> getPackageDetails(String package) => _api.get('/package/$package/details');
  
  Future<dynamic> uninstallPackage(String package) => _api.delete('/package/$package');

  Future<dynamic> launchPackage(String package, {String? activity}) {
    String endpoint = '/package/$package/launch';
    if (activity != null) {
      endpoint += '?activity=$activity';
    }
    return _api.get(endpoint);
  }
          
  Future<dynamic> stopPackage(String package) => _api.get('/package/$package/stop');

  Future<dynamic> installApk(Uint8List apkBytes, {bool? forceInstall, bool? grantPermissions}) {
    String endpoint = '/package/install';
    Map<String, String>? queryParams;
    
    if (forceInstall != null || grantPermissions != null) {
      queryParams = {};
      if (forceInstall != null) queryParams['forceInstall'] = forceInstall.toString();
      if (grantPermissions != null) queryParams['grantPermissions'] = grantPermissions.toString();
    }
    
    return _api.postMultipart(
      endpoint, 
      'file', 
      apkBytes, 
      'app.apk',
      queryParams: queryParams,
    );
  }

  Future<dynamic> grantPermission(String package, String permission) =>
      _api.post('/package/$package/permissions/grant?permission=$permission');
           
  Future<dynamic> revokePermission(String package, String permission) =>
      _api.post('/package/$package/permissions/revoke?permission=$permission');

  Future<dynamic> getPackagePermissions(String package) => _api.get('/package/$package/permissions');
  
  Future<dynamic> getAllPackagePermissions(String package) => _api.get('/package/$package/permissions/all');

  Future<dynamic> isPackageRunning(String package) => _api.get('/package/$package/running');
  
  Future<dynamic> getPackageProcessInfo(String package) => _api.get('/package/$package/process-info');

  Future<dynamic> clearPackageData(String package) => _api.post('/package/$package/clear-data');
  
  Future<dynamic> clearPackageCache(String package) => _api.post('/package/$package/clear-cache');

  Future<dynamic> getPackageSignatures(String package) => _api.get('/package/$package/signatures');
  
  Future<dynamic> isPackageDebuggable(String package) => _api.get('/package/$package/debuggable');

}