import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/document_tab.dart';
import '../../../services/file_service.dart';
import '../../../services/pdf_document_service.dart';
import '../../../services/pdf_page_service.dart';
import '../../../state/app_state.dart';

class OrganizeScreen extends StatefulWidget {
  final AppState appState;

  const OrganizeScreen({required this.appState, super.key});

  @override
  State<OrganizeScreen> createState() => _OrganizeScreenState();
}

class _OrganizeScreenState extends State<OrganizeScreen> {
  final Set<int> _selectedPages = {};
  int _activePreviewPage = 0;
  double _gridZoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final activeTab = widget.appState.activeTab;
    final isDark = widget.appState.isDarkMode;

    if (activeTab == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grid_view_rounded, size: 56, color: AppColors.brandPrimary),
            const SizedBox(height: 16),
            const Text('No Document Open', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Please open a PDF document to organize its pages.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Open PDF'),
              onPressed: () => widget.appState.openFile(),
            ),
          ],
        ),
      );
    }

    final totalPages = activeTab.pageCount;
    if (_activePreviewPage >= totalPages) {
      _activePreviewPage = totalPages - 1;
    }

    return Column(
      children: [
        // 1. Organize Action Ribbon Toolbar
        _buildOrganizeToolbar(activeTab, isDark),

        // 2. Main Body: Left Rail + Center Grid + Right Inspector
        Expanded(
          child: Row(
            children: [
              // Left Icon Rail
              _buildLeftRail(isDark),

              // Center Page Grid
              Expanded(
                child: Container(
                  color: isDark ? const Color(0xFF13151F) : AppColors.appBackground,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220 * _gridZoom,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 22,
                    ),
                    itemCount: totalPages,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedPages.contains(index);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedPages.contains(index)) {
                              _selectedPages.remove(index);
                            } else {
                              _selectedPages.add(index);
                            }
                            _activePreviewPage = index;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2135) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brandPrimary
                                  : (isDark ? const Color(0xFF333852) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 2.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.brandPrimary.withAlpha(40)
                                    : Colors.black.withAlpha(isDark ? 30 : 10),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Bar with Checkbox
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                      size: 18,
                                      color: isSelected ? AppColors.brandPrimary : const Color(0xFF94A3B8),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Thumbnail View
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7)),
                                  child: Container(
                                    color: Colors.white,
                                    child: FutureBuilder<PdfDocument>(
                                      future: PdfDocument.openData(activeTab.documentBytes),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData || index >= snapshot.data!.pages.length) {
                                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                        }
                                        return PdfPageView(
                                          document: snapshot.data!,
                                          pageNumber: index + 1,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Right Inspector: Page Options & Preview
              _buildRightPageOptions(activeTab, isDark),
            ],
          ),
        ),

        // 3. Bottom Status Bar
        _buildBottomBar(totalPages, isDark),
      ],
    );
  }

  Widget _buildOrganizeToolbar(DocumentTab activeTab, bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E2B) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF2E3245) : AppColors.borderLight)),
      ),
      child: Row(
        children: [
          // Select All Checkbox
          InkWell(
            onTap: () {
              setState(() {
                if (_selectedPages.length == activeTab.pageCount) {
                  _selectedPages.clear();
                } else {
                  _selectedPages.addAll(List.generate(activeTab.pageCount, (i) => i));
                }
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _selectedPages.length == activeTab.pageCount
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 18,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: 6),
                  const Text('Select All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 24, indent: 8, endIndent: 8),

          _buildToolbarAction(
            icon: Icons.rotate_left_rounded,
            label: 'Rotate Left',
            onTap: () => _rotateSelected(activeTab, clockwise: false),
            isDark: isDark,
          ),
          _buildToolbarAction(
            icon: Icons.rotate_right_rounded,
            label: 'Rotate Right',
            onTap: () => _rotateSelected(activeTab, clockwise: true),
            isDark: isDark,
          ),
          _buildToolbarAction(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            color: const Color(0xFFEF4444),
            onTap: () => _deleteSelected(activeTab),
            isDark: isDark,
          ),
          _buildToolbarAction(
            icon: Icons.output_rounded,
            label: 'Extract',
            onTap: () => _extractSelected(activeTab),
            isDark: isDark,
          ),
          _buildToolbarAction(
            icon: Icons.add_to_photos_outlined,
            label: 'Insert Blank',
            onTap: () => _insertBlankPage(activeTab),
            isDark: isDark,
          ),
          _buildToolbarAction(
            icon: Icons.call_split_rounded,
            label: 'Split',
            onTap: () => _splitDocument(activeTab),
            isDark: isDark,
          ),
          _buildToolbarAction(
            icon: Icons.layers_outlined,
            label: 'Merge',
            onTap: () => _mergeWithAnotherPdf(activeTab),
            isDark: isDark,
          ),

          const Spacer(),

          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 18),
            tooltip: 'Undo',
            onPressed: activeTab.undoRedo.canUndo ? () => activeTab.undoRedo.undo() : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, size: 18),
            tooltip: 'Redo',
            onPressed: activeTab.undoRedo.canRedo ? () => activeTab.undoRedo.redo() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color ?? (isDark ? Colors.white70 : AppColors.textPrimary)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color ?? (isDark ? Colors.white : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftRail(bool isDark) {
    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E2B) : Colors.white,
        border: Border(right: BorderSide(color: isDark ? const Color(0xFF2E3245) : AppColors.borderLight)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildRailItem(Icons.grid_view_rounded, 'Pages', true, isDark),
          _buildRailItem(Icons.bookmark_border_rounded, 'Bookmarks', false, isDark),
          _buildRailItem(Icons.comment_outlined, 'Comments', false, isDark),
          _buildRailItem(Icons.attach_file_rounded, 'Attachments', false, isDark),
          _buildRailItem(Icons.layers_outlined, 'Layers', false, isDark),
        ],
      ),
    );
  }

  Widget _buildRailItem(IconData icon, String label, bool isSelected, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? (isDark ? const Color(0xFF312E81) : AppColors.activeNavBg) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: isSelected ? AppColors.brandPrimary : const Color(0xFF94A3B8)),
        tooltip: label,
        onPressed: () {},
      ),
    );
  }

  Widget _buildRightPageOptions(DocumentTab activeTab, bool isDark) {
    final previewPage = _activePreviewPage.clamp(0, activeTab.pageCount - 1);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E2B) : Colors.white,
        border: Border(left: BorderSide(color: isDark ? const Color(0xFF2E3245) : AppColors.borderLight)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Page Options', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            // Large Preview Card
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: FutureBuilder<PdfDocument>(
                  future: PdfDocument.openData(activeTab.documentBytes),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || previewPage >= snapshot.data!.pages.length) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    return PdfPageView(
                      document: snapshot.data!,
                      pageNumber: previewPage + 1,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                'Page ${previewPage + 1} of ${activeTab.pageCount}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 16),

            // Page Operation Buttons
            _buildOptionButton(
              icon: Icons.rotate_left_rounded,
              label: 'Rotate Left',
              onTap: () => _rotatePage(activeTab, previewPage, clockwise: false),
            ),
            _buildOptionButton(
              icon: Icons.rotate_right_rounded,
              label: 'Rotate Right',
              onTap: () => _rotatePage(activeTab, previewPage, clockwise: true),
            ),
            _buildOptionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Page',
              color: const Color(0xFFEF4444),
              onTap: () => _deletePage(activeTab, previewPage),
            ),
            _buildOptionButton(
              icon: Icons.copy_rounded,
              label: 'Duplicate Page',
              onTap: () => _duplicatePage(activeTab, previewPage),
            ),
            _buildOptionButton(
              icon: Icons.output_rounded,
              label: 'Extract Page',
              onTap: () => _extractPage(activeTab, previewPage),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            const Text('Page Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('A4 (210 × 297 mm)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Text('Width: 210 mm  Height: 297 mm', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 16, color: color),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: TextStyle(fontSize: 12, color: color)),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBottomBar(int totalPages, bool isDark) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E2B) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF2E3245) : AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedPages.length} pages selected',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 14),
          Text(
            '$totalPages pages total',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Spacer(),
          const Text('Zoom: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
          SizedBox(
            width: 120,
            child: Slider(
              value: _gridZoom,
              min: 0.6,
              max: 1.6,
              onChanged: (v) => setState(() => _gridZoom = v),
            ),
          ),
        ],
      ),
    );
  }

  void _rotateSelected(DocumentTab tab, {required bool clockwise}) {
    final targets = _selectedPages.isEmpty ? [_activePreviewPage] : _selectedPages.toList();
    final updatedBytes = PdfPageService.rotatePages(
      pdfBytes: tab.documentBytes,
      pageIndices: targets,
      clockwise: clockwise,
    );
    _reloadTabWithNewBytes(tab, updatedBytes);
  }

  void _rotatePage(DocumentTab tab, int pageIndex, {required bool clockwise}) {
    final updatedBytes = PdfPageService.rotatePages(
      pdfBytes: tab.documentBytes,
      pageIndices: [pageIndex],
      clockwise: clockwise,
    );
    _reloadTabWithNewBytes(tab, updatedBytes);
  }

  void _deleteSelected(DocumentTab tab) {
    final targets = _selectedPages.isEmpty ? [_activePreviewPage] : _selectedPages.toList();
    if (targets.length >= tab.pageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete all pages in document.')),
      );
      return;
    }
    final updatedBytes = PdfPageService.deletePages(
      pdfBytes: tab.documentBytes,
      pageIndices: targets,
    );
    _selectedPages.clear();
    _reloadTabWithNewBytes(tab, updatedBytes);
  }

  void _deletePage(DocumentTab tab, int pageIndex) {
    if (tab.pageCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete the last remaining page.')),
      );
      return;
    }
    final updatedBytes = PdfPageService.deletePages(
      pdfBytes: tab.documentBytes,
      pageIndices: [pageIndex],
    );
    _selectedPages.remove(pageIndex);
    _reloadTabWithNewBytes(tab, updatedBytes);
  }

  void _duplicatePage(DocumentTab tab, int pageIndex) {
    final updatedBytes = PdfPageService.duplicatePage(
      pdfBytes: tab.documentBytes,
      pageIndex: pageIndex,
    );
    _reloadTabWithNewBytes(tab, updatedBytes);
  }

  void _insertBlankPage(DocumentTab tab) {
    final updatedBytes = PdfPageService.insertBlankPage(
      pdfBytes: tab.documentBytes,
      atIndex: _activePreviewPage + 1,
    );
    _reloadTabWithNewBytes(tab, updatedBytes);
  }

  void _extractSelected(DocumentTab tab) async {
    final targets = _selectedPages.isEmpty ? [_activePreviewPage] : _selectedPages.toList();
    final extractedBytes = PdfPageService.extractPages(
      pdfBytes: tab.documentBytes,
      pageIndices: targets,
    );
    widget.appState.openNewDocument(
      fileName: 'Extracted_${tab.title}',
    );
    // Replace with actual extracted bytes
    final newTab = widget.appState.activeTab;
    if (newTab != null) {
      newTab.updateDocumentBytes(extractedBytes);
    }
  }

  void _extractPage(DocumentTab tab, int pageIndex) {
    final extractedBytes = PdfPageService.extractPages(
      pdfBytes: tab.documentBytes,
      pageIndices: [pageIndex],
    );
    widget.appState.openNewDocument(
      fileName: 'Extracted_Page_${pageIndex + 1}_${tab.title}',
    );
    final newTab = widget.appState.activeTab;
    if (newTab != null) {
      newTab.updateDocumentBytes(extractedBytes);
    }
  }

  void _splitDocument(DocumentTab tab) {
    if (tab.pageCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document only has 1 page. Cannot split.')),
      );
      return;
    }
    final mid = tab.pageCount ~/ 2;
    final range1 = List.generate(mid, (i) => i);
    final range2 = List.generate(tab.pageCount - mid, (i) => mid + i);

    final parts = PdfPageService.splitDocument(
      pdfBytes: tab.documentBytes,
      ranges: [range1, range2],
    );

    for (int i = 0; i < parts.length; i++) {
      widget.appState.openNewDocument(
        fileName: 'Part_${i + 1}_${tab.title}',
      );
      final newTab = widget.appState.activeTab;
      if (newTab != null) {
        newTab.updateDocumentBytes(parts[i]);
      }
    }
  }

  void _mergeWithAnotherPdf(DocumentTab tab) async {
    final path = await FileService.pickPdfFile();
    if (path == null) return;
    try {
      final otherDoc = await PdfDocumentService.loadFromFile(path);
      final merged = PdfPageService.mergeDocuments([tab.documentBytes, otherDoc.documentBytes]);
      _reloadTabWithNewBytes(tab, merged);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to merge document: $e')),
      );
    }
  }

  void _reloadTabWithNewBytes(DocumentTab tab, Uint8List newBytes) {
    tab.updateDocumentBytes(newBytes);
    setState(() {});
  }
}
