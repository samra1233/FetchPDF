import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/annotation_model.dart';
import '../models/document_tab.dart';

enum EditorToolMode {
  hand,
  selectText,
  textBox,
  editText,
  highlight,
  underline,
  strikethrough,
  pen,
  line,
  arrow,
  rectangle,
  ellipse,
  stickyNote,
  stamp,
  image,
  eraser,
}

class EditorTabController extends ChangeNotifier {
  final DocumentTab tab;
  late final PdfViewerController pdfViewerController;

  EditorToolMode _toolMode = EditorToolMode.hand;
  double _zoomScale = 1.0;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  EditorAnnotation? _selectedAnnotation;

  // Active tool settings
  Color activeColor = const Color(0xFF0078D4);
  Color? activeFillColor; // Default to transparent (no background color)
  double activeStrokeWidth = 2.0;
  double activeFontSize = 14.0;
  String activeFontFamily = 'Helvetica';
  bool activeIsBold = false;
  bool activeIsItalic = false;
  TextAlign activeAlignment = TextAlign.left;
  String activeStampText = 'APPROVED';

  EditorTabController({required this.tab}) {
    pdfViewerController = PdfViewerController();
    pdfViewerController.addListener(_onViewerChanged);
  }

  void _onViewerChanged() {
    if (pdfViewerController.isReady) {
      final zoom = pdfViewerController.currentZoom;
      if ((_zoomScale - zoom).abs() > 0.005) {
        _zoomScale = zoom;
        notifyListeners();
      }
    }
  }

  PdfTextSearcher? _textSearcher;

  PdfTextSearcher? get textSearcher {
    if (_textSearcher == null && pdfViewerController.isReady) {
      try {
        _textSearcher = PdfTextSearcher(pdfViewerController);
        _textSearcher!.addListener(_onSearchChanged);
      } catch (_) {}
    }
    return _textSearcher;
  }

  void initSearcherIfReady() {
    if (_textSearcher == null && pdfViewerController.isReady) {
      try {
        _textSearcher = PdfTextSearcher(pdfViewerController);
        _textSearcher!.addListener(_onSearchChanged);
        notifyListeners();
      } catch (_) {}
    }
  }

