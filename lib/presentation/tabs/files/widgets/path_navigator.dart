import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jezail_ui/core/extensions/snackbar_extensions.dart';

class PathNavigator extends StatefulWidget {
  const PathNavigator({
    super.key,
    required this.currentPath,
    required this.pathController,
    required this.onNavigate,
    required this.onFilterChanged,
  });

  final String currentPath;
  final TextEditingController pathController;
  final void Function(String) onNavigate;
  final void Function(String) onFilterChanged;

  @override
  State<PathNavigator> createState() => _PathNavigatorState();
}

class _PathNavigatorState extends State<PathNavigator> {
  bool _isEditingPath = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _copyPath(context),
            icon: const Icon(Icons.content_copy),
            tooltip: 'Copy path',
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _isEditingPath 
              ? _buildPathEditor(theme)
              : _buildBreadcrumbTrail(theme),
          ),
          IconButton(
            onPressed: () => setState(() => _isEditingPath = !_isEditingPath),
            icon: Icon(_isEditingPath ? Icons.done : Icons.edit),
            tooltip: _isEditingPath ? 'Done editing' : 'Edit path',
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 16),
          _buildSearchSection(theme),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildPathEditor(ThemeData theme) {
    return TextField(
      controller: widget.pathController,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.folder, size: 16),
        hintText: 'Enter path...',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onSubmitted: (path) {
        widget.onNavigate(path);
        setState(() => _isEditingPath = false);
      },
      autofocus: true,
    );
  }

  Widget _buildBreadcrumbTrail(ThemeData theme) {
    final parts = widget.currentPath
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRootButton(theme),
                  ..._buildPathSegments(theme, parts),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRootButton(ThemeData theme) {
    return _buildClickableSegment(theme, '/', () => widget.onNavigate('/'));
  }

  Widget _buildClickableSegment(ThemeData theme, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPathSegments(ThemeData theme, List<String> pathParts) {
    final widgets = <Widget>[];
    
    for (int i = 0; i < pathParts.length; i++) {
      final isCurrentDirectory = i == pathParts.length - 1;
      final fullPath = '/${pathParts.take(i + 1).join('/')}';
      
      if (isCurrentDirectory) {
        widgets.add(_buildCurrentDirectory(theme, pathParts[i]));
      } else {
        widgets.add(_buildClickableSegment(
          theme,
          pathParts[i],
          () => widget.onNavigate(fullPath),
        ));
        widgets.add(_buildPathSeparator(theme));
      }
    }
    
    return widgets;
  }

  Widget _buildSearchSection(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSearchExpanded ? 300 : 48,
      child: Row(
        children: [
          if (_isSearchExpanded) _buildSearchField(),
          if (!_isSearchExpanded) _buildSearchButton(),
          if (_isSearchExpanded) _buildCloseSearchButton(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Expanded(
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Filter files...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: _clearSearch,
                )
              : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        onChanged: widget.onFilterChanged,
      ),
    );
  }

  Widget _buildSearchButton() {
    return IconButton(
      onPressed: _expandSearch,
      icon: const Icon(Icons.search),
      tooltip: 'Search/Filter files',
    );
  }

  Widget _buildCloseSearchButton() {
    return IconButton(
      onPressed: _closeSearch,
      icon: const Icon(Icons.close, size: 20),
    );
  }

  Widget _buildCurrentDirectory(ThemeData theme, String directoryName) {
    return Text(
      directoryName,
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPathSeparator(ThemeData theme) {
    return Text(
      ' / ',
      style: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  void _copyPath(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.currentPath));
    context.showInfoSnackBar('Path copied: ${widget.currentPath}');
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onFilterChanged('');
  }

  void _expandSearch() {
    setState(() {
      _isSearchExpanded = true;
    });
  }

  void _closeSearch() {
    setState(() {
      _isSearchExpanded = false;
      _searchController.clear();
      widget.onFilterChanged('');
    });
  }
}
