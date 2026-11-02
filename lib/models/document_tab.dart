import 'package:flutter/foundation.dart';
import 'annotation_model.dart';
import 'document_metadata.dart';
import 'page_info.dart';
import '../state/undo_redo_manager.dart';

class DocumentTab extends ChangeNotifier {
  final String id;
  String? filePath;
  String fileName;
  Uint8List pdfBytes;
  DocumentMetadata metadata;

  List<PageInfo> pages;
  final List<EditorAnnotation> annotations = [];
  final UndoRedoManager undoRedo = UndoRedoManager();

  bool _isModified = false;
  int _activePageIndex = 1;
  String? password;
  bool get isEncrypted => (password != null && password!.isNotEmpty) || metadata.isEncrypted;

  void setPassword(String? newPassword) {
    password = newPassword != null && newPassword.isNotEmpty ? newPassword : null;
    metadata = metadata.copyWith(isEncrypted: password != null);
    markModified();
    notifyListeners();
  }

  DocumentTab({
    required this.id,
    this.filePath,
    required this.fileName,
    required this.pdfBytes,
    required this.metadata,
    required List<PageInfo> pages,
    this.password,
  }) : pages = List.from(pages) {
    undoRedo.addListener(_onUndoRedoChanged);
  }

  void _onUndoRedoChanged() {
    notifyListeners();
  }

  void notifyChanged() => notifyListeners();

  @override
  void dispose() {
    undoRedo.removeListener(_onUndoRedoChanged);
    undoRedo.dispose();
    super.dispose();
  }

  bool get isModified => _isModified;
  int get activePageIndex => _activePageIndex;
  int get pageCount => pages.length;
  Uint8List get documentBytes => pdfBytes;
  set documentBytes(Uint8List val) => pdfBytes = val;
  String get title => fileName;

  void setActivePage(int page) {
    if (_activePageIndex != page && page >= 1 && page <= pages.length) {
      _activePageIndex = page;
      notifyListeners();
    }
  }

  void markModified() {
    if (!_isModified) {
      _isModified = true;
      notifyListeners();
    }
  }

  void markSaved({String? newPath, String? newFileName, Uint8List? updatedBytes}) {
    if (newPath != null) filePath = newPath;
    if (newFileName != null) fileName = newFileName;
    if (updatedBytes != null) pdfBytes = updatedBytes;
    _isModified = false;
    notifyListeners();
  }

  void updateDocumentBytes(Uint8List newBytes, {String? newPassword, bool? isEncrypted}) {
    pdfBytes = newBytes;
    if (newPassword != null) {
      password = newPassword.isNotEmpty ? newPassword : null;
    }
    if (isEncrypted != null) {
      metadata = metadata.copyWith(isEncrypted: isEncrypted);
    } else if (password != null && password!.isNotEmpty) {
      metadata = metadata.copyWith(isEncrypted: true);
    }
    markModified();
    notifyListeners();
  }

  // --- Annotation Operations ---
  void addAnnotation(EditorAnnotation annotation, {bool recordUndo = true}) {
    annotations.add(annotation);
    markModified();
    if (recordUndo) {
      undoRedo.recordExecuted(_AddAnnotationAction(this, annotation));
    }
    notifyListeners();
  }

  void removeAnnotation(EditorAnnotation annotation, {bool recordUndo = true}) {
    final index = annotations.indexWhere((a) => a.id == annotation.id);
    if (index != -1) {
      final removed = annotations.removeAt(index);
      markModified();
      if (recordUndo) {
        undoRedo.recordExecuted(_RemoveAnnotationAction(this, removed, index));
      }
      notifyListeners();
    }
  }

  void deleteAnnotation(String id, {bool recordUndo = true}) {
    final index = annotations.indexWhere((a) => a.id == id);
    if (index != -1) {
      removeAnnotation(annotations[index], recordUndo: recordUndo);
    }
  }

