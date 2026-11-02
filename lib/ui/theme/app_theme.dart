import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppTheme {
  // Fluent / FetchPDF Accent Colors
  static const Color accentBlue = AppColors.brandPrimary;
  static const Color accentHover = Color(0xFF4338CA);
  static const Color accentPressed = Color(0xFF3730A3);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF13151F);
  static const Color darkCanvas = Color(0xFF1E212D);
  static const Color darkSurface = Color(0xFF242736);
  static const Color darkSurfaceVariant = Color(0xFF2E3245);
  static const Color darkBorder = Color(0xFF363B52);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Light Theme Colors (Reference Accurate)
  static const Color lightBackground = AppColors.appBackground; // #F3F5FA
  static const Color lightCanvas = AppColors.secondarySurface;
  static const Color lightSurface = AppColors.cardSurface; // #FFFFFF
  static const Color lightSurfaceVariant = AppColors.secondarySurface;
  static const Color lightBorder = AppColors.borderLight; // #E4E8F0
  static const Color lightTextPrimary = AppColors.textPrimary; // #171B2C
  static const Color lightTextSecondary = AppColors.textSecondary; // #687084

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandPrimary,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        outline: lightBorder,
      ),
      dividerColor: lightBorder,
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: Color(0xFF1E2433),
          borderRadius: BorderRadius.all(Radius.circular(6)),
          border: Border.fromBorderSide(BorderSide(color: Color(0xFF334155))),
        ),
        textStyle: TextStyle(fontSize: 12, color: Colors.white),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 13, color: lightTextPrimary),
        bodySmall: TextStyle(fontSize: 11, color: lightTextSecondary),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: lightTextPrimary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandPrimaryLight,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        outline: darkBorder,
      ),
      dividerColor: darkBorder,
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: Color(0xFF323232),
          borderRadius: BorderRadius.all(Radius.circular(6)),
          border: Border.fromBorderSide(BorderSide(color: darkBorder)),
        ),
        textStyle: TextStyle(fontSize: 12, color: darkTextPrimary),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 13, color: darkTextPrimary),
        bodySmall: TextStyle(fontSize: 11, color: darkTextSecondary),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextPrimary),
      ),
    );
  }
}
