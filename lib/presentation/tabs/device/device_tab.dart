import 'package:flutter/material.dart';

import '../../../repositories/device_repository.dart';
import 'overview_tab.dart';
import 'processes_tab.dart';
import 'logs_tab.dart';
import 'system_tab.dart';
import 'controls_tab.dart';
import 'storage_tab.dart';

class DeviceTab extends StatefulWidget {
  const DeviceTab({super.key, required this.repository});
  final DeviceRepository repository;

  @override
  State<DeviceTab> createState() => _DeviceTabState();
}

class _DeviceTabState extends State<DeviceTab> with TickerProviderStateMixin {
  late final TabController _controller;

  final _tabConfigs = [
    ('Overview', Icons.dashboard, (repo) => OverviewTab(repository: repo)),
    ('Controls', Icons.gamepad, (repo) => ControlsTab(repository: repo)),
    ('Processes', Icons.list, (repo) => ProcessesTab(repository: repo)),
    ('Logs', Icons.article, (repo) => LogsTab(repository: repo)),
    ('System', Icons.computer, (repo) => SystemTab(repository: repo)),
    ('Storage', Icons.storage, (repo) => StorageTab(repository: repo)),
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