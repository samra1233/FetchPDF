import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../models/document_tab.dart';
import '../../state/editor_tab_controller.dart';

class ThumbnailSidebar extends StatelessWidget {
  final DocumentTab tab;
  final EditorTabController controller;

  const ThumbnailSidebar({
    required this.tab,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF222222) : const Color(0xFFF7F7F7);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5);

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pages (${tab.pages.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  'P. ${tab.activePageIndex}',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),

          // Thumbnails List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              itemCount: tab.pages.length,
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                final pageInfo = tab.pages[index];
                final isActive = tab.activePageIndex == pageNumber;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    children: [
                      // Thumbnail Card
                      GestureDetector(
                        onTap: () {
                          controller.goToPage(pageNumber);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isActive ? const Color(0xFF0078D4) : borderColor,
                              width: isActive ? 2.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: AspectRatio(
                              aspectRatio: pageInfo.sizeInPoints.width / pageInfo.sizeInPoints.height,
                              child: Container(
                                color: Colors.white,
                                child: controller.pdfViewerController.isReady
                                    ? PdfPageView(
                                        document: controller.pdfViewerController.document,
                                        pageNumber: pageNumber,
                                        maximumDpi: 100,
                                      )
                                    : Center(
                                        child: Text(
                                          'Page $pageNumber',
                                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Page Label & Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page $pageNumber',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? const Color(0xFF0078D4) : null,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Rotate CW
                              _buildActionIcon(
                                icon: Icons.rotate_right_rounded,
                                tooltip: 'Rotate 90° Clockwise',
                                onPressed: () => tab.rotatePage(index, 90),
                              ),
                              // Move Up
                              _buildActionIcon(
                                icon: Icons.arrow_upward_rounded,
                                tooltip: 'Move Page Up',
                                onPressed: index > 0 ? () => tab.reorderPage(index, index - 1) : null,
                              ),
                              // Move Down
                              _buildActionIcon(
                                icon: Icons.arrow_downward_rounded,
                                tooltip: 'Move Page Down',
                                onPressed: index < tab.pages.length - 1 ? () => tab.reorderPage(index, index + 1) : null,
                              ),
                              // Delete Page
                              _buildActionIcon(
                                icon: Icons.delete_outline_rounded,
                                tooltip: tab.pages.length > 1 ? 'Delete Page $pageNumber' : 'Cannot delete the only page',
                                color: Colors.redAccent,
                                onPressed: tab.pages.length > 1
                                    ? () => _confirmDeletePage(context, index, pageNumber)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 15,
            color: onPressed == null ? Colors.grey.withAlpha(80) : color,
          ),
        ),
      ),
    );
  }

  void _confirmDeletePage(BuildContext context, int pageIndex, int pageNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Delete Page', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete Page $pageNumber from the document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              tab.deletePage(pageIndex);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
