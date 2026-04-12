import 'package:jezail_ui/services/api_service.dart';
import 'package:jezail_ui/services/device_service.dart';
import 'package:jezail_ui/services/file_service.dart';
import 'package:jezail_ui/services/package_service.dart';
import 'package:jezail_ui/services/adb_service.dart';
import 'package:jezail_ui/services/frida_service.dart';
import 'package:jezail_ui/services/cert_service.dart';

class ServiceRegistry {
  ServiceRegistry(this.api)
      : device = DeviceService(api),
        files = FilesService(api),
        packages = PackageService(api),
        adb = AdbService(api),
        frida = FridaService(api),
        certs = CertService(api);

  final ApiService api;
  final DeviceService device;
  final FilesService files;
  final PackageService packages;
  final AdbService adb;
  final FridaService frida;
  final CertService certs;
}
