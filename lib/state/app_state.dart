import 'package:flutter/material.dart';
import '../models/document_tab.dart';
import '../services/document_creation_service.dart';
import '../services/file_service.dart';
import '../services/pdf_document_service.dart';
import '../services/persistent_storage_service.dart';
import '../services/printing_service.dart';
import '../services/sample_pdf_generator.dart';
import 'editor_tab_controller.dart';

enum AppNavDestination {
  home,
  edit,
  annotate,
  organize,
  convert,
  fillAndSign,
  protect,
  tools,
}

class AppState extends ChangeNotifier {
  final List<DocumentTab> _tabs = [];
  int _activeTabIndex = 0;
  final Map<String, EditorTabController> _controllers = {};
  List<RecentFileEntry> _recentFiles = [];
  List<String> _recentFolders = [];
  Future<String?> Function(String fileName)? passwordPromptHandler;

  AppNavDestination _activeNav = AppNavDestination.home;
  bool _isLeftSidebarVisible = true;
  bool _isRightPropertiesVisible = true;
  bool _isDarkMode = false;
  bool _isInitialized = false;

  AppNavDestination get activeNav => _activeNav;
  List<DocumentTab> get tabs => List.unmodifiable(_tabs);
  int get activeTabIndex => _activeTabIndex;
  DocumentTab? get activeTab =>
      _tabs.isNotEmpty && _activeTabIndex >= 0 && _activeTabIndex < _tabs.length ? _tabs[_activeTabIndex] : null;

  EditorTabController? get activeController {
    final tab = activeTab;
    if (tab == null) return null;
    return getControllerForTab(tab);
  }

  EditorTabController getControllerForTab(DocumentTab tab) {
    if (!_controllers.containsKey(tab.id)) {
      _controllers[tab.id] = EditorTabController(tab: tab);
    }
    return _controllers[tab.id]!;
  }

