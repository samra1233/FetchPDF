import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/persistent_storage_service.dart';
import '../../../state/app_state.dart';

class RecentDocumentsSection extends StatefulWidget {
  final AppState appState;

  const RecentDocumentsSection({required this.appState, super.key});

  @override
  State<RecentDocumentsSection> createState() => _RecentDocumentsSectionState();
}

class _RecentDocumentsSectionState extends State<RecentDocumentsSection> {
  String _activeTab = 'Recent';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final allRecent = widget.appState.recentFiles;

    final List<RecentFileEntry> displayedDocs;
    if (_activeTab == 'Starred') {
      displayedDocs = allRecent.where((e) => e.isStarred).toList();
    } else {
      displayedDocs = allRecent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          children: [
            Text(
              'Recent Documents',
              style: AppTypography.sectionTitle.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 20),
            // Filter Tabs
            _buildTabPill('Recent', isDark),
            const SizedBox(width: 6),
            _buildTabPill('Starred', isDark),
            const SizedBox(width: 6),
            _buildTabPill('Shared', isDark),
            const SizedBox(width: 6),
            _buildTabPill('Cloud', isDark),

            const Spacer(),

            if (allRecent.isNotEmpty)
              TextButton.icon(
                onPressed: () => widget.appState.clearRecent(),
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                label: const Text('Clear Recent', style: TextStyle(fontSize: 12)),
              ),
            const SizedBox(width: 14),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242736) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF333852) : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 16,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 16,
                      color: isDark ? Colors.white38 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Document List Table Container
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2135) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF333852) : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              // Table Header Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF25293E) : const Color(0xFFFAFBFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF333852) : AppColors.borderLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 60),
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Name',
                        style: AppTypography.tableHeader.copyWith(
                          color: isDark ? Colors.white60 : AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Last Opened',
                        style: AppTypography.tableHeader.copyWith(
                          color: isDark ? Colors.white60 : AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Size',
                        style: AppTypography.tableHeader.copyWith(
                          color: isDark ? Colors.white60 : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 80),
                  ],
                ),
              ),

              // Rows
              if (displayedDocs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          _activeTab == 'Starred' ? Icons.star_border_rounded : Icons.folder_open_outlined,
                          size: 36,
                          color: isDark ? Colors.white38 : AppColors.textMuted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _activeTab == 'Starred'
                              ? 'No starred documents yet'
                              : 'No recent documents opened yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => widget.appState.openFile(),
                          child: const Text('Open a PDF document'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedDocs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? const Color(0xFF282C40) : const Color(0xFFF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final doc = displayedDocs[index];
                    final dateStr = DateFormat.yMMMd().add_jm().format(doc.lastOpened);
                    final sizeMb = (doc.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (File(doc.path).existsSync()) {
                            await widget.appState.openFile(explicitPath: doc.path);
                          } else {
                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('File Not Found'),
                                content: Text('The file "${doc.path}" could not be found on disk. It may have been moved or deleted.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      widget.appState.removeRecent(doc.path);
                                    },
                                    child: const Text('Remove from Recent'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        hoverColor: isDark ? const Color(0xFF282C40) : const Color(0xFFF8FAFC),
                        borderRadius: index == displayedDocs.length - 1
                            ? const BorderRadius.vertical(bottom: Radius.circular(11))
                            : BorderRadius.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C3247) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF3B4360) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Icon(
                                  Icons.description_outlined,
                                  size: 16,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 8),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'PDF',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                flex: 5,
                                child: Text(
                                  doc.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.tableCellPrimary.copyWith(
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),

                              Expanded(
                                flex: 4,
                                child: Text(
                                  dateStr,
                                  style: AppTypography.tableCellSecondary.copyWith(
                                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                                  ),
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: Text(
                                  '$sizeMb MB',
                                  style: AppTypography.tableCellSecondary.copyWith(
                                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                                  ),
                                ),
                              ),

                              IconButton(
                                icon: Icon(
                                  doc.isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 18,
                                  color: doc.isStarred
                                      ? const Color(0xFFF59E0B)
                                      : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                ),
                                splashRadius: 16,
                                onPressed: () => widget.appState.toggleStarred(doc.path),
                              ),

                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_horiz_rounded,
                                  size: 18,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                ),
                                onSelected: (action) {
                                  if (action == 'open') {
                                    widget.appState.openFile(explicitPath: doc.path);
                                  } else if (action == 'star') {
                                    widget.appState.toggleStarred(doc.path);
                                  } else if (action == 'remove') {
                                    widget.appState.removeRecent(doc.path);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'open', child: Text('Open')),
                                  PopupMenuItem(
                                    value: 'star',
                                    child: Text(doc.isStarred ? 'Unstar' : 'Star'),
                                  ),
                                  const PopupMenuItem(value: 'remove', child: Text('Remove from Recent')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabPill(String title, bool isDark) {
    final isActive = _activeTab == title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _activeTab = title),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF312E81) : AppColors.activeNavBg)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? AppColors.brandPrimary
                  : (isDark ? Colors.white60 : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
