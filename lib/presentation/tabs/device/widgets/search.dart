import 'package:flutter/material.dart';

class CustomSearchField extends StatefulWidget {
  const CustomSearchField({
    super.key,
    required this.onChanged,
    required this.onRefresh,
    this.hintText = 'Search...',
    this.isLoading = false,
    this.animationController,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;
  final String hintText;
  final bool isLoading;
  final AnimationController? animationController;

  @override
  State<CustomSearchField> createState() => _CustomSearchFieldState();
}

class CompactSearchField extends StatefulWidget {
  const CompactSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search...',
    this.onRefresh,
    this.isLoading = false,
    this.animationController,
  });

  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final AnimationController? animationController;

  @override
  State<CompactSearchField> createState() => _CompactSearchFieldState();
}

class _CustomSearchFieldState extends State<CustomSearchField> {
  final TextEditingController _controller = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    widget.onChanged(value);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _searchQuery = '');
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(25)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(150),
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(25)),
            ),
            child: GestureDetector(
              onTap: widget.onRefresh,
              child: widget.isLoading && widget.animationController != null
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: RotationTransition(
                        turns: widget.animationController!,
                        child: Icon(
                          Icons.refresh,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSearchFieldState extends State<CompactSearchField> {
  final TextEditingController _controller = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    widget.onChanged(value);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _searchQuery = '');
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onRefresh != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(25)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(150),
                            fontSize: 13,
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _clearSearch,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(25)),
              ),
              child: GestureDetector(
                onTap: widget.onRefresh,
                child: widget.isLoading && widget.animationController != null
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: RotationTransition(
                          turns: widget.animationController!,
                          child: Icon(
                            Icons.refresh,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(150),
                  fontSize: 13,
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}