  void _onSearchChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    pdfViewerController.removeListener(_onViewerChanged);
    _textSearcher?.removeListener(_onSearchChanged);
    _textSearcher?.dispose();
    super.dispose();
  }

  EditorToolMode get toolMode => _toolMode;
  EditorToolMode get activeToolMode => _toolMode;
  double get zoomScale => _zoomScale;
  bool get isSearchVisible => _isSearchVisible;
  bool get isSearchOpen => _isSearchVisible;
  String get searchQuery => _searchQuery;
  EditorAnnotation? get selectedAnnotation {
    if (_selectedAnnotation == null) return null;
    final current = tab.annotations.where((a) => a.id == _selectedAnnotation!.id).firstOrNull;
    if (current != null) {
      _selectedAnnotation = current;
    }
    return _selectedAnnotation;
  }

  void setActiveColor(Color color) {
    activeColor = color;
    if (_selectedAnnotation != null) {
      _selectedAnnotation = _selectedAnnotation!.copyWith(color: color);
      tab.updateAnnotation(_selectedAnnotation!);
    }
    notifyListeners();
  }

  void setActiveFillColor(Color? color) {
    activeFillColor = color;
    if (_selectedAnnotation != null) {
      _selectedAnnotation = _selectedAnnotation!.copyWith(fillColor: color);
      tab.updateAnnotation(_selectedAnnotation!);
    }
    notifyListeners();
  }

  void setActiveStrokeWidth(double width) {
    activeStrokeWidth = width;
    if (_selectedAnnotation != null) {
      _selectedAnnotation = _selectedAnnotation!.copyWith(strokeWidth: width);
      tab.updateAnnotation(_selectedAnnotation!);
    }
    notifyListeners();
  }

  void setActiveFontSize(double size) {
    activeFontSize = size;
    if (_selectedAnnotation != null) {
      _selectedAnnotation = _selectedAnnotation!.copyWith(fontSize: size);
      tab.updateAnnotation(_selectedAnnotation!);
    }
    notifyListeners();
  }

  void setActiveFontFamily(String font) {
    activeFontFamily = font;
    if (_selectedAnnotation != null) {
      _selectedAnnotation = _selectedAnnotation!.copyWith(fontFamily: font);
      tab.updateAnnotation(_selectedAnnotation!);
    }
    notifyListeners();
  }

  void toggleBold() {
    final currentBold = selectedAnnotation?.isBold ?? activeIsBold;
    activeIsBold = !currentBold;
    if (_selectedAnnotation != null) {
      _selectedAnnotation = _selectedAnnotation!.copyWith(isBold: activeIsBold);
      tab.updateAnnotation(_selectedAnnotation!);
    }
    notifyListeners();
  }

  void toggleItalic() {
    final currentItalic = selectedAnnotation?.isItalic ?? activeIsItalic;
    activeIsItalic = !currentItalic;
    if (_selectedAnnotation != null) {
      _selectedAnnotation = _selectedAnnotation!.copyWith(isItalic: activeIsItalic);
      tab.updateAnnotation(_selectedAnnotation!);
    }
    notifyListeners();
  }

  void setActiveAlignment(TextAlign align) {
    activeAlignment = align;
    if (_selectedAnnotation != null) {
      _selectedAnnotation = _selectedAnnotation!.copyWith(alignment: align);
      tab.updateAnnotation(_selectedAnnotation!);
    }
    notifyListeners();
  }

  void setActiveStampText(String stamp) {
    if (activeStampText != stamp) {
      activeStampText = stamp;
      notifyListeners();
    }
  }

  void setToolMode(EditorToolMode mode) {
    if (_toolMode != mode) {
      _toolMode = mode;
      _selectedAnnotation = null;
      notifyListeners();
    }
  }

  void selectAnnotation(EditorAnnotation? annotation) {
    _selectedAnnotation = annotation;
    if (annotation != null) {
      activeColor = annotation.color;
      activeFillColor = annotation.fillColor;
      activeStrokeWidth = annotation.strokeWidth;
      activeFontSize = annotation.fontSize;
      activeFontFamily = annotation.fontFamily;
      activeIsBold = annotation.isBold;
      activeIsItalic = annotation.isItalic;
      activeAlignment = annotation.alignment;
    }
    notifyListeners();
  }

  void deleteSelectedAnnotation() {
    if (_selectedAnnotation != null) {
      tab.removeAnnotation(_selectedAnnotation!);
      _selectedAnnotation = null;
      notifyListeners();
    }
  }

  void toggleSearch() {
    _isSearchVisible = !_isSearchVisible;
    if (!_isSearchVisible) {
      textSearcher?.resetTextSearch();
      _searchQuery = '';
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      textSearcher?.resetTextSearch();
    } else {
      textSearcher?.startTextSearch(query, caseInsensitive: true, goToFirstMatch: true);
    }
    notifyListeners();
  }

  void nextSearchResult() {
    textSearcher?.goToNextMatch();
    notifyListeners();
  }

  void prevSearchResult() {
    textSearcher?.goToPrevMatch();
    notifyListeners();
  }

  void addSignature(Uint8List pngBytes) {
    final annId = 'sig_${DateTime.now().microsecondsSinceEpoch}';
    final pageNum = tab.activePageIndex;
    final annotation = EditorAnnotation(
      id: annId,
      pageNumber: pageNum,
      type: AnnotationType.image,
      imageBytes: pngBytes,
      normalizedX: 0.35,
      normalizedY: 0.65,
      normalizedWidth: 0.30,
      normalizedHeight: 0.10,
    );
    tab.addAnnotation(annotation);
    selectAnnotation(annotation);
    notifyListeners();
  }

  // --- Zoom & Viewport Controls ---
  void zoomIn() {
    if (pdfViewerController.isReady) {
      try {
        pdfViewerController.zoomUp();
        _zoomScale = pdfViewerController.currentZoom;
        notifyListeners();
      } catch (_) {
        final target = (_zoomScale * 1.25).clamp(0.25, 4.0);
        setZoom(target);
      }
    }
  }

  void zoomOut() {
    if (pdfViewerController.isReady) {
      try {
        pdfViewerController.zoomDown();
        _zoomScale = pdfViewerController.currentZoom;
        notifyListeners();
      } catch (_) {
        final target = (_zoomScale / 1.25).clamp(0.25, 4.0);
        setZoom(target);
      }
    }
  }

  void resetZoom() {
    setZoom(1.0);
  }

  void setZoom(double scale) {
    final clamped = scale.clamp(0.25, 4.0);
    _zoomScale = clamped;
    notifyListeners();
    if (pdfViewerController.isReady) {
      try {
        pdfViewerController.setZoom(pdfViewerController.centerPosition, clamped);
      } catch (_) {
        try {
          final center = pdfViewerController.centerPosition;
          pdfViewerController.goTo(pdfViewerController.calcMatrixFor(center, zoom: clamped));
        } catch (_) {}
      }
    }
  }

  void fitWidth() {
    if (pdfViewerController.isReady) {
      final pageNum = tab.activePageIndex;
      final matrix = pdfViewerController.calcMatrixFitWidthForPage(pageNumber: pageNum);
      if (matrix != null) {
        pdfViewerController.goTo(matrix);
        _zoomScale = pdfViewerController.currentZoom;
        notifyListeners();
      }
    }
  }

  void fitPage() {
    if (pdfViewerController.isReady) {
      final pageNum = tab.activePageIndex;
      final matrix = pdfViewerController.calcMatrixForFit(pageNumber: pageNum);
      if (matrix != null) {
        pdfViewerController.goTo(matrix);
        _zoomScale = pdfViewerController.currentZoom;
        notifyListeners();
      }
    }
  }

  void goToPage(int pageNumber) {
    if (pdfViewerController.isReady && pageNumber >= 1 && pageNumber <= tab.pages.length) {
      pdfViewerController.goToPage(pageNumber: pageNumber);
      tab.setActivePage(pageNumber);
    }
  }

  void updateZoomFromViewer(double newScale) {
    if ((_zoomScale - newScale).abs() > 0.01) {
      _zoomScale = newScale;
      notifyListeners();
    }
  }
}
