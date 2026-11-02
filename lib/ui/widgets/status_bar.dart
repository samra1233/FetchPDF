import 'package:flutter/material.dart';
import '../../models/document_tab.dart';
import '../../state/editor_tab_controller.dart';

class BottomStatusBar extends StatelessWidget {
  final DocumentTab? tab;
  final EditorTabController? controller;

  const BottomStatusBar({
    required this.tab,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return ListenableBuilder(
        listenable: controller!,
        builder: (context, _) => _buildBar(context),
      );
    }
    return _buildBar(context);
  }

  Widget _buildBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF202020) : const Color(0xFFEBEBEB);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFDADADA);

    final currentPage = tab?.activePageIndex ?? 1;
    final totalPages = tab?.pages.length ?? 1;
    final zoomPercent = ((controller?.zoomScale ?? 1.0) * 100).round();

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;
          final isMedium = constraints.maxWidth >= 600;

          return Row(
            children: [
              // Page Navigation
              if (isWide)
                IconButton(
                  icon: const Icon(Icons.first_page_rounded, size: 16),
                  tooltip: 'First Page',
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  onPressed: tab != null && currentPage > 1 ? () => controller?.goToPage(1) : null,
                ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                tooltip: 'Previous Page',
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                onPressed: tab != null && currentPage > 1 ? () => controller?.goToPage(currentPage - 1) : null,
              ),
              Text(
                ' $currentPage / $totalPages ',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                tooltip: 'Next Page',
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                onPressed: tab != null && currentPage < totalPages ? () => controller?.goToPage(currentPage + 1) : null,
              ),
              if (isWide)
                IconButton(
                  icon: const Icon(Icons.last_page_rounded, size: 16),
                  tooltip: 'Last Page',
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  onPressed: tab != null && currentPage < totalPages ? () => controller?.goToPage(totalPages) : null,
                ),

              if (isMedium && controller != null) ...[
                const SizedBox(width: 12),
                Text(
                  'Mode: ${_toolName(controller!.toolMode)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],

              const Spacer(),

              // Document Save Status
              if (tab != null && isMedium)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: tab!.isModified ? Colors.amber : const Color(0xFF107C41),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab!.isModified ? 'Unsaved edits' : 'Saved',
                      style: TextStyle(
                        fontSize: 11,
                        color: tab!.isModified ? Colors.amber : const Color(0xFF107C41),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

              const SizedBox(width: 16),

              // Zoom Controls
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                tooltip: 'Zoom Out (Ctrl+-)',
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                onPressed: controller != null ? () => controller!.zoomOut() : null,
              ),
              SizedBox(
                width: isWide ? 90 : 60,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                  ),
                  child: Slider(
                    value: (controller?.zoomScale ?? 1.0).clamp(0.25, 4.0),
                    min: 0.25,
                    max: 4.0,
                    onChanged: controller != null ? (val) => controller!.setZoom(val) : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                tooltip: 'Zoom In (Ctrl++)',
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                onPressed: controller != null ? () => controller!.zoomIn() : null,
              ),

              // Zoom preset dropup/menu
              PopupMenuButton<double>(
                tooltip: 'Zoom Presets',
                initialValue: controller?.zoomScale,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$zoomPercent%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                itemBuilder: (context) => [
                  _buildZoomItem(0.5, '50%'),
                  _buildZoomItem(0.75, '75%'),
                  _buildZoomItem(1.0, '100% (Actual Size)'),
                  _buildZoomItem(1.25, '125%'),
                  _buildZoomItem(1.5, '150%'),
                  _buildZoomItem(2.0, '200%'),
                  _buildZoomItem(3.0, '300%'),
                ],
                onSelected: (scale) => controller?.setZoom(scale),
              ),

              if (isWide) ...[
                // Fit Width
                IconButton(
                  icon: const Icon(Icons.fit_screen_outlined, size: 16),
                  tooltip: 'Fit Width',
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  onPressed: controller != null ? () => controller!.fitWidth() : null,
                ),

                // Fit Page
                IconButton(
                  icon: const Icon(Icons.fullscreen_outlined, size: 16),
                  tooltip: 'Fit Whole Page',
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  onPressed: controller != null ? () => controller!.fitPage() : null,
                ),

                // Reset Zoom
                IconButton(
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  tooltip: 'Reset to 100%',
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  onPressed: controller != null ? () => controller!.resetZoom() : null,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  PopupMenuItem<double> _buildZoomItem(double val, String text) {
    return PopupMenuItem(
      value: val,
      height: 32,
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  String _toolName(EditorToolMode mode) {
    switch (mode) {
      case EditorToolMode.hand:
        return 'Hand';
      case EditorToolMode.selectText:
        return 'Select Text';
      case EditorToolMode.textBox:
        return 'Insert Text Box';
      case EditorToolMode.editText:
        return 'Edit Text';
      case EditorToolMode.highlight:
        return 'Highlight';
      case EditorToolMode.underline:
        return 'Underline';
      case EditorToolMode.strikethrough:
        return 'Strikethrough';
      case EditorToolMode.pen:
        return 'Freehand Pen';
      case EditorToolMode.eraser:
        return 'Eraser';
      case EditorToolMode.line:
        return 'Line';
      case EditorToolMode.arrow:
        return 'Arrow';
      case EditorToolMode.rectangle:
        return 'Rectangle';
      case EditorToolMode.ellipse:
        return 'Ellipse';
      case EditorToolMode.stickyNote:
        return 'Sticky Note';
      case EditorToolMode.stamp:
        return 'Stamp';
      case EditorToolMode.image:
        return 'Image';
    }
  }
}
