import 'package:flutter/material.dart';
import '../../models/annotation_model.dart';
import '../../models/document_tab.dart';
import '../../state/editor_tab_controller.dart';
import 'text_box_dialog.dart';

class PropertiesPanel extends StatefulWidget {
  final DocumentTab tab;
  final EditorTabController controller;

  const PropertiesPanel({
    required this.tab,
    required this.controller,
    super.key,
  });

  @override
  State<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends State<PropertiesPanel> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  String? _lastAnnotationId;

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _syncTextController(EditorAnnotation? selected) {
    if (selected == null) {
      _lastAnnotationId = null;
      return;
    }
    if (_lastAnnotationId != selected.id) {
      _lastAnnotationId = selected.id;
      _textController.text = selected.text;
    } else if (!_textFocusNode.hasFocus && _textController.text != selected.text) {
      _textController.text = selected.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.tab,
        widget.controller,
        widget.tab.undoRedo,
      ]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final bgColor = isDark ? const Color(0xFF252526) : const Color(0xFFF7F7F7);
        final borderColor = isDark ? const Color(0xFF383838) : const Color(0xFFE5E5E5);

        final selected = widget.controller.selectedAnnotation;
        final activePage = widget.tab.pages.isNotEmpty && widget.tab.activePageIndex <= widget.tab.pages.length
            ? widget.tab.pages[widget.tab.activePageIndex - 1]
            : null;

        _syncTextController(selected);

        return Container(
          width: 295,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(left: BorderSide(color: borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF0078D4)),
                    const SizedBox(width: 8),
                    const Text('Properties', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (selected != null)
                      TextButton(
                        onPressed: () => widget.controller.selectAnnotation(null),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Deselect', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ),

              // Scrollable Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  children: [
                    if (selected != null) ...[
                      // --- 1. SELECTED OBJECT INSPECTOR ---
                      _buildSectionHeader('SELECTED ${selected.type.name.toUpperCase()}'),
                      const SizedBox(height: 10),

                      // Editable Text Content if applicable
                      if (selected.type == AnnotationType.textBox ||
                          selected.type == AnnotationType.existingText ||
                          selected.type == AnnotationType.stickyNote ||
                          selected.text.isNotEmpty) ...[
                        const Text('Text Content:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _textController,
                          focusNode: _textFocusNode,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: isDark ? const Color(0xFF333333) : const Color(0xFFEAEAEA),
                            contentPadding: const EdgeInsets.all(8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            hintText: 'Type text here...',
                          ),
                          onChanged: (val) {
                            widget.tab.updateAnnotation(selected.copyWith(text: val), recordUndo: false);
                          },
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Edit in Dialog...', style: TextStyle(fontSize: 11)),
                          onPressed: () async {
                            final res = await TextBoxDialog.show(
                              context,
                              initialText: selected.text,
                              initialFontSize: selected.fontSize,
                              initialTextColor: selected.color,
                              initialFillColor: selected.fillColor,
                            );
                            if (res != null) {
                              widget.tab.updateAnnotation(selected.copyWith(
                                text: res.text,
                                fontSize: res.fontSize,
                                color: res.textColor,
                                fillColor: res.fillColor,
                              ));
                              widget.controller.setActiveFontSize(res.fontSize);
                              widget.controller.setActiveColor(res.textColor);
                              widget.controller.setActiveFillColor(res.fillColor);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Typography & Formatting for Text Boxes
                      if (selected.type == AnnotationType.textBox ||
                          selected.type == AnnotationType.existingText) ...[
                        _buildSectionHeader('TYPOGRAPHY & FORMATTING'),
                        const SizedBox(height: 8),

                        // Font Family Dropdown
                        Row(
                          children: [
                            const Text('Font:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Container(
                              height: 28,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF333333) : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: borderColor),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: ['Helvetica', 'Times', 'Courier'].contains(selected.fontFamily)
                                      ? selected.fontFamily
                                      : 'Helvetica',
                                  dropdownColor: isDark ? const Color(0xFF333333) : Colors.white,
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black87),
                                  items: const [
                                    DropdownMenuItem(value: 'Helvetica', child: Text('Helvetica')),
                                    DropdownMenuItem(value: 'Times', child: Text('Times Roman')),
                                    DropdownMenuItem(value: 'Courier', child: Text('Courier')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      widget.controller.setActiveFontFamily(val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Font Size Stepper
                        Row(
                          children: [
                            const Text('Size:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.remove, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              onPressed: () {
                                final newSize = (selected.fontSize - 1).clamp(8.0, 72.0);
                                widget.controller.setActiveFontSize(newSize);
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF333333) : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: borderColor),
                              ),
                              child: Text('${selected.fontSize.toInt()} pt',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              onPressed: () {
                                final newSize = (selected.fontSize + 1).clamp(8.0, 72.0);
                                widget.controller.setActiveFontSize(newSize);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Bold, Italic & Alignment Toggles
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.format_bold_rounded,
                                  size: 16,
                                  color: selected.isBold
                                      ? const Color(0xFF0078D4)
                                      : (isDark ? Colors.white60 : Colors.black54)),
                              style: IconButton.styleFrom(
                                backgroundColor: selected.isBold ? const Color(0xFF0078D4).withAlpha(30) : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              onPressed: () {
                                widget.controller.toggleBold();
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.format_italic_rounded,
                                  size: 16,
                                  color: selected.isItalic
                                      ? const Color(0xFF0078D4)
                                      : (isDark ? Colors.white60 : Colors.black54)),
                              style: IconButton.styleFrom(
                                backgroundColor: selected.isItalic ? const Color(0xFF0078D4).withAlpha(30) : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              onPressed: () {
                                widget.controller.toggleItalic();
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.format_align_left_rounded,
                                  size: 16,
                                  color: selected.alignment == TextAlign.left
                                      ? const Color(0xFF0078D4)
                                      : (isDark ? Colors.white60 : Colors.black54)),
                              style: IconButton.styleFrom(
                                backgroundColor: selected.alignment == TextAlign.left
                                    ? const Color(0xFF0078D4).withAlpha(30)
                                    : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              onPressed: () {
                                widget.controller.setActiveAlignment(TextAlign.left);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.format_align_center_rounded,
                                  size: 16,
                                  color: selected.alignment == TextAlign.center
                                      ? const Color(0xFF0078D4)
                                      : (isDark ? Colors.white60 : Colors.black54)),
                              style: IconButton.styleFrom(
                                backgroundColor: selected.alignment == TextAlign.center
                                    ? const Color(0xFF0078D4).withAlpha(30)
                                    : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              onPressed: () {
                                widget.controller.setActiveAlignment(TextAlign.center);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.format_align_right_rounded,
                                  size: 16,
                                  color: selected.alignment == TextAlign.right
                                      ? const Color(0xFF0078D4)
                                      : (isDark ? Colors.white60 : Colors.black54)),
                              style: IconButton.styleFrom(
                                backgroundColor: selected.alignment == TextAlign.right
                                    ? const Color(0xFF0078D4).withAlpha(30)
                                    : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              onPressed: () {
                                widget.controller.setActiveAlignment(TextAlign.right);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Background Fill Color
                        _buildFillColorPicker(selected: selected, isDark: isDark),
                        const SizedBox(height: 12),
                      ],

                      // Text / Object Color
                      _buildColorPicker(context, selected: selected),
                      const SizedBox(height: 12),

                      // Stroke width / Font size
                      if (selected.type == AnnotationType.drawing ||
                          selected.type == AnnotationType.line ||
                          selected.type == AnnotationType.arrow ||
                          selected.type == AnnotationType.rectangle ||
                          selected.type == AnnotationType.ellipse) ...[
                        _buildStrokeWidthSlider(selected: selected),
                        const SizedBox(height: 12),
                      ],

                      // Position & Dimensions
                      _buildSectionHeader('LAYOUT POSITION'),
                      const SizedBox(height: 6),
                      _buildInfoRow('Page', 'Page ${selected.pageNumber}'),
                      _buildInfoRow('X Position', '${(selected.normalizedX * 100).toStringAsFixed(1)}%'),
                      _buildInfoRow('Y Position', '${(selected.normalizedY * 100).toStringAsFixed(1)}%'),
                      _buildInfoRow('Width', '${(selected.normalizedWidth * 100).toStringAsFixed(1)}%'),
                      _buildInfoRow('Height', '${(selected.normalizedHeight * 100).toStringAsFixed(1)}%'),
                      const SizedBox(height: 12),

                      // Object Layer Actions
                      _buildSectionHeader('LAYER ORDER'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              icon: const Icon(Icons.flip_to_front_rounded, size: 14),
                              label: const Text('Forward', style: TextStyle(fontSize: 11)),
                              onPressed: () => widget.tab.bringAnnotationForward(selected),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              icon: const Icon(Icons.flip_to_back_rounded, size: 14),
                              label: const Text('Backward', style: TextStyle(fontSize: 11)),
                              onPressed: () => widget.tab.sendAnnotationBackward(selected),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Delete Object Button
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          minimumSize: const Size.fromHeight(32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 15),
                        label: const Text('Delete Object', style: TextStyle(fontSize: 11)),
                        onPressed: () => widget.controller.deleteSelectedAnnotation(),
                      ),
                    ] else ...[
                      // --- 2. ACTIVE TOOL SETTINGS ---
                      _buildSectionHeader('ACTIVE TOOL'),
                      const SizedBox(height: 8),
                      Text(
                        _toolName(widget.controller.toolMode),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      _buildColorPicker(context),
                      const SizedBox(height: 12),
                      if (widget.controller.toolMode == EditorToolMode.pen ||
                          widget.controller.toolMode == EditorToolMode.line ||
                          widget.controller.toolMode == EditorToolMode.arrow ||
                          widget.controller.toolMode == EditorToolMode.rectangle ||
                          widget.controller.toolMode == EditorToolMode.ellipse ||
                          widget.controller.toolMode == EditorToolMode.underline) ...[
                        _buildStrokeWidthSlider(),
                      ],
                    ],

                    const Divider(height: 28),

                    // --- 3. ACTIVE PAGE SPECIFICATIONS ---
                    _buildSectionHeader('PAGE SPECIFICATIONS'),
                    const SizedBox(height: 8),
                    if (activePage != null) ...[
                      _buildInfoRow('Page', '${widget.tab.activePageIndex} of ${widget.tab.pages.length}'),
                      _buildInfoRow('Format', activePage.standardSizeName),
                      _buildInfoRow('Dimensions (pt)',
                          '${activePage.sizeInPoints.width.toStringAsFixed(0)} × ${activePage.sizeInPoints.height.toStringAsFixed(0)} pt'),
                      _buildInfoRow('Dimensions (in)',
                          '${activePage.widthInInches.toStringAsFixed(1)} × ${activePage.heightInInches.toStringAsFixed(1)} in'),
                      _buildInfoRow('Orientation', activePage.orientation),
                      _buildInfoRow('Rotation', '${activePage.rotationAngle}°'),
                      const SizedBox(height: 10),

                      // Rotate Page Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              icon: const Icon(Icons.rotate_left_rounded, size: 14),
                              label: const Text('Rotate 90° CCW', style: TextStyle(fontSize: 10)),
                              onPressed: () => widget.tab.rotatePage(widget.tab.activePageIndex - 1, 270),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              icon: const Icon(Icons.rotate_right_rounded, size: 14),
                              label: const Text('Rotate 90° CW', style: TextStyle(fontSize: 10)),
                              onPressed: () => widget.tab.rotatePage(widget.tab.activePageIndex - 1, 90),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Delete Page Button (if > 1 page)
                      if (widget.tab.pages.length > 1)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 14),
                          label: const Text('Delete This Page', style: TextStyle(fontSize: 11)),
                          onPressed: () => widget.tab.deletePage(widget.tab.activePageIndex - 1),
                        ),
                    ],

                    const Divider(height: 28),

                    // --- 4. DOCUMENT METADATA ---
                    _buildSectionHeader('DOCUMENT INFORMATION'),
                    const SizedBox(height: 8),
                    _buildInfoRow('File Name', widget.tab.fileName),
                    _buildInfoRow('Page Count', '${widget.tab.pages.length} Pages'),
                    _buildInfoRow('Annotations', '${widget.tab.annotations.length} Objects'),
                    _buildInfoRow('Status', widget.tab.isModified ? 'Unsaved Changes' : 'Saved'),
                    _buildInfoRow('File Size', _formatFileSize(widget.tab.pdfBytes.length)),
                    if (widget.tab.metadata.title.isNotEmpty)
                      _buildInfoRow('Title', widget.tab.metadata.title),
                    if (widget.tab.metadata.author.isNotEmpty)
                      _buildInfoRow('Author', widget.tab.metadata.author),
                    if (widget.tab.metadata.producer.isNotEmpty)
                      _buildInfoRow('Producer', widget.tab.metadata.producer),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0078D4),
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context, {EditorAnnotation? selected}) {
    final colors = [
      const Color(0xFF0078D4), // Blue
      const Color(0xFF107C41), // Green
      const Color(0xFFD83B01), // Red
      const Color(0xFFFFB900), // Yellow
      const Color(0xFF881798), // Purple
      Colors.black,
      Colors.white,
    ];

    final currentColor = selected?.color ?? widget.controller.activeColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: colors.map((c) {
            final isChosen = currentColor == c;
            return GestureDetector(
              onTap: () {
                widget.controller.setActiveColor(c);
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isChosen ? const Color(0xFF0078D4) : Colors.grey,
                    width: isChosen ? 2.5 : 1.0,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStrokeWidthSlider({EditorAnnotation? selected}) {
    final currentWidth = selected?.strokeWidth ?? widget.controller.activeStrokeWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Line Width:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            Text('${currentWidth.toStringAsFixed(1)} pt',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            trackHeight: 2,
            activeTrackColor: const Color(0xFF0078D4),
            thumbColor: const Color(0xFF0078D4),
          ),
          child: Slider(
            value: currentWidth.clamp(1.0, 16.0),
            min: 1.0,
            max: 16.0,
            divisions: 15,
            onChanged: (val) {
              widget.controller.setActiveStrokeWidth(val);
            },
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _toolName(EditorToolMode mode) {
    switch (mode) {
      case EditorToolMode.hand:
        return 'Hand (Pan Canvas)';
      case EditorToolMode.selectText:
        return 'Select Text';
      case EditorToolMode.textBox:
        return 'Insert Text Box';
      case EditorToolMode.editText:
        return 'Edit Document Text';
      case EditorToolMode.highlight:
        return 'Highlight Marker';
      case EditorToolMode.underline:
        return 'Text Underline';
      case EditorToolMode.strikethrough:
        return 'Strikethrough';
      case EditorToolMode.pen:
        return 'Freehand Pen';
      case EditorToolMode.eraser:
        return 'Annotation Eraser';
      case EditorToolMode.line:
        return 'Straight Line';
      case EditorToolMode.arrow:
        return 'Directional Arrow';
      case EditorToolMode.rectangle:
        return 'Rectangle Shape';
      case EditorToolMode.ellipse:
        return 'Ellipse / Oval';
      case EditorToolMode.stickyNote:
        return 'Sticky Note';
      case EditorToolMode.stamp:
        return 'Document Stamp';
      case EditorToolMode.image:
        return 'Image Object';
    }
  }

  Widget _buildFillColorPicker({required EditorAnnotation selected, required bool isDark}) {
    final fillOptions = [
      null, // Transparent
      Colors.white,
      const Color(0xFFFFF7A6), // Light yellow
      const Color(0xFFE0F2FE), // Light blue
      const Color(0xFFDCFCE7), // Light green
      const Color(0xFFF1F5F9), // Light gray
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Background Fill:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: fillOptions.map((c) {
            final isChosen = (c == null && (selected.fillColor == null || selected.fillColor == Colors.transparent)) ||
                (c != null && selected.fillColor == c);
            return GestureDetector(
              onTap: () {
                widget.controller.setActiveFillColor(c);
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: c ?? Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isChosen ? const Color(0xFF0078D4) : Colors.grey,
                    width: isChosen ? 2.5 : 1.0,
                  ),
                ),
                child: c == null
                    ? const Icon(Icons.block, size: 14, color: Colors.grey)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
