import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/convert/screens/convert_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/organize/screens/organize_screen.dart';
import '../../features/protect/screens/protect_screen.dart';
import '../../features/signatures/screens/fill_sign_screen.dart';
import '../../models/document_tab.dart';
import '../../state/app_state.dart';
import '../../state/editor_tab_controller.dart';
import '../widgets/password_dialog.dart';
import '../widgets/pdf_canvas_view.dart';
import '../widgets/properties_panel.dart';
import '../widgets/status_bar.dart';
import '../widgets/tab_bar_header.dart';
import '../widgets/thumbnail_sidebar.dart';
import '../widgets/toolbar.dart';
import '../widgets/top_header_bar.dart';
import '../widgets/create_pdf_dialog.dart';

class MainScreen extends StatefulWidget {
  final AppState appState;

  const MainScreen({required this.appState, super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    widget.appState.passwordPromptHandler = (fileName) => PasswordDialog.show(context, fileName);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    widget.appState.passwordPromptHandler = null;
    _focusNode.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    final primaryFocus = FocusManager.instance.primaryFocus;
    final isFocusedOnTextInput = primaryFocus != null &&
        (primaryFocus.context?.widget is EditableText ||
         primaryFocus.context?.findAncestorWidgetOfExactType<EditableText>() != null);

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyO) {
      widget.appState.openFile();
      return true;
    }

    if (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyS) {
      widget.appState.saveActiveDocumentAs();
      return true;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      widget.appState.saveActiveDocument();
      return true;
    }

    final activeTab = widget.appState.activeTab;
    if (activeTab != null) {
      if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (activeTab.undoRedo.canUndo) {
          activeTab.undoRedo.undo();
          return true;
        }
      }

      if ((isCtrl && event.logicalKey == LogicalKeyboardKey.keyY) ||
          (isCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyZ)) {
        if (activeTab.undoRedo.canRedo) {
          activeTab.undoRedo.redo();
          return true;
        }
      }

      final controller = widget.appState.activeController;
      if (controller != null) {
        if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
          controller.toggleSearch();
          return true;
        }

        // Only delete annotation with Delete key when NOT focused on any text input.
        // Backspace must NEVER delete annotations.
        if (!isFocusedOnTextInput && event.logicalKey == LogicalKeyboardKey.delete) {
          if (controller.selectedAnnotation != null) {
            controller.deleteSelectedAnnotation();
            return true;
          }
        }

        if (isCtrl && (event.logicalKey == LogicalKeyboardKey.equal || event.logicalKey == LogicalKeyboardKey.numpadAdd)) {
          controller.zoomIn();
          return true;
        }
        if (isCtrl && (event.logicalKey == LogicalKeyboardKey.minus || event.logicalKey == LogicalKeyboardKey.numpadSubtract)) {
          controller.zoomOut();
          return true;
        }
        if (isCtrl && (event.logicalKey == LogicalKeyboardKey.digit0 || event.logicalKey == LogicalKeyboardKey.numpad0)) {
          controller.resetZoom();
          return true;
        }

        if (event.logicalKey == LogicalKeyboardKey.escape) {
          controller.selectAnnotation(null);
          controller.setToolMode(EditorToolMode.selectText);
          return true;
        }

        if (!isFocusedOnTextInput) {
          if (event.logicalKey == LogicalKeyboardKey.pageDown) {
            final curr = activeTab.activePageIndex;
            if (curr < activeTab.pages.length) {
              controller.goToPage(curr + 1);
              return true;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
            final curr = activeTab.activePageIndex;
            if (curr > 1) {
              controller.goToPage(curr - 1);
              return true;
            }
          }
        }

        // Quick tool shortcuts only when NOT focused on any text input
        if (!isFocusedOnTextInput && !isCtrl && !isShift) {
          if (event.logicalKey == LogicalKeyboardKey.keyV) {
            controller.setToolMode(EditorToolMode.selectText);
            return true;
          } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
            controller.setToolMode(EditorToolMode.hand);
            return true;
          } else if (event.logicalKey == LogicalKeyboardKey.keyT) {
            controller.setToolMode(EditorToolMode.textBox);
            return true;
          } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
            controller.setToolMode(EditorToolMode.pen);
            return true;
          } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
            controller.setToolMode(EditorToolMode.highlight);
            return true;
          } else if (event.logicalKey == LogicalKeyboardKey.keyU) {
            controller.setToolMode(EditorToolMode.underline);
            return true;
          } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
            controller.setToolMode(EditorToolMode.rectangle);
            return true;
          }
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final activeTab = widget.appState.activeTab;
        final isHomeView = widget.appState.activeNav == AppNavDestination.home;

        return Scaffold(
          body: Column(
            children: [
              // 1. Universal Top Header Bar (Brand Logo, Nav Pills, Search, Window Controls)
              TopHeaderBar(appState: widget.appState),

              // 2. Main Body View
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (isHomeView) {
                      return HomeScreen(appState: widget.appState);
                    }
                    switch (widget.appState.activeNav) {
                      case AppNavDestination.organize:
                        return OrganizeScreen(appState: widget.appState);
                      case AppNavDestination.convert:
                        return ConvertScreen(appState: widget.appState);
                      case AppNavDestination.fillAndSign:
                        return FillSignScreen(appState: widget.appState);
                      case AppNavDestination.protect:
                        return ProtectScreen(appState: widget.appState);
                      case AppNavDestination.edit:
                      case AppNavDestination.annotate:
                      case AppNavDestination.tools:
                      default:
                        return _buildEditorWorkspace(activeTab);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditorWorkspace(DocumentTab? activeTab) {
    if (activeTab == null) {
      final isDark = widget.appState.isDarkMode;
      return Container(
        color: isDark ? const Color(0xFF13151F) : const Color(0xFFF1F5F9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_rounded, size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 18),
              Text(
                'Ready to Edit PDF Documents',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Open an existing PDF or create a sample document to start editing.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () => widget.appState.openFile(),
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('Open PDF File'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
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
                            widget.appState.openNewDocument(
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
                    icon: const Icon(Icons.note_add_outlined, size: 18),
                    label: const Text('Create New PDF'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final controller = widget.appState.getControllerForTab(activeTab);

    return Column(
      children: [
        // Multi-Document Tab Bar
        if (widget.appState.tabs.isNotEmpty)
          TabBarHeader(appState: widget.appState),

        // Main Application Toolbar
        TopToolbar(appState: widget.appState, controller: controller),

        // Workspace Canvas
        Expanded(
          child: Row(
            children: [
              // Left Thumbnail Sidebar
              if (widget.appState.isLeftSidebarVisible)
                ThumbnailSidebar(tab: activeTab, controller: controller),

              // Center PDF Canvas
              Expanded(
                child: PdfCanvasView(
                  key: ValueKey(activeTab.id),
                  tab: activeTab,
                  controller: controller,
                ),
              ),

              // Right Collapsible Properties Panel
              if (widget.appState.isRightPropertiesVisible)
                PropertiesPanel(tab: activeTab, controller: controller),
            ],
          ),
        ),

        // Bottom Status & Zoom Bar
        BottomStatusBar(tab: activeTab, controller: controller),
      ],
    );
  }
}
