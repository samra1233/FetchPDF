import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../state/app_state.dart';

class PopularToolsGrid extends StatelessWidget {
  final AppState appState;

  const PopularToolsGrid({required this.appState, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDarkMode;

    final tools = [
      _ToolData(
        title: 'Edit PDF',
        description: 'Modify text, images, pages and more',
        icon: Icons.edit_outlined,
        iconBg: AppColors.editPinkBg,
        iconColor: AppColors.editPinkIcon,
        onTap: () async {
          if (appState.tabs.isEmpty) {
            await appState.openFile();
          } else {
            appState.setActiveNav(AppNavDestination.edit);
          }
        },
      ),
      _ToolData(
        title: 'Merge PDF',
        description: 'Combine multiple PDFs into one',
        icon: Icons.layers_outlined,
        iconBg: AppColors.mergePurpleBg,
        iconColor: AppColors.mergePurpleIcon,
        onTap: () => appState.setActiveNav(AppNavDestination.organize),
      ),
      _ToolData(
        title: 'Convert PDF',
        description: 'Convert to Word, Excel, PPT and more',
        icon: Icons.sync_rounded,
        iconBg: AppColors.convertBlueBg,
        iconColor: AppColors.convertBlueIcon,
        onTap: () => appState.setActiveNav(AppNavDestination.convert),
      ),
      _ToolData(
        title: 'Organize Pages',
        description: 'Reorder, rotate, delete and extract pages',
        icon: Icons.flip_to_front_rounded,
        iconBg: AppColors.organizeMintBg,
        iconColor: AppColors.organizeMintIcon,
        onTap: () => appState.setActiveNav(AppNavDestination.organize),
      ),
      _ToolData(
        title: 'Fill & Sign',
        description: 'Add signatures and fill PDF forms',
        icon: Icons.drive_file_rename_outline_rounded,
        iconBg: AppColors.signAmberBg,
        iconColor: AppColors.signAmberIcon,
        onTap: () => appState.setActiveNav(AppNavDestination.fillAndSign),
      ),
      _ToolData(
        title: 'OCR PDF',
        description: 'Make scanned PDFs searchable',
        icon: Icons.center_focus_strong_rounded,
        iconBg: AppColors.ocrCyanBg,
        iconColor: AppColors.ocrCyanIcon,
        onTap: () => appState.setActiveNav(AppNavDestination.convert),
      ),
      _ToolData(
        title: 'Compress PDF',
        description: 'Reduce file size without losing quality',
        icon: Icons.compress_rounded,
        iconBg: AppColors.compressRoseBg,
        iconColor: AppColors.compressRoseIcon,
        onTap: () {
          appState.setActiveNav(AppNavDestination.protect);
        },
      ),
      _ToolData(
        title: 'Protect PDF',
        description: 'Add password and set permissions',
        icon: Icons.lock_outline_rounded,
        iconBg: AppColors.protectIndigoBg,
        iconColor: AppColors.protectIndigoIcon,
        onTap: () {
          appState.setActiveNav(AppNavDestination.protect);
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Tools',
              style: AppTypography.sectionTitle.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            InkWell(
              onTap: () => appState.setActiveNav(AppNavDestination.tools),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      'View all tools',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF818CF8) : AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFF818CF8) : AppColors.brandPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Grid of 8 Tools (2 rows x 4 columns)
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 3 * 14) / 4;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: tools.map((tool) {
                return _buildToolCard(
                  tool: tool,
                  width: cardWidth,
                  isDark: isDark,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required _ToolData tool,
    required double width,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF242736) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: isDark ? const Color(0xFF2D3247) : const Color(0xFFF8FAFC),
        child: Container(
          width: width,
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF333852) : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              // Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? tool.iconColor.withAlpha(40) : tool.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  tool.icon,
                  size: 22,
                  color: isDark ? tool.iconColor.withAlpha(220) : tool.iconColor,
                ),
              ),

              const SizedBox(width: 12),

              // Title & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tool.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.toolCardTitle.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.toolCardSubtitle.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Arrow Circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E212D) : const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolData {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _ToolData({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
}
