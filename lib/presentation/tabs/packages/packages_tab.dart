import 'package:jezail_ui/models/packages/package_actions.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import 'package:jezail_ui/models/packages/package_info.dart';
import 'package:jezail_ui/repositories/package_repository.dart';
import 'package:jezail_ui/core/enums/package_enums.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/utils/dialog_utils.dart';
import 'package:jezail_ui/presentation/tabs/packages/package_list_page.dart';
import 'package:jezail_ui/presentation/tabs/packages/package_details_page.dart';

typedef PackageTabState = ({
  List<PackageInfo> packages,
  bool isLoading,
  String? error,
  String searchQuery,
  AppTypeFilter filter,
  PackageInfo? selectedPackage,
});

class PackagesTab extends StatefulWidget {
  const PackagesTab({super.key, required this.packageRepository});

  final PackageRepository packageRepository;

  @override
  State<PackagesTab> createState() => PackagesTabState();
}

class PackagesTabState extends State<PackagesTab> {
  late final PageController _pageController = PageController();
  
  PackageTabState _state = (
    packages: <PackageInfo>[],
    isLoading: false,
    error: null,
    searchQuery: '',
    filter: AppTypeFilter.user,
    selectedPackage: null,
  );

  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!_hasLoaded) _loadPackages();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateState(PackageTabState Function(PackageTabState) updater) {
    if (mounted) setState(() => _state = updater(_state));
  }

  Future<void> _loadPackages() async {
    if (_hasLoaded) return;
    
    _updateState((s) => (
      packages: s.packages,
      isLoading: true,
      error: null,
      searchQuery: s.searchQuery,
      filter: s.filter,
      selectedPackage: s.selectedPackage,
    ));

    try {
      final packages = await widget.packageRepository.getAllPackages();
      _hasLoaded = true;
      _updateState((s) => (
        packages: packages,
        isLoading: false,
        error: null,
        searchQuery: s.searchQuery,
        filter: s.filter,
        selectedPackage: s.selectedPackage,
      ));
    } catch (e) {
      _updateState((s) => (
        packages: s.packages,
        isLoading: false,
        error: 'Failed to load packages: $e',
        searchQuery: s.searchQuery,
        filter: s.filter,
        selectedPackage: s.selectedPackage,
      ));
    }
  }

  Future<void> _refreshPackages() async {
    _hasLoaded = false;
    await _loadPackages();
  }

  Future<void> _handlePackageAction(PackageAction action, PackageInfo pkg) async {
    switch (action) {
      case PackageAction.start:
        await context.runWithFeedback(
          action: () => widget.packageRepository.launchPackage(pkg.packageName),
          successMessage: 'Started ${pkg.name}',
          errorMessage: 'Failed to start ${pkg.name}',
        );
      case PackageAction.stop:
        await context.runWithFeedback(
          action: () => widget.packageRepository.stopPackage(pkg.packageName),
          successMessage: 'Stopped ${pkg.name}',
          errorMessage: 'Failed to stop ${pkg.name}',
        );
      case PackageAction.details:
        await _showPackageDetails(pkg);
      case PackageAction.uninstall:
        await _uninstallPackage(pkg);
    }
  }

  Future<void> _showPackageDetails(PackageInfo pkg) async {
    // Update URL
    context.go('/packages/details?package=${pkg.packageName}');
    
    _updateState((s) => (
      packages: s.packages,
      isLoading: s.isLoading,
      error: s.error,
      searchQuery: s.searchQuery,
      filter: s.filter,
      selectedPackage: pkg,
    ));

    _pageController.animateToPage(1, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _installApk() async {
    await context.runWithFeedback(
      action: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['apk'],
          withData: true,
        );

        if (result?.files.single.bytes case final bytes? when mounted) {
          final confirmed = await DialogUtils.showConfirmationDialog(
            context,
            title: 'Install APK',
            message: 'Install ${result!.files.single.name}?',
            confirmText: 'Install',
          );

          if (confirmed) {
            await widget.packageRepository.installApk(bytes);
            await _refreshPackages();
          }
        }
      },
      successMessage: 'APK installed successfully',
      errorMessage: 'Failed to install APK',
    );
  }

  Future<void> _uninstallPackage(PackageInfo pkg) async {
    final confirmed = await DialogUtils.showConfirmationDialog(
      context,
      title: 'Uninstall Package',
      message: 'Are you sure you want to uninstall ${pkg.name}?',
      confirmText: 'Uninstall',
      confirmButtonColor: Colors.red,
    );

    if (confirmed && mounted) {
      await context.runWithFeedback(
        action: () async {
          await widget.packageRepository.uninstallPackage(pkg.packageName);
          await _refreshPackages();
        },
        successMessage: 'Uninstalled ${pkg.name}',
        errorMessage: 'Failed to uninstall ${pkg.name}',
      );
    }
  }

  void _goBackToList() {
    context.go('/packages');
    _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  // Public methods for URL navigation
  Future<void> navigateToPackageDetails(String packageName) async {
    final pkg = _state.packages.firstWhere(
      (p) => p.packageName == packageName,
      orElse: () => PackageInfo(
        name: packageName,
        packageName: packageName,
        iconBase64: '',
        isRunning: false,
        canLaunch: true,
        isSystemApp: false,
        isUpdatedSystemApp: false,
      ),
    );
    await _showPackageDetails(pkg);
  }

  void navigateToPackageList() {
    _goBackToList();
  }

  List<PackageInfo> get _filteredPackages => _state.packages.where((pkg) {
    final matchesSearch = pkg.name.toLowerCase().contains(_state.searchQuery.toLowerCase()) ||
        pkg.packageName.toLowerCase().contains(_state.searchQuery.toLowerCase());
    
    final matchesFilter = switch (_state.filter) {
      AppTypeFilter.all => true,
      AppTypeFilter.user => !pkg.isSystemApp,
      AppTypeFilter.system => pkg.isSystemApp,
    };
    
    return matchesSearch && matchesFilter;
  }).toList();

  PackageState get _listPageState => (
    packages: _state.packages,
    isLoading: _state.isLoading,
    error: _state.error,
    searchQuery: _state.searchQuery,
    filter: _state.filter,
  );

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      children: [
        PackageListPage(
          state: _listPageState,
          filteredPackages: _filteredPackages,
          onSearchChanged: (query) => _updateState((s) => (
            packages: s.packages,
            isLoading: s.isLoading,
            error: s.error,
            searchQuery: query,
            filter: s.filter,
            selectedPackage: s.selectedPackage,
          )),
          onFilterChanged: (filter) => _updateState((s) => (
            packages: s.packages,
            isLoading: s.isLoading,
            error: s.error,
            searchQuery: s.searchQuery,
            filter: filter,
            selectedPackage: s.selectedPackage,
          )),
          onRefresh: _refreshPackages,
          onInstallApk: _installApk,
          onPackageAction: _handlePackageAction,
        ),
        PackageDetailsPage(
          package: _state.selectedPackage,
          repository: widget.packageRepository,
          onBack: _goBackToList,
          onPackageAction: _handlePackageAction,
        ),
      ],
    );
  }
}