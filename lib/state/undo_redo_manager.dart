import 'package:flutter/foundation.dart';

abstract class UndoableAction {
  String get description;
  void undo();
  void redo();
}

class UndoRedoManager extends ChangeNotifier {
  final List<UndoableAction> _undoStack = [];
  final List<UndoableAction> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  String? get undoDescription => _undoStack.isNotEmpty ? _undoStack.last.description : null;
  String? get redoDescription => _redoStack.isNotEmpty ? _redoStack.last.description : null;

  void execute(UndoableAction action) {
    action.redo();
    _undoStack.add(action);
    _redoStack.clear();
    notifyListeners();
  }

  void recordExecuted(UndoableAction action) {
    _undoStack.add(action);
    _redoStack.clear();
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    final action = _undoStack.removeLast();
    action.undo();
    _redoStack.add(action);
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    final action = _redoStack.removeLast();
    action.redo();
    _undoStack.add(action);
    notifyListeners();
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
