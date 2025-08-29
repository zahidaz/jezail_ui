import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jezail_ui/app_config.dart';
import 'package:jezail_ui/services/device_service.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';
import 'package:jezail_ui/presentation/utils/dialog_utils.dart';
import 'package:jezail_ui/core/log.dart';
import 'package:jezail_ui/core/enums/battery_level.dart';
import 'package:jezail_ui/models/device/device_info.dart';

class Header extends StatefulWidget {
  const Header({super.key, required this.deviceService, this.onToggleSidebar});

  final DeviceService deviceService;
  final VoidCallback? onToggleSidebar;

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  Map<String, dynamic>? _info;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadInfo();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadInfo());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await widget.deviceService.getDeviceInfo();
      if (mounted) setState(() => _info = info);
    } catch (e) {
      Log.error('Failed to load device info', e);
    }
  }

  DeviceInfo get _deviceInfo => (
    name: _info?['data']?['deviceName'] ?? 'Unknown Device',
    battery: _info?['data']?['batteryLevel'] ?? 0,
    charging: _info?['data']?['isCharging'] ?? false,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (:name, :battery, :charging) = _deviceInfo;
    
    return Material(
      elevation: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 64,
            color: theme.colorScheme.primary,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 800;
                
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: widget.onToggleSidebar ?? () {},
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 24),
                      child: Text(
                        AppConfig.appName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (!isCompact) _badge(name),
                    const Spacer(),
                    _batteryWidget(battery, charging),
                    const SizedBox(width: 8),
                    if (isCompact)
                      IconButton(
                        icon: Icon(
                          _controller.isCompleted ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white,
                        ),
                        onPressed: () => _controller.isCompleted 
                          ? _controller.reverse() 
                          : _controller.forward(),
                        tooltip: 'More controls',
                      )
                    else
                      ..._controls(),
                  ],
                );
              },
            ),
          ),
          SizeTransition(
            sizeFactor: _controller,
            child: Container(
              width: double.infinity,
              color: theme.colorScheme.primary.withValues(alpha: 0.9),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _badge(name),
                      const SizedBox(width: 8),
                      _batteryWidget(battery, charging),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _controls(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _batteryWidget(int level, bool charging) {
    final batteryLevel = BatteryLevelExtension.fromPercent(level);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            charging ? Icons.battery_charging_full : batteryLevel.icon,
            color: charging ? Colors.green : batteryLevel.color,
            size: 16,
          ),
          const SizedBox(width: 2),
          Text(
            '$level%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _controls() => [
    _group([
      _btn(Icons.apps, widget.deviceService.pressRecentApps, 'Recent Apps'),
      _btn(Icons.home, widget.deviceService.pressHome, 'Home'),
      _btn(Icons.arrow_back, widget.deviceService.pressBack, 'Back'),
    ]),
    _group([
      _btn(Icons.volume_up, widget.deviceService.pressVolumeUp, 'Volume Up'),
      _btn(Icons.volume_down, widget.deviceService.pressVolumeDown, 'Volume Down'),
      _btn(Icons.volume_off, widget.deviceService.muteVolume, 'Mute'),
    ]),
    _group([
      _btnCustom(Icons.content_copy, _copy, 'Copy Clipboard'),
      _btnCustom(Icons.content_paste, _set, 'Set Clipboard'),
      _btn(Icons.clear, widget.deviceService.clearClipboard, 'Clear Clipboard'),
    ]),
    _single(Icons.lock, widget.deviceService.pressPower, 'Screen Lock'),
    _single(Icons.screenshot, widget.deviceService.downloadScreenshot, 'Screenshot'),
  ];

  Widget _group(List<Widget> children) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: children),
  );

  Widget _btn(IconData icon, Future<void> Function() action, String tooltip) =>
    IconButton(
      icon: Icon(icon, color: Colors.white, size: 18),
      onPressed: () => context.runWithFeedback(
        action: action,
        successMessage: '',
        errorMessage: '',
      ),
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    );

  Widget _single(IconData icon, Future<void> Function() action, String tooltip) =>
    IconButton(
      icon: Icon(icon, color: Colors.white, size: 20),
      onPressed: () => context.runWithFeedback(
        action: action,
        successMessage: '',
        errorMessage: '',
      ),
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    );

  Widget _btnCustom(IconData icon, VoidCallback action, String tooltip) =>
    IconButton(
      icon: Icon(icon, color: Colors.white, size: 18),
      onPressed: action,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    );

  Future<void> _copy() async {
    try {
      final content = await widget.deviceService.getClipboard();
      if (!mounted) return;
      
      switch (content) {
        case null || '':
          context.showWarningSnackBar('Clipboard is empty');
        case final String value:
          context.showSuccessSnackBar(
            'Clipboard copied',
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () => DialogUtils.showContentDialog(
                context,
                title: 'Clipboard Content',
                content: SelectableText(value),
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to copy clipboard');
    }
  }

  Future<void> _set() async {
    if (!mounted) return;
    
    final result = await DialogUtils.showTextInputDialog(
      context,
      title: 'Set Clipboard',
      hintText: 'Enter new clipboard text',
      confirmText: 'Set',
    );
    
    if (result case final String value when value.isNotEmpty && mounted) {
      await context.runWithFeedback(
        action: () => widget.deviceService.setClipboard(value),
        successMessage: 'Clipboard updated',
        errorMessage: 'Failed to set clipboard',
      );
    }
  }
}