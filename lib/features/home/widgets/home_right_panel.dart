import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../state/app_state.dart';
import '../../../ui/widgets/create_pdf_dialog.dart';
import '../../../ui/widgets/app_logo.dart';

class HomeRightPanel extends StatelessWidget {
  final AppState appState;

  const HomeRightPanel({required this.appState, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = appState.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1B1E2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3245) : AppColors.borderLight;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(left: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Quick Actions Section
            Text(
              'Quick Actions',
              style: AppTypography.rightPanelTitle.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            _buildQuickActionItem(
              icon: Icons.folder_open_rounded,
              iconColor: const Color(0xFF4F46E5),
              label: 'Open PDF',
              onTap: () => appState.openFile(),
              isDark: isDark,
            ),
            _buildQuickActionItem(
              icon: Icons.note_add_outlined,
              iconColor: const Color(0xFF4F46E5),
              label: 'Create PDF',
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
              isDark: isDark,
            ),
            _buildQuickActionItem(
              icon: Icons.sync_rounded,
              iconColor: const Color(0xFF0284C7),
              label: 'Convert PDF',
              onTap: () => appState.setActiveNav(AppNavDestination.convert),
              isDark: isDark,
            ),
            _buildQuickActionItem(
              icon: Icons.layers_outlined,
              iconColor: const Color(0xFF9333EA),
              label: 'Merge PDF',
              onTap: () => _showQuickDialog(context, 'Merge PDF'),
              isDark: isDark,
            ),
            _buildQuickActionItem(
              icon: Icons.compress_rounded,
              iconColor: const Color(0xFFDB2777),
              label: 'Compress PDF',
              onTap: () => _showQuickDialog(context, 'Compress PDF'),
              isDark: isDark,
            ),
            _buildQuickActionItem(
              icon: Icons.center_focus_strong_rounded,
              iconColor: const Color(0xFF00ACC1),
              label: 'OCR PDF',
              onTap: () => _showQuickDialog(context, 'OCR PDF'),
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // 2. Recent Folders Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Recent Folders',
                    style: AppTypography.rightPanelTitle.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (appState.recentFolders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(
                  'No recent folders yet.\nOpen PDFs to build folder history.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : AppColors.textMuted,
                  ),
                ),
              )
            else
              ...appState.recentFolders.take(5).map((folder) {
                final name = folder.split(RegExp(r'[\\/]')).lastWhere((s) => s.isNotEmpty, orElse: () => folder);
                return _buildFolderItem(
                  name: name,
                  path: folder,
                  isDark: isDark,
                );
              }),

            const SizedBox(height: 20),

            // 3. FetchPDF Desktop Edition Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3730A3),
                    Color(0xFF4F46E5),
                    Color(0xFF7C3AED),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FetchPdfLogo(size: 36, borderRadius: 8, showShadow: false),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'FetchPDF Desktop\nProfessional Edition',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildProBenefit('Full offline PDF editing'),
                  const SizedBox(height: 4),
                  _buildProBenefit('Real document conversions'),
                  const SizedBox(height: 4),
                  _buildProBenefit('Zero cloud dependencies'),
                  const SizedBox(height: 14),
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withAlpha(70)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '🛡️ Local & Private',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: isDark ? const Color(0xFF242736) : const Color(0xFFF1F5F9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderItem({
    required String name,
    required String path,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => appState.openFile(),
        borderRadius: BorderRadius.circular(6),
        hoverColor: isDark ? const Color(0xFF242736) : const Color(0xFFF1F5F9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProBenefit(String text) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, color: Colors.white, size: 12),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  void _showQuickDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action),
        content: Text('$action will be activated in upcoming milestones.\n\nYou can currently open, view, edit, annotate, and organize PDF documents in FetchPDF!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
