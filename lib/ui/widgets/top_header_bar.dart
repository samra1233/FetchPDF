import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/app_state.dart';
import '../../state/editor_tab_controller.dart';
import 'app_logo.dart';

class TopHeaderBar extends StatefulWidget {
  final AppState appState;

  const TopHeaderBar({required this.appState, super.key});

  @override
  State<TopHeaderBar> createState() => _TopHeaderBarState();
}

class _TopHeaderBarState extends State<TopHeaderBar> with WindowListener {
  bool _isMaximized = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        windowManager.addListener(this);
        _checkMaximized();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        windowManager.removeListener(this);
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    try {
      final max = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = max);
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  Future<void> _handleMinimize() async {
    try {
      await windowManager.minimize();
    } catch (_) {}
  }

  Future<void> _handleToggleMaximize() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {}
  }

  Future<void> _handleClose() async {
    try {
      await windowManager.close();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1B1E2B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3245) : AppColors.borderLight;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Drag to move window handle for the brand area
          Expanded(
            child: DragToMoveArea(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: _handleToggleMaximize,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Row(
                    children: [
                      // 1. App Brand Logo & Name
                      InkWell(
                        onTap: () => widget.appState.setActiveNav(AppNavDestination.home),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FetchPdfLogo(size: 28, borderRadius: 7),
                            const SizedBox(width: 9),
                            Text(
                              'FetchPDF',
                              style: AppTypography.brandLogo.copyWith(
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // 2. Navigation Pills
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildNavPill(
                                context,
                                destination: AppNavDestination.home,
                                icon: Icons.home_rounded,
                                label: 'Home',
                                isDark: isDark,
                              ),
                              const SizedBox(width: 4),
                              _buildNavPill(
                                context,
                                destination: AppNavDestination.edit,
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                                isDark: isDark,
                              ),
                              const SizedBox(width: 4),
                              _buildNavPill(
                                context,
                                destination: AppNavDestination.annotate,
                                icon: Icons.drive_file_rename_outline_rounded,
                                label: 'Annotate',
                                isDark: isDark,
                              ),
                              const SizedBox(width: 4),
                              _buildNavPill(
                                context,
                                destination: AppNavDestination.organize,
                                icon: Icons.grid_view_rounded,
                                label: 'Organize',
                                isDark: isDark,
                              ),
                              const SizedBox(width: 4),
                              _buildNavPill(
                                context,
                                destination: AppNavDestination.convert,
                                icon: Icons.swap_horiz_rounded,
                                label: 'Convert',
                                isDark: isDark,
                              ),
                              const SizedBox(width: 4),
                              _buildNavPill(
                                context,
                                destination: AppNavDestination.fillAndSign,
                                icon: Icons.draw_outlined,
                                label: 'Fill & Sign',
                                isDark: isDark,
                              ),
                              const SizedBox(width: 4),
                              _buildNavPill(
                                context,
                                destination: AppNavDestination.protect,
                                icon: Icons.shield_outlined,
                                label: 'Protect',
                                isDark: isDark,
                              ),
                              const SizedBox(width: 4),
                              _buildNavPill(
                                context,
                                destination: AppNavDestination.tools,
                                icon: Icons.apps_rounded,
                                label: 'Tools',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Search Bar
          Container(
            width: 220,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF282C3D) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF3B4158) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 15,
                  color: isDark ? Colors.white54 : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search documents or tools...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withAlpha(12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Ctrl + F',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // 4. Dark/Light Theme Toggle
          Tooltip(
            message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            child: InkWell(
              onTap: () => widget.appState.toggleTheme(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF282C3D) : const Color(0xFFF1F5F9),
                ),
                child: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 16,
                  color: isDark ? const Color(0xFFFBBF24) : AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 5. Native Windows Custom Window Controls (Minimize, Maximize/Restore, Close)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWindowButton(
                icon: Icons.remove,
                tooltip: 'Minimize',
                onTap: _handleMinimize,
                isDark: isDark,
              ),
              _buildWindowButton(
                icon: _isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
                tooltip: _isMaximized ? 'Restore Down' : 'Maximize',
                onTap: _handleToggleMaximize,
                isDark: isDark,
              ),
              _buildWindowButton(
                icon: Icons.close_rounded,
                tooltip: 'Close',
                isClose: true,
                onTap: _handleClose,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavPill(
    BuildContext context, {
    required AppNavDestination destination,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isActive = widget.appState.activeNav == destination;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (destination == AppNavDestination.edit && widget.appState.activeTab != null) {
            widget.appState.getControllerForTab(widget.appState.activeTab!).setToolMode(EditorToolMode.selectText);
          }
          widget.appState.setActiveNav(destination);
        },
        borderRadius: BorderRadius.circular(18),
        hoverColor: isDark ? const Color(0xFF282C3D) : const Color(0xFFF1F5F9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6.5),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF2E3456) : AppColors.activeNavBg)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive
                    ? AppColors.brandPrimary
                    : (isDark ? Colors.white60 : AppColors.textSecondary),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppColors.brandPrimary
                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required String tooltip,
    bool isClose = false,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: isClose
              ? const Color(0xFFE81123)
              : (isDark ? Colors.white12 : Colors.black.withAlpha(15)),
          child: SizedBox(
            width: 44,
            height: 38,
            child: Icon(
              icon,
              size: icon == Icons.remove ? 14 : 12.5,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
