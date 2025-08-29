import 'package:flutter/material.dart';

import 'package:jezail_ui/repositories/device_repository.dart';
import 'package:jezail_ui/presentation/tabs/device/info.dart';
import 'package:jezail_ui/presentation/tabs/device/processes.dart';
import 'package:jezail_ui/presentation/tabs/device/logs.dart';
import 'package:jezail_ui/presentation/tabs/device/controls.dart';

class DeviceTab extends StatefulWidget {
  const DeviceTab({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<DeviceTab> createState() => _DeviceTabState();
}

class _DeviceTabState extends State<DeviceTab> with TickerProviderStateMixin {
  late final TabController _controller;

  final _tabConfigs = [
    ('Info', Icons.info, (repo) => InfoTab(repository: repo)),
    ('Processes', Icons.list, (repo) => ProcessesTab(repository: repo)),
    ('Logs', Icons.article, (repo) => LogsTab(repository: repo)),
    ('Controls', Icons.gamepad, (repo) => ControlsTab(repository: repo)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: _tabConfigs.length, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TabBar(
        controller: _controller,
        tabs: _tabConfigs.map((config) => Tab(text: config.$1, icon: Icon(config.$2))).toList(),
      ),
      Expanded(
        child: TabBarView(
          controller: _controller,
          children: _tabConfigs.map((config) => config.$3(widget.repository)).toList(),
        ),
      ),
    ],
  );
}