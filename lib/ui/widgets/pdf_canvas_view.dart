import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../models/annotation_model.dart';
import '../../models/document_tab.dart';
import '../../state/editor_tab_controller.dart';
import 'search_bar_overlay.dart';
import 'text_box_dialog.dart';

class PdfCanvasView extends StatefulWidget {
  final DocumentTab tab;
  final EditorTabController controller;

  const PdfCanvasView({
    required this.tab,
    required this.controller,
    super.key,
  });

  @override
  State<PdfCanvasView> createState() => _PdfCanvasViewState();
}

class _PdfCanvasViewState extends State<PdfCanvasView> {
  // Temporary state for in-progress drawing / dragging on a page
  int? _activeDrawingPage;
  List<Offset> _currentDrawingNormalizedPoints = [];
  Offset? _dragStartNormalized;
  Offset? _dragCurrentNormalized;
  Offset? _pointerDownRawPos;

  // Inline text editing state
  String? _editingAnnotationId;
  final TextEditingController _inlineTextController = TextEditingController();
  final FocusNode _inlineFocusNode = FocusNode();

  // Mouse wheel scroll navigation state
  Duration? _lastProcessedPointerTimestamp;
  double _wheelScrollAccumulator = 0.0;
  DateTime _lastPageTurnTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastScrollEventTime = DateTime.fromMillisecondsSinceEpoch(0);

  void _handlePointerScroll(PointerScrollEvent event) {
    // Deduplicate if both inner overlay and outer canvas receive the same signal
    if (_lastProcessedPointerTimestamp != null && _lastProcessedPointerTimestamp == event.timeStamp) {
      return;
    }
    _lastProcessedPointerTimestamp = event.timeStamp;

    // Handle Ctrl + Wheel for zoom
    if (HardwareKeyboard.instance.isControlPressed) {
      widget.controller.pdfViewerController.handlePointerSignalEvent(event);
      return;
    }

    final totalPages = widget.tab.pages.length;
    // If only 1 page, fallback to pdfrx panning
    if (totalPages <= 1) {
      widget.controller.pdfViewerController.handlePointerSignalEvent(event);
      return;
    }

    final now = DateTime.now();
    // Reset accumulator if user stopped scrolling for > 300ms
    if (now.difference(_lastScrollEventTime).inMilliseconds > 300) {
      _wheelScrollAccumulator = 0.0;
    }
    _lastScrollEventTime = now;
    _wheelScrollAccumulator += event.scrollDelta.dy;

    // Minimum delay between page flips (200ms) to ensure smooth, natural page turns
    if (now.difference(_lastPageTurnTime).inMilliseconds < 200) {
      return;
    }

    const double threshold = 35.0; // Responsive single notch threshold
    if (_wheelScrollAccumulator >= threshold) {
      _wheelScrollAccumulator = 0.0;
      final currentPage = widget.tab.activePageIndex;
      if (currentPage < totalPages) {
        _commitInlineEditing();
        _lastPageTurnTime = now;
        widget.controller.goToPage(currentPage + 1);
      }
    } else if (_wheelScrollAccumulator <= -threshold) {
      _wheelScrollAccumulator = 0.0;
      final currentPage = widget.tab.activePageIndex;
      if (currentPage > 1) {
        _commitInlineEditing();
        _lastPageTurnTime = now;
        widget.controller.goToPage(currentPage - 1);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    widget.tab.addListener(_onStateChanged);
    widget.controller.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(PdfCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) {
      oldWidget.tab.removeListener(_onStateChanged);
      widget.tab.addListener(_onStateChanged);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onStateChanged);
      widget.controller.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.tab.removeListener(_onStateChanged);
    widget.controller.removeListener(_onStateChanged);
    _inlineTextController.dispose();
    _inlineFocusNode.dispose();
    super.dispose();
  }

  void _commitInlineEditing() {
    if (_editingAnnotationId != null) {
      final annId = _editingAnnotationId!;
      final newText = _inlineTextController.text;
      final annIndex = widget.tab.annotations.indexWhere((a) => a.id == annId);
      if (annIndex != -1) {
        final ann = widget.tab.annotations[annIndex];
        if (ann.text != newText) {
          widget.tab.updateAnnotation(ann.copyWith(text: newText), recordUndo: true);
        }
      }
      setState(() => _editingAnnotationId = null);
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark ? const Color(0xFF181818) : const Color(0xFFDCDCDC);

    return Stack(
      children: [
        // Center PDF Viewer
        Container(
          color: canvasBg,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                _handlePointerScroll(pointerSignal);
              }
            },
            child: PdfViewer.data(
              widget.tab.pdfBytes,
              sourceName: widget.tab.fileName,
              key: ValueKey('${widget.tab.id}_${widget.tab.pdfBytes.length}'),
              controller: widget.controller.pdfViewerController,
              passwordProvider: widget.tab.password != null ? () => widget.tab.password : null,
              params: PdfViewerParams(
                backgroundColor: canvasBg,
                margin: 16.0,
                panEnabled: true,
                scaleEnabled: true,
                scrollByMouseWheel: null,
                enableKeyboardNavigation: true,
                scrollByArrowKey: 35.0,
                viewerOverlayBuilder: (context, size, handleLinkTap) => [
                  PdfViewerScrollThumb(
                    controller: widget.controller.pdfViewerController,
                    orientation: ScrollbarOrientation.right,
                    margin: 2,
                  ),
                  PdfViewerScrollThumb(
                    controller: widget.controller.pdfViewerController,
                    orientation: ScrollbarOrientation.bottom,
                    margin: 2,
                  ),
                ],
                onViewerReady: (document, controller) {
                  widget.controller.initSearcherIfReady();
                },
                onPageChanged: (pageNumber) {
                  if (pageNumber != null) {
                    widget.tab.setActivePage(pageNumber);
                  }
                },
                pagePaintCallbacks: [
                  (canvas, rect, page) {
                    widget.controller.textSearcher?.pageTextMatchPaintCallback(canvas, rect, page);
                  },
                ],
                pageOverlaysBuilder: (context, pageRect, page) {
                  return [
                    Positioned.fill(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            _handlePointerScroll(pointerSignal);
                          }
                        },
                        child: _buildPageAnnotationOverlay(page.pageNumber, pageRect.size),
                      ),
                    ),
                  ];
                },
              ),
            ),
          ),
        ),

