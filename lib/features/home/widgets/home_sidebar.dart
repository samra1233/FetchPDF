import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state.dart';
import '../../../ui/widgets/create_pdf_dialog.dart';
import '../../../ui/widgets/settings_dialog.dart';

class HomeSidebar extends StatelessWidget {
  final AppState appState;
  final String activeSection;
  final ValueChanged<String> onSectionSelected;

  const HomeSidebar({
    required this.appState,
    required this.activeSection,
    required this.onSectionSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1B1E2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3245) : AppColors.borderLight;

    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Primary Action: + Open PDF
          Container(
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withAlpha(50),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => appState.openFile(),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Open PDF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 2. Secondary Action: Create PDF
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242736) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF363B52) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
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
                        appState.openNewDocument(
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 16,
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Create PDF',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Navigation List
          _buildNavMenuItem(
            id: 'home',
            icon: Icons.home_rounded,
            label: 'Home',
            isDark: isDark,
          ),
          _buildNavMenuItem(
            id: 'recent',
            icon: Icons.access_time_rounded,
            label: 'Recent',
            isDark: isDark,
          ),
          _buildNavMenuItem(
            id: 'starred',
            icon: Icons.star_outline_rounded,
            label: 'Starred',
            isDark: isDark,
          ),
          _buildNavMenuItem(
            id: 'shared',
            icon: Icons.people_outline_rounded,
            label: 'Shared',
            isDark: isDark,
          ),
          _buildNavMenuItem(
            id: 'cloud',
            icon: Icons.cloud_outlined,
            label: 'Cloud',
            isDark: isDark,
          ),
          _buildNavMenuItem(
            id: 'all_tools',
            icon: Icons.grid_view_outlined,
            label: 'All Tools',
            isDark: isDark,
          ),

          const Spacer(),

          // 4. Cloud Storage Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242736) : const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF363B52) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cloud_queue_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cloud Storage',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: 0.24,
                    minHeight: 5,
                    backgroundColor: isDark ? const Color(0xFF363B52) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '2.4 GB of 10 GB used',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 5. Settings Item
          InkWell(
            onTap: () {
              SettingsDialog.show(context, appState);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavMenuItem({
    required String id,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = activeSection == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSectionSelected(id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF2E3456) : AppColors.activeNavBg)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.brandPrimary
                      : (isDark ? Colors.white60 : AppColors.textSecondary),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.brandPrimary
                        : (isDark ? Colors.white70 : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
