import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const TextStyle brandLogo = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heroHeadline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.15,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle heroTag = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.brandPrimary,
    letterSpacing: 0.8,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle toolCardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle toolCardSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static const TextStyle navItem = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle navItemActive = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.brandPrimary,
  );

  static const TextStyle tableHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static const TextStyle tableCellPrimary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle tableCellSecondary = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle rightPanelTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}