        // Search Bar Overlay (top-right)
        if (widget.controller.isSearchVisible)
          Positioned(
            top: 16,
            right: 24,
            child: SearchBarOverlay(controller: widget.controller),
          ),
      ],
    );
  }

  Widget _buildPageAnnotationOverlay(int pageNumber, Size pageSize) {
    final pageAnnotations = widget.tab.annotations.where((a) => a.pageNumber == pageNumber).toList();

    final isShapeOrPenTool = widget.controller.toolMode == EditorToolMode.pen ||
        widget.controller.toolMode == EditorToolMode.highlight ||
        widget.controller.toolMode == EditorToolMode.underline ||
        widget.controller.toolMode == EditorToolMode.strikethrough ||
        widget.controller.toolMode == EditorToolMode.line ||
        widget.controller.toolMode == EditorToolMode.arrow ||
        widget.controller.toolMode == EditorToolMode.rectangle ||
        widget.controller.toolMode == EditorToolMode.ellipse ||
        widget.controller.toolMode == EditorToolMode.eraser;

    final isTapToPlaceTool = widget.controller.toolMode == EditorToolMode.textBox ||
        widget.controller.toolMode == EditorToolMode.editText ||
        widget.controller.toolMode == EditorToolMode.stickyNote ||
        widget.controller.toolMode == EditorToolMode.stamp;

    final interactiveTypes = {
      AnnotationType.textBox,
      AnnotationType.existingText,
      AnnotationType.stickyNote,
      AnnotationType.stamp,
      AnnotationType.image,
    };

    return Stack(
      children: [
        // 1. Render painted annotations (drawings, highlights, lines, shapes)
        CustomPaint(
          size: pageSize,
          painter: _AnnotationPainter(
            annotations: pageAnnotations,
            selectedAnnotation: widget.controller.selectedAnnotation,
            pageSize: pageSize,
          ),
        ),

        // 2. Tap-To-Place Tool Layer (TextBox, StickyNote, Stamp) - Placed behind interactive annotations
        if (isTapToPlaceTool)
          Positioned.fill(
            child: MouseRegion(
              cursor: (widget.controller.toolMode == EditorToolMode.textBox || widget.controller.toolMode == EditorToolMode.editText)
                  ? SystemMouseCursors.text
                  : SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) => _handlePageTapUp(pageNumber, details.localPosition, pageSize),
              ),
            ),
          )
        else
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _commitInlineEditing();
                if (widget.controller.selectedAnnotation != null) {
                  widget.controller.selectAnnotation(null);
                }
              },
            ),
          ),

        // 3. Render all interactive movable/resizable annotations (text, sticky notes, stamps, images, signatures)
        ...pageAnnotations
            .where((a) => interactiveTypes.contains(a.type))
            .map((ann) => _buildInteractiveAnnotation(ann, pageSize)),

        // 4. Render in-progress drawing preview (if currently drawing on this page)
        if (_activeDrawingPage == pageNumber)
          CustomPaint(
            size: pageSize,
            painter: _ActiveDrawingPainter(
              toolMode: widget.controller.toolMode,
              points: _currentDrawingNormalizedPoints,
              start: _dragStartNormalized,
              current: _dragCurrentNormalized,
              color: widget.controller.activeColor,
              strokeWidth: widget.controller.activeStrokeWidth,
              pageSize: pageSize,
            ),
          ),

        // 5. Drawing / Pen Tool Layer - Only mounted when actively drawing shapes or pen strokes
        if (isShapeOrPenTool)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) {
                if (e.buttons == kPrimaryMouseButton) {
                  _pointerDownRawPos = e.localPosition;
                  _handlePointerDown(pageNumber, e.localPosition, pageSize);
                }
              },
              onPointerMove: (e) {
                if (_activeDrawingPage == pageNumber) {
                  _handlePointerMove(pageNumber, e.localPosition, pageSize);
                }
              },
              onPointerUp: (e) {
                if (_activeDrawingPage == pageNumber) {
                  _handlePointerUp(pageNumber, e.localPosition, pageSize);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildInteractiveAnnotation(EditorAnnotation ann, Size pageSize) {
    final isSelected = widget.controller.selectedAnnotation?.id == ann.id;
    final isEditing = _editingAnnotationId == ann.id;
    final left = ann.normalizedX * pageSize.width;
    final top = ann.normalizedY * pageSize.height;
    final width = max(ann.normalizedWidth * pageSize.width, 40.0);
    final height = max(ann.normalizedHeight * pageSize.height, 24.0);
    final scale = (pageSize.width / 612.0).clamp(0.6, 2.5);
    final isExisting = ann.type == AnnotationType.existingText;

    if (isEditing) {
      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Unobstructed Native TextField Input Container
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: isExisting ? Colors.white : (ann.fillColor ?? Colors.transparent),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFF0078D4), width: 1.5),
                ),
                alignment: ann.alignment == TextAlign.center
                    ? Alignment.center
                    : (ann.alignment == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    controller: _inlineTextController,
                    focusNode: _inlineFocusNode,
                    autofocus: true,
                    maxLines: null,
                    expands: true,
                    style: TextStyle(
                      fontSize: ann.fontSize * scale,
                      color: ann.color,
                      fontFamily: ann.fontFamily,
                      fontWeight: ann.isBold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: ann.isItalic ? FontStyle.italic : FontStyle.normal,
                    ),
                    textAlign: ann.alignment,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Type text here...',
                    ),
                    onSubmitted: (_) => _commitInlineEditing(),
                  ),
                ),
              ),
            ),

            // 2. Green Checkmark Done Button at Top-Right
            Positioned(
              right: -9,
              top: -9,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _commitInlineEditing,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                    ),
                    child: const Icon(Icons.check, size: 13, color: Colors.white),
                  ),
                ),
              ),
            ),

            // 3. Resize Handle at Bottom-Right
            Positioned(
              right: -6,
              bottom: -6,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final newWidth = ((width + details.delta.dx) / pageSize.width).clamp(0.04, 1.0 - ann.normalizedX);
                  final newHeight = ((height + details.delta.dy) / pageSize.height).clamp(0.02, 1.0 - ann.normalizedY);
                  widget.tab.updateAnnotation(ann.copyWith(
                    normalizedWidth: newWidth,
                    normalizedHeight: newHeight,
                  ), recordUndo: false);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeDownRight,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0078D4), width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Body GestureDetector (Select, Move, Double-Click to Edit)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _commitInlineEditing();
                final isAlreadySelected = widget.controller.selectedAnnotation?.id == ann.id;
                final isTextType = ann.type == AnnotationType.textBox || ann.type == AnnotationType.existingText;
                final isEditMode = widget.controller.toolMode == EditorToolMode.editText;

                if ((isAlreadySelected || isEditMode) && isTextType) {
                  setState(() {
                    _editingAnnotationId = ann.id;
                    _inlineTextController.text = ann.text;
                  });
                  widget.controller.selectAnnotation(ann);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _inlineFocusNode.requestFocus();
                    _inlineTextController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _inlineTextController.text.length,
                    );
                  });
                } else {
                  widget.controller.selectAnnotation(ann);
                }
              },
              onPanUpdate: isSelected
                  ? (details) {
                      final newNormX = ((left + details.delta.dx) / pageSize.width).clamp(0.0, 1.0 - ann.normalizedWidth);
                      final newNormY = ((top + details.delta.dy) / pageSize.height).clamp(0.0, 1.0 - ann.normalizedHeight);
                      widget.tab.updateAnnotation(ann.copyWith(
                        normalizedX: newNormX,
                        normalizedY: newNormY,
                      ), recordUndo: false);
                    }
                  : null,
              onPanEnd: isSelected ? (_) => widget.tab.markModified() : null,
              onDoubleTap: () {
                if (ann.type == AnnotationType.textBox || ann.type == AnnotationType.existingText) {
                  setState(() {
                    _editingAnnotationId = ann.id;
                    _inlineTextController.text = ann.text;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _inlineFocusNode.requestFocus();
                    _inlineTextController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _inlineTextController.text.length,
                    );
                  });
                } else {
                  _handleAnnotationEdit(ann);
                }
              },
              child: MouseRegion(
                cursor: isSelected ? SystemMouseCursors.move : SystemMouseCursors.click,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0078D4) : Colors.transparent,
                      width: isSelected ? 1.5 : 0.0,
                    ),
                  ),
                  child: _buildAnnotationContent(ann, pageSize),
                ),
              ),
            ),
          ),

          // Edit pencil icon at Top-Left (Only when selected)
          if (isSelected && (ann.type == AnnotationType.textBox || ann.type == AnnotationType.existingText))
            Positioned(
              left: -7,
              top: -7,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _editingAnnotationId = ann.id;
                    _inlineTextController.text = ann.text;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _inlineFocusNode.requestFocus();
                    _inlineTextController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _inlineTextController.text.length,
                    );
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0078D4),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                    ),
                    child: const Icon(Icons.edit, size: 11, color: Colors.white),
                  ),
                ),
              ),
            ),

          // Resize Handle at Bottom-Right (Only when selected)
          if (isSelected)
            Positioned(
              right: -6,
              bottom: -6,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final newWidth = ((width + details.delta.dx) / pageSize.width).clamp(0.03, 1.0 - ann.normalizedX);
                  final newHeight = ((height + details.delta.dy) / pageSize.height).clamp(0.02, 1.0 - ann.normalizedY);
                  widget.tab.updateAnnotation(ann.copyWith(
                    normalizedWidth: newWidth,
                    normalizedHeight: newHeight,
                  ), recordUndo: false);
                },
                onPanEnd: (_) => widget.tab.markModified(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeDownRight,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0078D4), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Delete Handle at Top-Right (Only when selected)
          if (isSelected)
            Positioned(
              right: -7,
              top: -7,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.controller.deleteSelectedAnnotation(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 10, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnnotationContent(EditorAnnotation ann, Size pageSize) {
    switch (ann.type) {
      case AnnotationType.textBox:
      case AnnotationType.existingText:
        final scale = (pageSize.width / 612.0).clamp(0.6, 2.5);
        final isEditing = _editingAnnotationId == ann.id;
        final isExisting = ann.type == AnnotationType.existingText;

        if (isEditing) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isExisting ? Colors.white : (ann.fillColor ?? Colors.transparent),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFF0078D4), width: 1.5),
            ),
            alignment: ann.alignment == TextAlign.center
                ? Alignment.center
                : (ann.alignment == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
            child: Material(
              color: Colors.transparent,
              child: TextField(
                controller: _inlineTextController,
                focusNode: _inlineFocusNode,
                autofocus: true,
                maxLines: null,
                expands: true,
                style: TextStyle(
                  fontSize: ann.fontSize * scale,
                  color: ann.color,
                  fontFamily: ann.fontFamily,
                  fontWeight: ann.isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: ann.isItalic ? FontStyle.italic : FontStyle.normal,
                ),
                textAlign: ann.alignment,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: 'Type text...',
                ),
                onChanged: (val) {
                  widget.tab.updateAnnotation(ann.copyWith(text: val));
                },
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isExisting ? Colors.white : (ann.fillColor ?? Colors.transparent),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isExisting && ann.fillColor == null ? Colors.transparent : Colors.transparent,
              width: 0.0,
            ),
          ),
          alignment: ann.alignment == TextAlign.center
              ? Alignment.center
              : (ann.alignment == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
          child: Text(
            ann.text.isNotEmpty ? ann.text : '(Click or double-click to type)',
            textAlign: ann.alignment,
            style: TextStyle(
              fontSize: ann.fontSize * scale,
              color: ann.text.isNotEmpty ? ann.color : Colors.grey,
              fontFamily: ann.fontFamily,
              fontWeight: ann.isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: ann.isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        );

      case AnnotationType.stickyNote:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7A6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD4C868)),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 12, color: Color(0xFF8A7A00)),
                  const SizedBox(width: 4),
                  Text(
                    ann.author.isNotEmpty ? ann.author : 'Note',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8A7A00)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  ann.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ),
            ],
          ),
        );

      case AnnotationType.stamp:
        final stampText = ann.stampText.isNotEmpty ? ann.stampText : (ann.text.isNotEmpty ? ann.text : 'APPROVED');
        return Container(
          decoration: BoxDecoration(
            color: ann.color.withAlpha(20),
            border: Border.all(color: ann.color, width: 2.5),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            stampText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: ann.color,
            ),
          ),
        );

      case AnnotationType.image:
        if (ann.imageBytes != null && ann.imageBytes!.isNotEmpty) {
          return Image.memory(
            ann.imageBytes!,
            fit: BoxFit.contain,
          );
        }
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleAnnotationEdit(EditorAnnotation ann) async {
    if (ann.type == AnnotationType.textBox || ann.type == AnnotationType.existingText) {
      final result = await TextBoxDialog.show(
        context,
        initialText: ann.text,
        initialFontSize: ann.fontSize,
        initialTextColor: ann.color,
        initialFillColor: ann.fillColor,
      );
      if (result != null) {
        widget.tab.updateAnnotation(ann.copyWith(
          text: result.text,
          fontSize: result.fontSize,
          color: result.textColor,
          fillColor: result.fillColor,
        ));
      }
    } else if (ann.type == AnnotationType.stickyNote) {
      final result = await TextBoxDialog.show(
        context,
        initialText: ann.text,
        initialFontSize: 12,
        initialTextColor: Colors.black87,
        initialFillColor: const Color(0xFFFFF275),
      );
      if (result != null) {
        widget.tab.updateAnnotation(ann.copyWith(text: result.text));
      }
    }
  }

  Future<void> _handlePageTapUp(int pageNumber, Offset localPos, Size pageSize) async {
    final mode = widget.controller.toolMode;
    final annId = DateTime.now().microsecondsSinceEpoch.toString();
    final normX = (localPos.dx / pageSize.width).clamp(0.0, 0.85);
    final normY = (localPos.dy / pageSize.height).clamp(0.0, 0.92);

    if (mode == EditorToolMode.textBox) {
      final newAnnotation = EditorAnnotation(
        id: annId,
        pageNumber: pageNumber,
        type: AnnotationType.textBox,
        normalizedX: normX,
        normalizedY: normY,
        normalizedWidth: 0.28,
        normalizedHeight: 0.045,
        text: '',
        fontSize: widget.controller.activeFontSize,
        color: widget.controller.activeColor,
        fillColor: widget.controller.activeFillColor ?? Colors.transparent,
        fontFamily: widget.controller.activeFontFamily,
        isBold: widget.controller.activeIsBold,
        isItalic: widget.controller.activeIsItalic,
        alignment: widget.controller.activeAlignment,
      );
      widget.tab.addAnnotation(newAnnotation);
      widget.controller.selectAnnotation(newAnnotation);
      setState(() {
        _editingAnnotationId = newAnnotation.id;
        _inlineTextController.text = '';
      });
      widget.controller.setToolMode(EditorToolMode.selectText);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inlineFocusNode.requestFocus();
      });
      return;
    } else if (mode == EditorToolMode.editText) {
      String detectedText = '';
      double detectedNormX = normX;
      double detectedNormY = normY;
      double detectedNormW = 0.28;
      double detectedNormH = 0.045;
      double detectedFontSize = widget.controller.activeFontSize;

      try {
        final pageText = await widget.controller.pdfViewerController.useDocument((doc) async {
          if (pageNumber - 1 < doc.pages.length) {
            final page = doc.pages[pageNumber - 1];
            final text = await page.loadStructuredText();
            return (text: text, width: page.width, height: page.height);
          }
          return null;
        });

        if (pageText != null) {
          final textObj = pageText.text;
          final pageWidth = pageText.width;
          final pageHeight = pageText.height;
          final double pdfX = (localPos.dx / pageSize.width) * pageWidth;
          final double pdfY = ((pageSize.height - localPos.dy) / pageSize.height) * pageHeight;

          PdfPageTextFragment? bestFrag;
          double minDistance = double.infinity;
          for (final frag in textObj.fragments) {
            if (frag.bounds.containsXy(pdfX, pdfY, margin: 4.0)) {
              bestFrag = frag;
              break;
            }
            final dist = frag.bounds.distanceSquaredTo(PdfPoint(pdfX, pdfY));
            if (dist < 400.0 && dist < minDistance) {
              minDistance = dist;
              bestFrag = frag;
            }
          }

          if (bestFrag != null) {
            final raw = textObj.fullText.substring(bestFrag.index, bestFrag.end).trim();
            if (raw.isNotEmpty) {
              detectedText = raw;
              detectedNormX = (bestFrag.bounds.left / pageWidth).clamp(0.0, 0.90);
              detectedNormY = ((pageHeight - bestFrag.bounds.top) / pageHeight).clamp(0.0, 0.95);
              detectedNormW = (bestFrag.bounds.width / pageWidth).clamp(0.06, 1.0 - detectedNormX);
              detectedNormH = (bestFrag.bounds.height / pageHeight).clamp(0.02, 1.0 - detectedNormY);
              detectedFontSize = bestFrag.bounds.height.clamp(8.0, 48.0);
            }
          }
        }
      } catch (_) {}

      final newAnnotation = EditorAnnotation(
        id: annId,
        pageNumber: pageNumber,
        type: AnnotationType.existingText,
        normalizedX: detectedNormX,
        normalizedY: detectedNormY,
        normalizedWidth: max(detectedNormW, 0.16),
        normalizedHeight: max(detectedNormH, 0.038),
        text: detectedText,
        fontSize: detectedFontSize,
        color: Colors.black87,
        fillColor: Colors.white,
        fontFamily: widget.controller.activeFontFamily,
        isBold: widget.controller.activeIsBold,
        isItalic: widget.controller.activeIsItalic,
        alignment: widget.controller.activeAlignment,
      );
      widget.tab.addAnnotation(newAnnotation);
      widget.controller.selectAnnotation(newAnnotation);
      setState(() {
        _editingAnnotationId = newAnnotation.id;
        _inlineTextController.text = detectedText;
      });
      widget.controller.setToolMode(EditorToolMode.selectText);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inlineFocusNode.requestFocus();
        _inlineTextController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _inlineTextController.text.length,
        );
      });
      return;
    } else if (mode == EditorToolMode.stickyNote) {
      final result = await TextBoxDialog.show(
        context,
        initialText: 'Add note...',
        initialFontSize: 12,
        initialTextColor: Colors.black87,
        initialFillColor: const Color(0xFFFFF275),
      );
      if (result != null) {
        final note = EditorAnnotation.createStickyNote(
          id: annId,
          pageNumber: pageNumber,
          normX: normX,
          normY: normY,
          text: result.text,
          author: 'FetchPDF User',
        );
        widget.tab.addAnnotation(note);
        widget.controller.selectAnnotation(note);
      }
    } else if (mode == EditorToolMode.stamp) {
      final stamp = EditorAnnotation.createStamp(
        id: annId,
        pageNumber: pageNumber,
        normX: normX,
        normY: normY,
        normWidth: 0.30,
        normHeight: 0.08,
        stampText: widget.controller.activeStampText,
        color: widget.controller.activeStampText == 'CONFIDENTIAL' || widget.controller.activeStampText == 'VOID'
            ? const Color(0xFFD83B01)
            : const Color(0xFF107C41),
      );
      widget.tab.addAnnotation(stamp);
      widget.controller.selectAnnotation(stamp);
    }
  }

  void _handlePointerDown(int pageNumber, Offset localPos, Size pageSize) {
    final normPoint = Offset(
      (localPos.dx / pageSize.width).clamp(0.0, 1.0),
      (localPos.dy / pageSize.height).clamp(0.0, 1.0),
    );

    setState(() {
      _activeDrawingPage = pageNumber;
      if (widget.controller.toolMode == EditorToolMode.pen) {
        _currentDrawingNormalizedPoints = [normPoint];
      } else {
        _dragStartNormalized = normPoint;
        _dragCurrentNormalized = normPoint;
      }
    });
  }

  void _handlePointerMove(int pageNumber, Offset localPos, Size pageSize) {
    if (_activeDrawingPage != pageNumber) return;

    final normPoint = Offset(
      (localPos.dx / pageSize.width).clamp(0.0, 1.0),
      (localPos.dy / pageSize.height).clamp(0.0, 1.0),
    );

    // If eraser is active, remove any annotation under cursor
    if (widget.controller.toolMode == EditorToolMode.eraser) {
      _eraseAtPoint(pageNumber, normPoint);
      return;
    }

    setState(() {
      if (widget.controller.toolMode == EditorToolMode.pen) {
        _currentDrawingNormalizedPoints.add(normPoint);
      } else {
        _dragCurrentNormalized = normPoint;
      }
    });
  }

  void _handlePointerUp(int pageNumber, Offset localPos, Size pageSize) async {
    if (_activeDrawingPage != pageNumber) return;

    final mode = widget.controller.toolMode;
    final annId = DateTime.now().microsecondsSinceEpoch.toString();
    final normPoint = Offset(
      (localPos.dx / pageSize.width).clamp(0.0, 1.0),
      (localPos.dy / pageSize.height).clamp(0.0, 1.0),
    );

    final isTap = _pointerDownRawPos != null && (localPos - _pointerDownRawPos!).distance < 6.0;

    if (mode == EditorToolMode.eraser) {
      _eraseAtPoint(pageNumber, normPoint);
    } else if (isTap) {
      // Handle tap-to-place tools
      if (mode == EditorToolMode.textBox || mode == EditorToolMode.editText) {
        final result = await TextBoxDialog.show(
          context,
          initialTextColor: widget.controller.activeColor,
        );
        if (result != null) {
          final newAnnotation = mode == EditorToolMode.editText
              ? EditorAnnotation(
                  id: annId,
                  pageNumber: pageNumber,
                  type: AnnotationType.existingText,
                  normalizedX: normPoint.dx,
                  normalizedY: normPoint.dy,
                  normalizedWidth: 0.25,
                  normalizedHeight: 0.05,
                  text: result.text,
                  fontSize: result.fontSize,
                  color: result.textColor,
                  fillColor: Colors.white,
                  fontFamily: widget.controller.activeFontFamily,
                  isBold: widget.controller.activeIsBold,
                  isItalic: widget.controller.activeIsItalic,
                )
              : EditorAnnotation.createTextBox(
                  id: annId,
                  pageNumber: pageNumber,
                  normX: normPoint.dx,
                  normY: normPoint.dy,
                  normWidth: 0.25,
                  normHeight: 0.06,
                  text: result.text,
                  fontSize: result.fontSize,
                  color: result.textColor,
                  fillColor: result.fillColor,
                  fontFamily: widget.controller.activeFontFamily,
                  isBold: widget.controller.activeIsBold,
                  isItalic: widget.controller.activeIsItalic,
                );
          widget.tab.addAnnotation(newAnnotation);
        }
      } else if (mode == EditorToolMode.stickyNote) {
        final result = await TextBoxDialog.show(
          context,
          initialText: 'Add note...',
          initialFontSize: 12,
          initialTextColor: Colors.black87,
        );
        if (result != null) {
          final note = EditorAnnotation.createStickyNote(
            id: annId,
            pageNumber: pageNumber,
            normX: normPoint.dx,
            normY: normPoint.dy,
            text: result.text,
            author: 'FetchPDF User',
          );
          widget.tab.addAnnotation(note);
        }
      } else if (mode == EditorToolMode.stamp) {
        final stamp = EditorAnnotation.createStamp(
          id: annId,
          pageNumber: pageNumber,
          normX: normPoint.dx,
          normY: normPoint.dy,
          stampText: widget.controller.activeStampText,
          color: widget.controller.activeStampText == 'CONFIDENTIAL' || widget.controller.activeStampText == 'VOID'
              ? const Color(0xFFD83B01)
              : const Color(0xFF107C41),
        );
        widget.tab.addAnnotation(stamp);
      }
    } else {
      // Handle drag gestures
      if (mode == EditorToolMode.pen && _currentDrawingNormalizedPoints.length >= 2) {
        final drawing = EditorAnnotation.createDrawing(
          id: annId,
          pageNumber: pageNumber,
          normalizedPoints: List.from(_currentDrawingNormalizedPoints),
          color: widget.controller.activeColor,
          strokeWidth: widget.controller.activeStrokeWidth,
        );
        widget.tab.addAnnotation(drawing);
      } else if (_dragStartNormalized != null && _dragCurrentNormalized != null) {
        final left = min(_dragStartNormalized!.dx, _dragCurrentNormalized!.dx);
        final top = min(_dragStartNormalized!.dy, _dragCurrentNormalized!.dy);
        final width = (_dragStartNormalized!.dx - _dragCurrentNormalized!.dx).abs();
        final height = (_dragStartNormalized!.dy - _dragCurrentNormalized!.dy).abs();

        if (width > 0.005 || height > 0.005) {
          if (mode == EditorToolMode.highlight) {
            final highlight = EditorAnnotation.createHighlight(
              id: annId,
              pageNumber: pageNumber,
              normX: left,
              normY: top,
              normWidth: max(width, 0.02),
              normHeight: max(height, 0.02),
              color: widget.controller.activeColor.withAlpha(120),
            );
            widget.tab.addAnnotation(highlight);
          } else if (mode == EditorToolMode.underline) {
            final underline = EditorAnnotation.createUnderline(
              id: annId,
              pageNumber: pageNumber,
              normX: left,
              normY: top + height - 0.005,
              normWidth: max(width, 0.02),
              normHeight: 0.005,
              color: widget.controller.activeColor,
              strokeWidth: widget.controller.activeStrokeWidth,
            );
            widget.tab.addAnnotation(underline);
          } else if (mode == EditorToolMode.strikethrough) {
            final strikethrough = EditorAnnotation.createStrikethrough(
              id: annId,
              pageNumber: pageNumber,
              normX: left,
              normY: top + height / 2 - 0.002,
              normWidth: max(width, 0.02),
              normHeight: 0.004,
              color: widget.controller.activeColor,
              strokeWidth: widget.controller.activeStrokeWidth,
            );
            widget.tab.addAnnotation(strikethrough);
          } else if (mode == EditorToolMode.line) {
            final line = EditorAnnotation.createLine(
              id: annId,
              pageNumber: pageNumber,
              normX: left,
              normY: top,
              normWidth: max(width, 0.01),
              normHeight: max(height, 0.01),
              color: widget.controller.activeColor,
              strokeWidth: widget.controller.activeStrokeWidth,
            );
            widget.tab.addAnnotation(line);
          } else if (mode == EditorToolMode.arrow) {
            final arrow = EditorAnnotation.createArrow(
              id: annId,
              pageNumber: pageNumber,
              normX: left,
              normY: top,
              normWidth: max(width, 0.01),
              normHeight: max(height, 0.01),
              color: widget.controller.activeColor,
              strokeWidth: widget.controller.activeStrokeWidth,
            );
            widget.tab.addAnnotation(arrow);
          } else if (mode == EditorToolMode.rectangle) {
            final rect = EditorAnnotation.createRectangle(
              id: annId,
              pageNumber: pageNumber,
              normX: left,
              normY: top,
              normWidth: width,
              normHeight: height,
              color: widget.controller.activeColor,
              fillColor: widget.controller.activeFillColor,
              strokeWidth: widget.controller.activeStrokeWidth,
            );
            widget.tab.addAnnotation(rect);
          } else if (mode == EditorToolMode.ellipse) {
            final ellipse = EditorAnnotation.createEllipse(
              id: annId,
              pageNumber: pageNumber,
              normX: left,
              normY: top,
              normWidth: width,
              normHeight: height,
              color: widget.controller.activeColor,
              fillColor: widget.controller.activeFillColor,
              strokeWidth: widget.controller.activeStrokeWidth,
            );
            widget.tab.addAnnotation(ellipse);
          }
        }
      }
    }

    setState(() {
      _activeDrawingPage = null;
      _currentDrawingNormalizedPoints = [];
      _dragStartNormalized = null;
      _dragCurrentNormalized = null;
      _pointerDownRawPos = null;
    });
  }

  void _eraseAtPoint(int pageNumber, Offset normPoint) {
    final pageAnns = widget.tab.annotations.where((a) => a.pageNumber == pageNumber).toList();
    for (final ann in pageAnns) {
      if (ann.type == AnnotationType.drawing) {
        final hit = ann.normalizedPoints.any((p) => (p - normPoint).distance < 0.02);
        if (hit) {
          widget.tab.removeAnnotation(ann);
          break;
        }
      } else {
        final inBounds = normPoint.dx >= ann.normalizedX &&
            normPoint.dx <= (ann.normalizedX + ann.normalizedWidth) &&
            normPoint.dy >= ann.normalizedY &&
            normPoint.dy <= (ann.normalizedY + ann.normalizedHeight);
        if (inBounds) {
          widget.tab.removeAnnotation(ann);
          break;
        }
      }
    }
  }
}

