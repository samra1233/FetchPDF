import 'package:flutter/material.dart';
import '../../models/document_tab.dart';
import '../../state/app_state.dart';
import 'confirm_discard_dialog.dart';

class TabBarHeader extends StatelessWidget {
  final AppState appState;

  const TabBarHeader({required this.appState, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE8E8E8);
    final activeTabBg = isDark ? const Color(0xFF282828) : Colors.white;
    final inactiveTabBg = Colors.transparent;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFD6D6D6);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Tabs list
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: appState.tabs.length,
              itemBuilder: (context, index) {
                final tab = appState.tabs[index];
                final isActive = index == appState.activeTabIndex;

                return GestureDetector(
                  onTap: () => appState.selectTab(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                    decoration: BoxDecoration(
                      color: isActive ? activeTabBg : inactiveTabBg,
                      border: Border(
                        right: BorderSide(color: borderColor, width: 0.8),
                        top: isActive
                            ? const BorderSide(color: Color(0xFF0078D4), width: 2.5)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 16,
                          color: Color(0xFFE53935), // PDF Red
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tab.fileName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              color: isActive
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                        // Unsaved changes indicator
                        if (tab.isModified)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0078D4),
                              shape: BoxShape.circle,
                            ),
                          ),
                        // Close tab button
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => _handleCloseTab(context, index, tab),
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Icon(Icons.close, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Add tab button
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Open PDF Document',
            splashRadius: 16,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () => appState.openFile(),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _handleCloseTab(BuildContext context, int index, DocumentTab tab) {
    appState.closeTab(
      index,
      confirmDiscard: (t) async {
        final choice = await ConfirmDiscardDialog.show(context, t.fileName);
        if (choice == DiscardChoice.save) {
          final saved = await appState.saveActiveDocument();
          return saved;
        } else if (choice == DiscardChoice.discard) {
          return true;
        }
        return false;
      },
    );
  }
}
