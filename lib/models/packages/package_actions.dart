import 'package:jezail_ui/models/packages/package_info.dart';
import '../../core/enums/package_enums.dart';

typedef PackageState = ({
  List<PackageInfo> packages,
  bool isLoading,
  String? error,
  String searchQuery,
  AppTypeFilter filter,
});