// CustomPainter for rendering all existing page annotations
class _AnnotationPainter extends CustomPainter {
  final List<EditorAnnotation> annotations;
  final EditorAnnotation? selectedAnnotation;
  final Size pageSize;

  _AnnotationPainter({
    required this.annotations,
    required this.selectedAnnotation,
    required this.pageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final ann in annotations) {
      final isSelected = selectedAnnotation?.id == ann.id;
      final rect = ann.toActualRect(size);

      switch (ann.type) {
        case AnnotationType.textBox:
        case AnnotationType.existingText:
        case AnnotationType.stickyNote:
        case AnnotationType.stamp:
        case AnnotationType.image:
          // Handled by positioned interactive widgets above for double-click/drag/selection
          break;

        case AnnotationType.highlight:
          final paint = Paint()
            ..color = ann.color.withAlpha(100)
            ..style = PaintingStyle.fill;
          canvas.drawRect(rect, paint);
          if (isSelected) {
            canvas.drawRect(
              rect,
              Paint()
                ..color = const Color(0xFF0078D4)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2,
            );
          }
          break;

        case AnnotationType.underline:
          final paint = Paint()
            ..color = isSelected ? const Color(0xFF0078D4) : ann.color
            ..strokeWidth = isSelected ? ann.strokeWidth + 1 : ann.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawLine(rect.bottomLeft, rect.bottomRight, paint);
          break;

        case AnnotationType.strikethrough:
          final paint = Paint()
            ..color = isSelected ? const Color(0xFF0078D4) : ann.color
            ..strokeWidth = isSelected ? ann.strokeWidth + 1 : ann.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawLine(Offset(rect.left, rect.center.dy), Offset(rect.right, rect.center.dy), paint);
          break;

        case AnnotationType.line:
          final paint = Paint()
            ..color = isSelected ? const Color(0xFF0078D4) : ann.color
            ..strokeWidth = isSelected ? ann.strokeWidth + 1 : ann.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
          break;

        case AnnotationType.arrow:
          final paint = Paint()
            ..color = isSelected ? const Color(0xFF0078D4) : ann.color
            ..strokeWidth = isSelected ? ann.strokeWidth + 1 : ann.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
          final dx = rect.bottomRight.dx - rect.topLeft.dx;
          final dy = rect.bottomRight.dy - rect.topLeft.dy;
          final angle = atan2(dy, dx);
          const arrowLength = 12.0;
          final wing1 = Offset(
            rect.bottomRight.dx - arrowLength * cos(angle - pi / 6),
            rect.bottomRight.dy - arrowLength * sin(angle - pi / 6),
          );
          final wing2 = Offset(
            rect.bottomRight.dx - arrowLength * cos(angle + pi / 6),
            rect.bottomRight.dy - arrowLength * sin(angle + pi / 6),
          );
          canvas.drawLine(rect.bottomRight, wing1, paint);
          canvas.drawLine(rect.bottomRight, wing2, paint);
          break;

        case AnnotationType.drawing:
          if (ann.normalizedPoints.length >= 2) {
            final paint = Paint()
              ..color = isSelected ? const Color(0xFF0078D4) : ann.color
              ..strokeWidth = isSelected ? ann.strokeWidth + 1 : ann.strokeWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke;

            final path = Path();
            final p0 = Offset(
              ann.normalizedPoints.first.dx * size.width,
              ann.normalizedPoints.first.dy * size.height,
            );
            path.moveTo(p0.dx, p0.dy);
            for (var i = 1; i < ann.normalizedPoints.length; i++) {
              final pt = Offset(
                ann.normalizedPoints[i].dx * size.width,
                ann.normalizedPoints[i].dy * size.height,
              );
              path.lineTo(pt.dx, pt.dy);
            }
            canvas.drawPath(path, paint);
          }
          break;

        case AnnotationType.rectangle:
          if (ann.fillColor != null && ann.fillColor!.a > 0) {
            final fillPaint = Paint()
              ..color = ann.fillColor!
              ..style = PaintingStyle.fill;
            canvas.drawRect(rect, fillPaint);
          }
          final borderPaint = Paint()
            ..color = isSelected ? const Color(0xFF0078D4) : ann.color
            ..strokeWidth = isSelected ? ann.strokeWidth + 1.5 : ann.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawRect(rect, borderPaint);
          break;

        case AnnotationType.ellipse:
          if (ann.fillColor != null && ann.fillColor!.a > 0) {
            final fillPaint = Paint()
              ..color = ann.fillColor!
              ..style = PaintingStyle.fill;
            canvas.drawOval(rect, fillPaint);
          }
          final borderPaint = Paint()
            ..color = isSelected ? const Color(0xFF0078D4) : ann.color
            ..strokeWidth = isSelected ? ann.strokeWidth + 1.5 : ann.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawOval(rect, borderPaint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}

// CustomPainter for in-progress drawings or dragging shapes
class _ActiveDrawingPainter extends CustomPainter {
  final EditorToolMode toolMode;
  final List<Offset> points;
  final Offset? start;
  final Offset? current;
  final Color color;
  final double strokeWidth;
  final Size pageSize;

  _ActiveDrawingPainter({
    required this.toolMode,
    required this.points,
    required this.start,
    required this.current,
    required this.color,
    required this.strokeWidth,
    required this.pageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (toolMode == EditorToolMode.pen && points.length >= 2) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(points.first.dx * size.width, points.first.dy * size.height);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx * size.width, points[i].dy * size.height);
      }
      canvas.drawPath(path, paint);
    } else if (start != null && current != null) {
      final p1 = Offset(start!.dx * size.width, start!.dy * size.height);
      final p2 = Offset(current!.dx * size.width, current!.dy * size.height);
      final rect = Rect.fromPoints(p1, p2);

      if (toolMode == EditorToolMode.highlight) {
        final paint = Paint()
          ..color = color.withAlpha(120)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, paint);
      } else if (toolMode == EditorToolMode.underline) {
        final paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
        canvas.drawLine(rect.bottomLeft, rect.bottomRight, paint);
      } else if (toolMode == EditorToolMode.strikethrough) {
        final paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(rect.left, rect.center.dy), Offset(rect.right, rect.center.dy), paint);
      } else if (toolMode == EditorToolMode.line) {
        final paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
        canvas.drawLine(p1, p2, paint);
      } else if (toolMode == EditorToolMode.arrow) {
        final paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
        canvas.drawLine(p1, p2, paint);
        final dx = p2.dx - p1.dx;
        final dy = p2.dy - p1.dy;
        final angle = atan2(dy, dx);
        const arrowLength = 12.0;
        final wing1 = Offset(p2.dx - arrowLength * cos(angle - pi / 6), p2.dy - arrowLength * sin(angle - pi / 6));
        final wing2 = Offset(p2.dx - arrowLength * cos(angle + pi / 6), p2.dy - arrowLength * sin(angle + pi / 6));
        canvas.drawLine(p2, wing1, paint);
        canvas.drawLine(p2, wing2, paint);
      } else if (toolMode == EditorToolMode.rectangle) {
        final paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
        canvas.drawRect(rect, paint);
      } else if (toolMode == EditorToolMode.ellipse) {
        final paint = Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
        canvas.drawOval(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ActiveDrawingPainter oldDelegate) => true;
}