  void updateAnnotation(EditorAnnotation updated, {bool recordUndo = true}) {
    final index = annotations.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      final old = annotations[index];
      annotations[index] = updated;
      markModified();
      if (recordUndo) {
        undoRedo.recordExecuted(_UpdateAnnotationAction(this, old, updated));
      }
      notifyListeners();
    }
  }

  void bringAnnotationForward(EditorAnnotation annotation) {
    final index = annotations.indexWhere((a) => a.id == annotation.id);
    if (index != -1 && index < annotations.length - 1) {
      final item = annotations.removeAt(index);
      annotations.insert(index + 1, item);
      markModified();
      notifyListeners();
    }
  }

  void sendAnnotationBackward(EditorAnnotation annotation) {
    final index = annotations.indexWhere((a) => a.id == annotation.id);
    if (index > 0) {
      final item = annotations.removeAt(index);
      annotations.insert(index - 1, item);
      markModified();
      notifyListeners();
    }
  }

  // --- Page Operations ---
  void rotatePage(int pageIndex, int angleDelta, {bool recordUndo = true}) {
    if (pageIndex < 0 || pageIndex >= pages.length) return;
    final currentAngle = pages[pageIndex].rotationAngle;
    final newAngle = (currentAngle + angleDelta) % 360;
    pages[pageIndex] = pages[pageIndex].copyWith(rotationAngle: newAngle);
    markModified();
    if (recordUndo) {
      undoRedo.recordExecuted(_RotatePageAction(this, pageIndex, currentAngle, newAngle));
    }
    notifyListeners();
  }

  void deletePage(int pageIndex, {bool recordUndo = true}) {
    if (pages.length <= 1) return; // Prevent deleting the only remaining page
    if (pageIndex < 0 || pageIndex >= pages.length) return;

    final removedPage = pages.removeAt(pageIndex);
    // Remove or adjust annotations associated with this page
    final removedAnnotations = annotations.where((a) => a.pageNumber == (pageIndex + 1)).toList();
    annotations.removeWhere((a) => a.pageNumber == (pageIndex + 1));
    // Shift remaining annotations page numbers
    for (var i = 0; i < annotations.length; i++) {
      if (annotations[i].pageNumber > (pageIndex + 1)) {
        annotations[i] = annotations[i].copyWith(pageNumber: annotations[i].pageNumber - 1);
      }
    }

    if (_activePageIndex > pages.length) {
      _activePageIndex = pages.length;
    }

    markModified();
    if (recordUndo) {
      undoRedo.recordExecuted(_DeletePageAction(this, pageIndex, removedPage, removedAnnotations));
    }
    notifyListeners();
  }

  void reorderPage(int oldIndex, int newIndex, {bool recordUndo = true}) {
    if (oldIndex < 0 || oldIndex >= pages.length || newIndex < 0 || newIndex >= pages.length) return;
    final item = pages.removeAt(oldIndex);
    pages.insert(newIndex, item);

    // Adjust annotation page numbers for the moved page
    final oldPageNum = oldIndex + 1;
    final newPageNum = newIndex + 1;
    for (var i = 0; i < annotations.length; i++) {
      if (annotations[i].pageNumber == oldPageNum) {
        annotations[i] = annotations[i].copyWith(pageNumber: newPageNum);
      } else if (oldIndex < newIndex && annotations[i].pageNumber > oldPageNum && annotations[i].pageNumber <= newPageNum) {
        annotations[i] = annotations[i].copyWith(pageNumber: annotations[i].pageNumber - 1);
      } else if (oldIndex > newIndex && annotations[i].pageNumber >= newPageNum && annotations[i].pageNumber < oldPageNum) {
        annotations[i] = annotations[i].copyWith(pageNumber: annotations[i].pageNumber + 1);
      }
    }

    markModified();
    if (recordUndo) {
      undoRedo.recordExecuted(_ReorderPageAction(this, oldIndex, newIndex));
    }
    notifyListeners();
  }
}

// Action implementations for DocumentTab
class _AddAnnotationAction implements UndoableAction {
  final DocumentTab tab;
  final EditorAnnotation annotation;
  _AddAnnotationAction(this.tab, this.annotation);

  @override
  String get description => 'Add ${annotation.type.name}';

  @override
  void undo() => tab.removeAnnotation(annotation, recordUndo: false);

  @override
  void redo() => tab.addAnnotation(annotation, recordUndo: false);
}

class _RemoveAnnotationAction implements UndoableAction {
  final DocumentTab tab;
  final EditorAnnotation annotation;
  final int index;
  _RemoveAnnotationAction(this.tab, this.annotation, this.index);

  @override
  String get description => 'Delete ${annotation.type.name}';

  @override
  void undo() {
    if (index <= tab.annotations.length) {
      tab.annotations.insert(index, annotation);
    } else {
      tab.annotations.add(annotation);
    }
    tab.markModified();
    tab.notifyChanged();
  }

  @override
  void redo() => tab.removeAnnotation(annotation, recordUndo: false);
}

class _UpdateAnnotationAction implements UndoableAction {
  final DocumentTab tab;
  final EditorAnnotation oldAnnotation;
  final EditorAnnotation newAnnotation;
  _UpdateAnnotationAction(this.tab, this.oldAnnotation, this.newAnnotation);

  @override
  String get description => 'Edit ${newAnnotation.type.name}';

  @override
  void undo() => tab.updateAnnotation(oldAnnotation, recordUndo: false);

  @override
  void redo() => tab.updateAnnotation(newAnnotation, recordUndo: false);
}

class _RotatePageAction implements UndoableAction {
  final DocumentTab tab;
  final int pageIndex;
  final int oldAngle;
  final int newAngle;
  _RotatePageAction(this.tab, this.pageIndex, this.oldAngle, this.newAngle);

  @override
  String get description => 'Rotate Page ${pageIndex + 1}';

  @override
  void undo() {
    tab.pages[pageIndex] = tab.pages[pageIndex].copyWith(rotationAngle: oldAngle);
    tab.markModified();
    tab.notifyChanged();
  }

  @override
  void redo() {
    tab.pages[pageIndex] = tab.pages[pageIndex].copyWith(rotationAngle: newAngle);
    tab.markModified();
    tab.notifyChanged();
  }
}

class _DeletePageAction implements UndoableAction {
  final DocumentTab tab;
  final int pageIndex;
  final PageInfo page;
  final List<EditorAnnotation> annotations;
  _DeletePageAction(this.tab, this.pageIndex, this.page, this.annotations);

  @override
  String get description => 'Delete Page ${pageIndex + 1}';

  @override
  void undo() {
    tab.pages.insert(pageIndex, page);
    // Shift annotation page numbers back
    for (var i = 0; i < tab.annotations.length; i++) {
      if (tab.annotations[i].pageNumber >= (pageIndex + 1)) {
        tab.annotations[i] = tab.annotations[i].copyWith(pageNumber: tab.annotations[i].pageNumber + 1);
      }
    }
    tab.annotations.addAll(annotations);
    tab.markModified();
    tab.notifyChanged();
  }

  @override
  void redo() => tab.deletePage(pageIndex, recordUndo: false);
}

class _ReorderPageAction implements UndoableAction {
  final DocumentTab tab;
  final int oldIndex;
  final int newIndex;
  _ReorderPageAction(this.tab, this.oldIndex, this.newIndex);

  @override
  String get description => 'Move Page ${oldIndex + 1} to ${newIndex + 1}';

  @override
  void undo() => tab.reorderPage(newIndex, oldIndex, recordUndo: false);

  @override
  void redo() => tab.reorderPage(oldIndex, newIndex, recordUndo: false);
}
