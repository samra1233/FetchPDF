import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fetchpdf/state/app_state.dart';
import 'package:fetchpdf/state/editor_tab_controller.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('AppState tab lifecycle, sample document, and tool modes', () {
    final appState = AppState();

    expect(appState.tabs.isEmpty, true);
    expect(appState.activeTab, null);

    // Open sample document
    appState.openSample();
    expect(appState.tabs.length, 1);
    expect(appState.activeTab != null, true);
    expect(appState.activeTab!.fileName, 'FetchPDF_Sample.pdf');
    expect(appState.activeTab!.pages.length, 3);

    // Verify Tab Controller
    final controller = appState.activeController;
    expect(controller != null, true);
    expect(controller!.toolMode, EditorToolMode.hand);

    // Switch tool mode
    controller.setToolMode(EditorToolMode.textBox);
    expect(controller.toolMode, EditorToolMode.textBox);

    // Open second sample tab
    appState.openSample();
    expect(appState.tabs.length, 2);
    expect(appState.activeTabIndex, 1);

    // Switch tab
    appState.selectTab(0);
    expect(appState.activeTabIndex, 0);

    // Toggle theme
    final initialTheme = appState.isDarkMode;
    appState.toggleTheme();
    expect(appState.isDarkMode, !initialTheme);

    // Toggle sidebar
    final initialSidebar = appState.isLeftSidebarVisible;
    appState.toggleLeftSidebar();
    expect(appState.isLeftSidebarVisible, !initialSidebar);

    appState.dispose();
  });
}
