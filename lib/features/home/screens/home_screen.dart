import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state.dart';
import '../../home/widgets/home_hero_banner.dart';
import '../../home/widgets/home_right_panel.dart';
import '../../home/widgets/home_sidebar.dart';
import '../../home/widgets/popular_tools_grid.dart';
import '../../home/widgets/recent_documents_section.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;

  const HomeScreen({required this.appState, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeSidebarSection = 'home';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final contentBg = isDark ? const Color(0xFF13151F) : AppColors.appBackground;

    return Container(
      color: contentBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Left Sidebar
          HomeSidebar(
            appState: widget.appState,
            activeSection: _activeSidebarSection,
            onSectionSelected: (section) {
              setState(() => _activeSidebarSection = section);
              if (section == 'all_tools') {
                widget.appState.setActiveNav(AppNavDestination.tools);
              }
            },
          ),

          // 2. Main Scrollable Dashboard Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Banner
                    HomeHeroBanner(appState: widget.appState),

                    const SizedBox(height: 22),

                    // Popular Tools
                    PopularToolsGrid(appState: widget.appState),

                    const SizedBox(height: 22),

                    // Recent Documents Table
                    RecentDocumentsSection(appState: widget.appState),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // 3. Right Quick Actions & Folders Panel
          HomeRightPanel(appState: widget.appState),
        ],
      ),
    );
  }
}
