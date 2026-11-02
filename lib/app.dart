import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'ui/screens/main_screen.dart';
import 'ui/theme/app_theme.dart';

class FetchPdfApp extends StatelessWidget {
  final AppState appState;

  const FetchPdfApp({required this.appState, super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'FetchPDF',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: MainScreen(appState: appState),
        );
      },
    );
  }
}
