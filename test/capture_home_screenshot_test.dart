import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fetchpdf/app.dart';
import 'package:fetchpdf/state/app_state.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (call) async => '.');
    try {
      final segoeFile = File(r'C:\Windows\Fonts\segoeui.ttf');
      if (segoeFile.existsSync()) {
        final bytes = segoeFile.readAsBytesSync();
        
        final fontLoaderSegoe = FontLoader('Segoe UI');
        fontLoaderSegoe.addFont(Future.value(ByteData.view(bytes.buffer)));
        await fontLoaderSegoe.load();

        // Also alias to Roboto so all Material default text styles render cleanly
        final fontLoaderRoboto = FontLoader('Roboto');
        fontLoaderRoboto.addFont(Future.value(ByteData.view(bytes.buffer)));
        await fontLoaderRoboto.load();
      }

      final iconFile = File('build/windows/x64/runner/Release/data/flutter_assets/fonts/MaterialIcons-Regular.otf');
      if (iconFile.existsSync()) {
        final bytes = iconFile.readAsBytesSync();
        final fontLoader = FontLoader('MaterialIcons');
        fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
        await fontLoader.load();
      }
    } catch (e) {
      debugPrint('Font loading error: $e');
    }
  });

  testWidgets('Capture FetchPDF Editor Screen screenshot at 1280x720', (WidgetTester tester) async {
    tester.view.physicalSize = const ui.Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final appState = AppState();
    appState.openSample();
    appState.setActiveNav(AppNavDestination.edit);

    final repaintKey = GlobalKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: repaintKey,
          child: FetchPdfApp(appState: appState),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      const outputPath = r'C:\Users\SOHAIL SONS\.gemini\antigravity\brain\785d7056-0fd1-4792-85f5-8020e2bab084\fetchpdf_editor_rendered.png';
      final file = File(outputPath);
      await file.writeAsBytes(pngBytes);
      debugPrint('Editor screenshot saved to: $outputPath (${pngBytes.length} bytes)');
    });

    appState.dispose();
  });
}
