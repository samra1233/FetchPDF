import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'state/app_state.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1280, 800),
        minimumSize: Size(960, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
        title: 'FetchPDF',
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    } catch (_) {}
  }

  final appState = AppState();
  await appState.initialize();

  // If launched with command line arguments (e.g. Windows File Explorer "Open with" or double-click)
  if (args.isNotEmpty) {
    final possiblePath = args.first;
    if (possiblePath.toLowerCase().endsWith('.pdf') && await File(possiblePath).exists()) {
      try {
        await appState.openFile(explicitPath: possiblePath);
      } catch (_) {
        // Fallback to welcome view if corrupted
      }
    }
  }

  runApp(FetchPdfApp(appState: appState));
}