  bool get isLeftSidebarVisible => _isLeftSidebarVisible;
  bool get isRightPropertiesVisible => _isRightPropertiesVisible;
  bool get isDarkMode => _isDarkMode;
  List<RecentFileEntry> get recentFiles => List.unmodifiable(_recentFiles);
  List<String> get recentFolders => List.unmodifiable(_recentFolders);

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      _isDarkMode = await PersistentStorageService.isDarkMode();
      _recentFiles = await PersistentStorageService.getRecentFiles();
      _recentFolders = await PersistentStorageService.getRecentFolders();
      notifyListeners();
    } catch (_) {}
  }

  void setActiveNav(AppNavDestination destination) {
    _activeNav = destination;
    notifyListeners();
  }

  void toggleLeftSidebar() {
    _isLeftSidebarVisible = !_isLeftSidebarVisible;
    notifyListeners();
  }

  void toggleRightProperties() {
    _isRightPropertiesVisible = !_isRightPropertiesVisible;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await PersistentStorageService.setDarkMode(_isDarkMode);
  }

  void selectTab(int index) {
    if (index >= 0 && index < _tabs.length && index != _activeTabIndex) {
      _activeTabIndex = index;
      _activeNav = AppNavDestination.edit;
      notifyListeners();
    }
  }

  Future<void> openFile({String? explicitPath, String? password}) async {
    final path = explicitPath ?? await FileService.pickPdfFile();
    if (path == null) return;

    // Check if already open
    final existingIndex = _tabs.indexWhere((t) => t.filePath != null && t.filePath == path);
    if (existingIndex != -1) {
      selectTab(existingIndex);
      _activeNav = AppNavDestination.edit;
      return;
    }

    String? currentPassword = password;
    try {
      DocumentTab tab;
      try {
        tab = await PdfDocumentService.loadFromFile(path, password: currentPassword);
      } on PdfPasswordRequiredException {
        if (passwordPromptHandler != null) {
          final fileName = path.split(RegExp(r'[\\/]')).last;
          currentPassword = await passwordPromptHandler!(fileName);
          if (currentPassword == null || currentPassword.isEmpty) {
            return; // User cancelled password prompt
          }
          tab = await PdfDocumentService.loadFromFile(path, password: currentPassword);
        } else {
          rethrow;
        }
      }
      _addTab(tab);
      await PersistentStorageService.addRecentFile(path, sizeBytes: tab.documentBytes.length);
      _recentFiles = await PersistentStorageService.getRecentFiles();
      _recentFolders = await PersistentStorageService.getRecentFolders();
      _activeNav = AppNavDestination.edit;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void openNewDocument({
    PageSizePreset size = PageSizePreset.a4,
    PageOrientationPreset orientation = PageOrientationPreset.portrait,
    PagePatternPreset pattern = PagePatternPreset.blank,
    int pageCount = 1,
    String fileName = 'Untitled.pdf',
  }) {
    final bytes = DocumentCreationService.createNewDocument(
      size: size,
      orientation: orientation,
      pattern: pattern,
      pageCount: pageCount,
      title: fileName,
    );
    final tab = PdfDocumentService.parseDocument(bytes, fileName: fileName);
    _addTab(tab);
    _activeNav = AppNavDestination.edit;
  }

  void openSample({String fileName = 'FetchPDF_Sample.pdf'}) {
    final bytes = SamplePdfGenerator.createSampleDocument();
    final tab = PdfDocumentService.parseDocument(
      bytes,
      fileName: fileName,
    );
    _addTab(tab);
    _activeNav = AppNavDestination.edit;
  }

  void _addTab(DocumentTab tab) {
    tab.addListener(_onTabModified);
    _tabs.add(tab);
    _activeTabIndex = _tabs.length - 1;
    notifyListeners();
  }

  void _onTabModified() {
    notifyListeners();
  }

  Future<bool> closeTab(
    int index, {
    required Future<bool?> Function(DocumentTab tab) confirmDiscard,
  }) async {
    if (index < 0 || index >= _tabs.length) return false;
    final tab = _tabs[index];

    if (tab.isModified) {
      final shouldProceed = await confirmDiscard(tab);
      if (shouldProceed != true) return false;
    }

    tab.removeListener(_onTabModified);
    _controllers.remove(tab.id)?.dispose();
    _tabs.removeAt(index);
    tab.dispose();

    if (_tabs.isEmpty) {
      _activeTabIndex = 0;
      _activeNav = AppNavDestination.home;
    } else if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    }

    notifyListeners();
    return true;
  }

  Future<bool> saveActiveDocument() async {
    final tab = activeTab;
    if (tab == null) return false;
    final success = await FileService.saveDocument(tab);
    if (success && tab.filePath != null) {
      await PersistentStorageService.addRecentFile(tab.filePath!, sizeBytes: tab.documentBytes.length);
      _recentFiles = await PersistentStorageService.getRecentFiles();
    }
    notifyListeners();
    return success;
  }

  Future<bool> saveActiveDocumentAs() async {
    final tab = activeTab;
    if (tab == null) return false;
    final success = await FileService.saveAsDocument(tab);
    if (success && tab.filePath != null) {
      await PersistentStorageService.addRecentFile(tab.filePath!, sizeBytes: tab.documentBytes.length);
      _recentFiles = await PersistentStorageService.getRecentFiles();
    }
    notifyListeners();
    return success;
  }

  Future<bool> printActiveDocument() async {
    final tab = activeTab;
    if (tab == null) return false;
    return await PrintingService.printPdf(tab.documentBytes, jobName: tab.title);
  }

  Future<void> toggleStarred(String filePath) async {
    await PersistentStorageService.toggleStarred(filePath);
    _recentFiles = await PersistentStorageService.getRecentFiles();
    notifyListeners();
  }

  Future<void> removeRecent(String filePath) async {
    await PersistentStorageService.removeRecentFile(filePath);
    _recentFiles = await PersistentStorageService.getRecentFiles();
    notifyListeners();
  }

  Future<void> clearRecent() async {
    await PersistentStorageService.clearRecentFiles();
    _recentFiles = [];
    notifyListeners();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final tab in _tabs) {
      tab.removeListener(_onTabModified);
      tab.dispose();
    }
    super.dispose();
  }
}
