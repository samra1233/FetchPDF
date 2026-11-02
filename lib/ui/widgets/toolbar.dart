import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/annotation_model.dart';
import '../../models/document_tab.dart';
import '../../state/app_state.dart';
import '../../state/editor_tab_controller.dart';
import 'create_pdf_dialog.dart';
import 'signature_dialog.dart';

class TopToolbar extends StatelessWidget {
  final AppState appState;
  final EditorTabController? controller;

  const TopToolbar({
    required this.appState,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final activeTab = appState.activeTab;
    final List<Listenable> listenables = [
      appState,
      ...?controller == null ? null : [controller!],
      ...?activeTab == null ? null : [activeTab],
      ...?activeTab?.undoRedo == null ? null : [activeTab!.undoRedo],
    ];

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final currentTab = appState.activeTab;
        final isDark = appState.isDarkMode;
        final bgColor = isDark ? const Color(0xFF1F2231) : Colors.white;
        final borderColor = isDark ? const Color(0xFF2E3245) : AppColors.borderLight;

        return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Left sidebar toggle
            _buildIconButton(
              icon: Icons.view_sidebar_outlined,
              tooltip: 'Toggle Page Thumbnails',
              isActive: appState.isLeftSidebarVisible,
              onPressed: () => appState.toggleLeftSidebar(),
            ),
            const SizedBox(width: 4),
            _buildDivider(borderColor),
            const SizedBox(width: 4),

            // File Operations
            _buildIconButton(
              icon: Icons.folder_open_outlined,
              tooltip: 'Open PDF Document (Ctrl+O)',
              onPressed: () => appState.openFile(),
            ),
            _buildIconButton(
              icon: Icons.note_add_outlined,
              tooltip: 'Create New PDF',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => CreatePdfDialog(
                    onCreated: ({
                      required size,
                      required orientation,
                      required pattern,
                      required pageCount,
                      required fileName,
                    }) {
                      appState.openNewDocument(
                        size: size,
                        orientation: orientation,
                        pattern: pattern,
                        pageCount: pageCount,
                        fileName: fileName,
                      );
                    },
                  ),
                );
              },
            ),
            _buildIconButton(
              icon: Icons.save_outlined,
              tooltip: activeTab?.isModified == true
                  ? 'Save Document (Unsaved Changes) (Ctrl+S)'
                  : 'Save Document (Ctrl+S)',
              isActive: activeTab?.isModified == true,
              activeColor: AppColors.brandPrimary,
              onPressed: activeTab != null ? () => appState.saveActiveDocument() : null,
            ),
            _buildIconButton(
              icon: Icons.save_as_outlined,
              tooltip: 'Save As... (Ctrl+Shift+S)',
              onPressed: activeTab != null ? () => appState.saveActiveDocumentAs() : null,
            ),
            _buildIconButton(
              icon: Icons.print_outlined,
              tooltip: 'Print Document (Ctrl+P)',
              onPressed: activeTab != null ? () => appState.printActiveDocument() : null,
            ),

            const SizedBox(width: 4),
            _buildDivider(borderColor),
            const SizedBox(width: 4),

            // Undo / Redo
            _buildIconButton(
              icon: Icons.undo_rounded,
              tooltip: activeTab?.undoRedo.undoDescription != null
                  ? 'Undo ${activeTab!.undoRedo.undoDescription} (Ctrl+Z)'
                  : 'Undo (Ctrl+Z)',
              onPressed: activeTab?.undoRedo.canUndo == true ? () => activeTab?.undoRedo.undo() : null,
            ),
            _buildIconButton(
              icon: Icons.redo_rounded,
              tooltip: activeTab?.undoRedo.redoDescription != null
                  ? 'Redo ${activeTab!.undoRedo.redoDescription} (Ctrl+Y)'
                  : 'Redo (Ctrl+Y)',
              onPressed: activeTab?.undoRedo.canRedo == true ? () => activeTab?.undoRedo.redo() : null,
            ),

