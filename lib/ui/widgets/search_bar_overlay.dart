import 'package:flutter/material.dart';
import '../../state/editor_tab_controller.dart';

class SearchBarOverlay extends StatefulWidget {
  final EditorTabController controller;

  const SearchBarOverlay({required this.controller, super.key});

  @override
  State<SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends State<SearchBarOverlay> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.searchQuery);
  }

  @override
  void didUpdateWidget(SearchBarOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.searchQuery != _textController.text) {
      _textController.text = widget.controller.searchQuery;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searcher = widget.controller.textSearcher;
    final totalMatches = searcher?.matches.length ?? 0;
    final currentIndex = searcher?.currentIndex;
    final isSearching = searcher?.isSearching ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String matchText = '';
    if (isSearching) {
      matchText = 'Searching...';
    } else if (_textController.text.isNotEmpty) {
      if (totalMatches > 0) {
        matchText = '${(currentIndex ?? 0) + 1} of $totalMatches';
      } else {
        matchText = '0 matches';
      }
    }

    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282828) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF404040) : const Color(0xFFD0D0D0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search text...',
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) => widget.controller.setSearchQuery(val),
              onSubmitted: (_) => widget.controller.nextSearchResult(),
            ),
          ),
          if (matchText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                matchText,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, size: 18),
            tooltip: 'Previous match (Shift+Enter)',
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: totalMatches > 0 ? () => widget.controller.prevSearchResult() : null,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            tooltip: 'Next match (Enter)',
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: totalMatches > 0 ? () => widget.controller.nextSearchResult() : null,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Close (Esc)',
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => widget.controller.toggleSearch(),
          ),
        ],
      ),
    );
  }
}
