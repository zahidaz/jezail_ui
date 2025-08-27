import 'package:flutter/material.dart';
import 'package:jezail_ui/repositories/tool_repository.dart';
import 'package:jezail_ui/presentation/tabs/tools/frida_tool.dart';
import 'package:jezail_ui/presentation/tabs/tools/adb_tool.dart';

class ToolsTab extends StatefulWidget {
  final ToolRepository repository;
  const ToolsTab({super.key, required this.repository});

  @override
  State<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab> {

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              FridaTool(repository: widget.repository),
              const SizedBox(height: 16),
              AdbTool(repository: widget.repository),
            ],
          ),
        ),
      ),
    );
  }
}