            const SizedBox(width: 4),
            _buildDivider(borderColor),
            const SizedBox(width: 4),

            // Navigation Ribbon Switcher
            if (controller != null && activeTab != null) ...[
              if (appState.activeNav == AppNavDestination.edit)
                ..._buildEditRibbon(context, currentTab ?? activeTab, controller!, borderColor, isDark)
              else if (appState.activeNav == AppNavDestination.annotate)
                ..._buildAnnotateRibbon(context, activeTab, controller!, borderColor)
              else
                ..._buildStandardTools(context, activeTab, controller!, borderColor),
            ],

            const SizedBox(width: 4),
            _buildDivider(borderColor),
            const SizedBox(width: 4),

            // Search Button
            if (controller != null)
              _buildIconButton(
                icon: Icons.search_rounded,
                tooltip: 'Search Document Text (Ctrl+F)',
                isActive: controller!.isSearchVisible,
                onPressed: () => controller!.toggleSearch(),
              ),

            // Right Properties Panel Toggle
            _buildIconButton(
              icon: Icons.tune_rounded,
              tooltip: 'Toggle Properties Panel',
              isActive: appState.isRightPropertiesVisible,
              onPressed: () => appState.toggleRightProperties(),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  // --- EDIT RIBBON ---
  List<Widget> _buildEditRibbon(
    BuildContext context,
    DocumentTab tab,
    EditorTabController ctrl,
    Color borderColor,
    bool isDark,
  ) {
    final selected = ctrl.selectedAnnotation;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dropdownBg = isDark ? const Color(0xFF282C3D) : Colors.white;

    return [
      // 1. POINTER & NAVIGATION GROUP
      _buildToolButton(
        icon: Icons.near_me_outlined,
        label: 'Select',
        mode: EditorToolMode.selectText,
        tooltip: 'Select & Move Objects (V)',
      ),
      _buildToolButton(
        icon: Icons.pan_tool_outlined,
        label: 'Hand',
        mode: EditorToolMode.hand,
        tooltip: 'Hand / Pan Canvas (H)',
      ),
      const SizedBox(width: 4),
      _buildDivider(borderColor),
      const SizedBox(width: 4),

      // 2. TEXT GROUP
      _buildToolButton(
        icon: Icons.text_fields_rounded,
        label: 'Add Text',
        mode: EditorToolMode.textBox,
        tooltip: 'Click anywhere on page to add text (T)',
      ),
      _buildToolButton(
        icon: Icons.edit_note_rounded,
        label: 'Edit Text',
        mode: EditorToolMode.editText,
        tooltip: 'Click on text in document to edit/replace',
      ),
      const SizedBox(width: 4),
      // Font Family Dropdown
      DropdownButtonHideUnderline(
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: dropdownBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButton<String>(
            value: ctrl.activeFontFamily,
            dropdownColor: dropdownBg,
            icon: Icon(Icons.arrow_drop_down, size: 16, color: textColor),
            style: TextStyle(fontSize: 11, color: textColor),
            items: const [
              DropdownMenuItem(value: 'Helvetica', child: Text('Helvetica')),
              DropdownMenuItem(value: 'Times', child: Text('Times Roman')),
              DropdownMenuItem(value: 'Courier', child: Text('Courier')),
            ],
            onChanged: (val) {
              if (val != null) ctrl.setActiveFontFamily(val);
            },
          ),
        ),
      ),
      const SizedBox(width: 4),
      // Font Size Dropdown
      DropdownButtonHideUnderline(
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: dropdownBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButton<double>(
            value: [8.0, 9.0, 10.0, 11.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 36.0, 48.0].contains(ctrl.activeFontSize)
                ? ctrl.activeFontSize
                : 14.0,
            dropdownColor: dropdownBg,
            icon: Icon(Icons.arrow_drop_down, size: 16, color: textColor),
            style: TextStyle(fontSize: 11, color: textColor),
            items: const [
              DropdownMenuItem(value: 8.0, child: Text('8 pt')),
              DropdownMenuItem(value: 9.0, child: Text('9 pt')),
              DropdownMenuItem(value: 10.0, child: Text('10 pt')),
              DropdownMenuItem(value: 11.0, child: Text('11 pt')),
              DropdownMenuItem(value: 12.0, child: Text('12 pt')),
              DropdownMenuItem(value: 14.0, child: Text('14 pt')),
              DropdownMenuItem(value: 16.0, child: Text('16 pt')),
              DropdownMenuItem(value: 18.0, child: Text('18 pt')),
              DropdownMenuItem(value: 20.0, child: Text('20 pt')),
              DropdownMenuItem(value: 24.0, child: Text('24 pt')),
              DropdownMenuItem(value: 28.0, child: Text('28 pt')),
              DropdownMenuItem(value: 32.0, child: Text('32 pt')),
              DropdownMenuItem(value: 36.0, child: Text('36 pt')),
              DropdownMenuItem(value: 48.0, child: Text('48 pt')),
            ],
            onChanged: (val) {
              if (val != null) ctrl.setActiveFontSize(val);
            },
          ),
        ),
      ),
      const SizedBox(width: 4),
      // Bold & Italic
      _buildIconButton(
        icon: Icons.format_bold_rounded,
        tooltip: 'Bold (Ctrl+B)',
        isActive: ctrl.activeIsBold,
        onPressed: () => ctrl.toggleBold(),
      ),
      _buildIconButton(
        icon: Icons.format_italic_rounded,
        tooltip: 'Italic (Ctrl+I)',
        isActive: ctrl.activeIsItalic,
        onPressed: () => ctrl.toggleItalic(),
      ),
      // Alignment
      _buildIconButton(
        icon: Icons.format_align_left_rounded,
        tooltip: 'Align Left',
        isActive: ctrl.activeAlignment == TextAlign.left,
        onPressed: () => ctrl.setActiveAlignment(TextAlign.left),
      ),
      _buildIconButton(
        icon: Icons.format_align_center_rounded,
        tooltip: 'Align Center',
        isActive: ctrl.activeAlignment == TextAlign.center,
        onPressed: () => ctrl.setActiveAlignment(TextAlign.center),
      ),
      _buildIconButton(
        icon: Icons.format_align_right_rounded,
        tooltip: 'Align Right',
        isActive: ctrl.activeAlignment == TextAlign.right,
        onPressed: () => ctrl.setActiveAlignment(TextAlign.right),
      ),

      const SizedBox(width: 4),
      // Color Chips for Quick Text Styling
      _buildColorChip(ctrl, const Color(0xFF000000)),
      _buildColorChip(ctrl, const Color(0xFF1E293B)),
      _buildColorChip(ctrl, const Color(0xFF0078D4)),
      _buildColorChip(ctrl, const Color(0xFFEF4444)),
      _buildColorChip(ctrl, const Color(0xFF10B981)),

      const SizedBox(width: 4),
      _buildDivider(borderColor),
      const SizedBox(width: 4),

      // 2. IMAGE GROUP
      _buildActionIconButton(
        icon: Icons.add_photo_alternate_outlined,
        label: 'Add Image',
        tooltip: 'Insert Image (PNG, JPG)',
        onPressed: () => _handleAddImage(context, tab, ctrl),
      ),

      const SizedBox(width: 4),
      _buildDivider(borderColor),
      const SizedBox(width: 4),

      // 3. OBJECT MANIPULATION GROUP
      _buildIconButton(
        icon: Icons.flip_to_front_rounded,
        tooltip: 'Bring Forward',
        onPressed: selected != null ? () => tab.bringAnnotationForward(selected) : null,
      ),
      _buildIconButton(
        icon: Icons.flip_to_back_rounded,
        tooltip: 'Send Backward',
        onPressed: selected != null ? () => tab.sendAnnotationBackward(selected) : null,
      ),
      _buildIconButton(
        icon: Icons.delete_outline_rounded,
        tooltip: 'Delete Selected Object',
        onPressed: selected != null ? () => ctrl.deleteSelectedAnnotation() : null,
      ),

      const SizedBox(width: 4),
      _buildDivider(borderColor),
      const SizedBox(width: 4),

      // 4. PAGE CONTENT GROUP
      _buildActionIconButton(
        icon: Icons.branding_watermark_outlined,
        label: 'Watermark',
        tooltip: 'Apply Watermark across pages',
        onPressed: () => _showWatermarkDialog(context, tab),
      ),
      _buildActionIconButton(
        icon: Icons.format_list_numbered_rounded,
        label: 'Page Numbers',
        tooltip: 'Add Header / Footer Page Numbers',
        onPressed: () => _addPageNumbers(context, tab),
      ),
      _buildActionIconButton(
        icon: Icons.draw_rounded,
        label: 'Sign',
        tooltip: 'Insert Electronic Signature',
        onPressed: () => _handleInsertSignature(context, tab, ctrl),
      ),
    ];
  }

  // --- ANNOTATE RIBBON ---
  List<Widget> _buildAnnotateRibbon(
    BuildContext context,
    DocumentTab tab,
    EditorTabController ctrl,
    Color borderColor,
  ) {
    return [
      _buildToolButton(
        icon: Icons.near_me_outlined,
        label: 'Select',
        mode: EditorToolMode.selectText,
        tooltip: 'Select & Move Annotations (V)',
      ),
      _buildToolButton(
        icon: Icons.pan_tool_outlined,
        label: 'Hand',
        mode: EditorToolMode.hand,
        tooltip: 'Hand / Pan Canvas (H)',
      ),
      const SizedBox(width: 4),
      _buildDivider(borderColor),
      const SizedBox(width: 4),
      // 1. Text Markup Group
      _buildToolButton(
        icon: Icons.brush_outlined,
        label: 'Highlight',
        mode: EditorToolMode.highlight,
        tooltip: 'Highlight Text (E)',
      ),
      _buildToolButton(
        icon: Icons.format_underlined_rounded,
        label: 'Underline',
        mode: EditorToolMode.underline,
        tooltip: 'Underline Text (U)',
      ),
      _buildToolButton(
        icon: Icons.strikethrough_s_rounded,
        label: 'Strikeout',
        mode: EditorToolMode.strikethrough,
        tooltip: 'Strikethrough Text (S)',
      ),

      const SizedBox(width: 4),
      _buildDivider(borderColor),
      const SizedBox(width: 4),

      // 2. Notes Group
      _buildToolButton(
        icon: Icons.note_alt_outlined,
        label: 'Sticky Note',
        mode: EditorToolMode.stickyNote,
        tooltip: 'Insert Sticky Note (N)',
      ),

      const SizedBox(width: 4),
      _buildDivider(borderColor),
      const SizedBox(width: 4),

      // 3. Drawing & Shapes Group
      _buildToolButton(
        icon: Icons.edit_outlined,
        label: 'Pen',
        mode: EditorToolMode.pen,
        tooltip: 'Freehand Drawing Pen (P)',
      ),
      _buildToolButton(
        icon: Icons.auto_fix_normal_outlined,
        label: 'Eraser',
        mode: EditorToolMode.eraser,
        tooltip: 'Annotation Eraser',
      ),
      _buildToolButton(
        icon: Icons.remove_rounded,
        label: 'Line',
        mode: EditorToolMode.line,
        tooltip: 'Straight Line Tool',
      ),
      _buildToolButton(
        icon: Icons.arrow_outward_rounded,
        label: 'Arrow',
        mode: EditorToolMode.arrow,
        tooltip: 'Directional Arrow Tool',
      ),
      _buildToolButton(
        icon: Icons.crop_square_rounded,
        label: 'Rectangle',
        mode: EditorToolMode.rectangle,
        tooltip: 'Rectangle Tool (R)',
      ),
      _buildToolButton(
        icon: Icons.circle_outlined,
        label: 'Ellipse',
        mode: EditorToolMode.ellipse,
        tooltip: 'Ellipse / Oval Tool',
      ),

      const SizedBox(width: 4),
      _buildDivider(borderColor),
      const SizedBox(width: 4),

      // 4. Stamps Group
      PopupMenuButton<String>(
        tooltip: 'Insert Document Stamp',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ctrl.toolMode == EditorToolMode.stamp
                ? AppColors.brandPrimary.withAlpha(20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: ctrl.toolMode == EditorToolMode.stamp
                  ? AppColors.brandPrimary
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.approval_rounded, size: 16),
              const SizedBox(width: 4),
              Text(
                'Stamp: ${ctrl.activeStampText}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const Icon(Icons.arrow_drop_down, size: 14),
            ],
          ),
        ),
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'APPROVED', child: Text('APPROVED (Green)')),
          PopupMenuItem(value: 'DRAFT', child: Text('DRAFT (Amber)')),
          PopupMenuItem(value: 'CONFIDENTIAL', child: Text('CONFIDENTIAL (Red)')),
          PopupMenuItem(value: 'VOID', child: Text('VOID (Red)')),
          PopupMenuItem(value: 'COMPLETED', child: Text('COMPLETED (Blue)')),
        ],
        onSelected: (val) {
          ctrl.setActiveStampText(val);
          ctrl.setToolMode(EditorToolMode.stamp);
        },
      ),

      const SizedBox(width: 4),
      _buildActionIconButton(
        icon: Icons.draw_rounded,
        label: 'Sign',
        tooltip: 'Insert Electronic Signature',
        onPressed: () => _handleInsertSignature(context, tab, ctrl),
      ),

      const SizedBox(width: 4),
      _buildDivider(borderColor),
      const SizedBox(width: 4),

      // 5. Quick Color Palette Chips
      _buildColorChip(ctrl, const Color(0xFF0078D4)),
      _buildColorChip(ctrl, const Color(0xFF107C41)),
      _buildColorChip(ctrl, const Color(0xFFD83B01)),
      _buildColorChip(ctrl, const Color(0xFFFFB900)),
      _buildColorChip(ctrl, const Color(0xFF881798)),
      _buildColorChip(ctrl, const Color(0xFF000000)),
    ];
  }

  // --- STANDARD TOOLS (General View) ---
  List<Widget> _buildStandardTools(
    BuildContext context,
    DocumentTab tab,
    EditorTabController ctrl,
    Color borderColor,
  ) {
    return [
      _buildToolButton(
        icon: Icons.near_me_outlined,
        label: 'Select',
        mode: EditorToolMode.selectText,
        tooltip: 'Select & Move Objects (V)',
      ),
      _buildToolButton(
        icon: Icons.pan_tool_outlined,
        label: 'Hand',
        mode: EditorToolMode.hand,
        tooltip: 'Hand / Pan Canvas (H)',
      ),
      _buildToolButton(
        icon: Icons.text_fields_rounded,
        label: 'Text Box',
        mode: EditorToolMode.textBox,
        tooltip: 'Insert Text Box Annotation (T)',
      ),
      _buildToolButton(
        icon: Icons.edit_outlined,
        label: 'Pen',
        mode: EditorToolMode.pen,
        tooltip: 'Freehand Drawing Pen (P)',
      ),
      _buildToolButton(
        icon: Icons.brush_outlined,
        label: 'Highlight',
        mode: EditorToolMode.highlight,
        tooltip: 'Text Highlighter (E)',
      ),
      _buildToolButton(
        icon: Icons.format_underlined_rounded,
        label: 'Underline',
        mode: EditorToolMode.underline,
        tooltip: 'Text Underline (U)',
      ),
      _buildToolButton(
        icon: Icons.crop_square_rounded,
        label: 'Rectangle',
        mode: EditorToolMode.rectangle,
        tooltip: 'Rectangle Tool (R)',
      ),
      const SizedBox(width: 4),
      _buildActionIconButton(
        icon: Icons.draw_rounded,
        label: 'Sign',
        tooltip: 'Insert Electronic Signature',
        onPressed: () => _handleInsertSignature(context, tab, ctrl),
      ),
    ];
  }

  Future<void> _handleInsertSignature(BuildContext context, DocumentTab tab, EditorTabController ctrl) async {
    final bytes = await showDialog<Uint8List>(
      context: context,
      builder: (ctx) => const SignatureDialog(),
    );
    if (bytes != null) {
      ctrl.addSignature(bytes);
    }
  }

  Widget _buildColorChip(EditorTabController ctrl, Color color) {
    final isSelected = ctrl.activeColor == color;
    return GestureDetector(
      onTap: () => ctrl.setActiveColor(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.black26,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withAlpha(120), blurRadius: 4, spreadRadius: 1)]
              : null,
        ),
      ),
    );
  }

  Future<void> _handleAddImage(BuildContext context, DocumentTab tab, EditorTabController ctrl) async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select Image to Insert',
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );
      if (result.isNotEmpty && result.first.path != null) {
        final bytes = await File(result.first.path!).readAsBytes();
        final ann = EditorAnnotation.createImage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          pageNumber: tab.activePageIndex,
          normX: 0.3,
          normY: 0.3,
          normWidth: 0.35,
          normHeight: 0.25,
          imageBytes: bytes,
        );
        tab.addAnnotation(ann);
        ctrl.selectAnnotation(ann);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to insert image: $e')));
      }
    }
  }

  Future<void> _showWatermarkDialog(BuildContext context, DocumentTab tab) async {
    final textController = TextEditingController(text: 'CONFIDENTIAL');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Document Watermark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter watermark text to apply across all document pages:'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Watermark Text',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply Watermark')),
        ],
      ),
    );

    if (confirmed == true && textController.text.trim().isNotEmpty && context.mounted) {
      final text = textController.text.trim();
      for (var p = 1; p <= tab.pages.length; p++) {
        final watermark = EditorAnnotation.createStamp(
          id: '${DateTime.now().microsecondsSinceEpoch}_wm_$p',
          pageNumber: p,
          normX: 0.2,
          normY: 0.4,
          normWidth: 0.6,
          normHeight: 0.15,
          stampText: text,
          color: const Color(0x33D83B01),
        );
        tab.addAnnotation(watermark);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Watermark "$text" applied across all ${tab.pages.length} pages.')),
      );
    }
  }

  void _addPageNumbers(BuildContext context, DocumentTab tab) {
    final total = tab.pages.length;
    for (var p = 1; p <= total; p++) {
      final footer = EditorAnnotation.createTextBox(
        id: '${DateTime.now().microsecondsSinceEpoch}_pg_$p',
        pageNumber: p,
        normX: 0.4,
        normY: 0.94,
        normWidth: 0.2,
        normHeight: 0.035,
        text: 'Page $p of $total',
        fontSize: 10,
        color: const Color(0xFF666666),
        fillColor: Colors.transparent,
        alignment: TextAlign.center,
      );
      tab.addAnnotation(footer);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Page numbers added to all $total pages.')),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required EditorToolMode mode,
    required String tooltip,
  }) {
    final isSelected = controller?.toolMode == mode;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: () {
            if (controller?.toolMode == mode) {
              controller?.setToolMode(EditorToolMode.selectText);
            } else {
              controller?.setToolMode(mode);
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brandPrimary.withAlpha(28) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? AppColors.brandPrimary : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? AppColors.brandPrimary : null,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.brandPrimary : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isActive = false,
    Color? activeColor,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: IconButton(
        icon: Icon(
          icon,
          size: 17,
          color: isActive ? (activeColor ?? AppColors.brandPrimary) : null,
        ),
        splashRadius: 16,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: color,
    );
  }
}
