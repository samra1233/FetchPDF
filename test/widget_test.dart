import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:fetchpdf/app.dart';
import 'package:fetchpdf/state/app_state.dart';

void main() {
  testWidgets('FetchPDF smoke test - renders Home Screen dashboard on desktop', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final appState = AppState();

    await tester.pumpWidget(FetchPdfApp(appState: appState));
    await tester.pumpAndSettle();

    // Verify Home Screen is displayed initially with all components
    expect(find.text('FetchPDF'), findsWidgets);
    expect(find.text('Every PDF. Every Possibility.'), findsOneWidget);
    expect(find.text('Popular Tools'), findsOneWidget);
    expect(find.text('Recent Documents'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Recent Folders'), findsOneWidget);
    expect(find.text('Drop your PDF here'), findsOneWidget);
    expect(find.text('Cloud Storage'), findsOneWidget);

    appState.dispose();
  });
}
