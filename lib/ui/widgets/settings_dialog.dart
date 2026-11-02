import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_state.dart';
import 'app_logo.dart';

class SettingsDialog extends StatefulWidget {
  final AppState appState;

  const SettingsDialog({required this.appState, super.key});

  static void show(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(appState: appState),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _defaultZoom = 'Fit Width';
  bool _smoothScroll = true;
  bool _autoSaveEdits = true;
  bool _showTooltips = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3456) : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              children: [
                const FetchPdfLogo(size: 26, borderRadius: 6),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings & Preferences',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Configure appearance, viewer performance & desktop defaults',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  splashRadius: 16,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppColors.brandPrimary,
              unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
              indicatorColor: AppColors.brandPrimary,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.palette_outlined, size: 18), text: 'Appearance'),
                Tab(icon: Icon(Icons.picture_as_pdf_outlined, size: 18), text: 'Viewer'),
                Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'About'),
              ],
            ),
            const SizedBox(height: 14),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppearanceTab(isDark, borderColor),
                  _buildViewerTab(isDark, borderColor),
                  _buildAboutTab(isDark, borderColor),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceTab(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Theme Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141724) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF0284C7),
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDark ? 'Dark Theme (Active)' : 'Light Theme (Active)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        isDark ? 'Comfortable for low-light environments' : 'High-contrast desktop presentation',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDark,
                  activeThumbColor: AppColors.brandPrimary,
                  onChanged: (val) {
                    widget.appState.toggleTheme();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Interface Customization', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SwitchListTile(
            title: const Text('Show Tooltips', style: TextStyle(fontSize: 12.5)),
            subtitle: const Text('Display helpful descriptions when hovering over tools', style: TextStyle(fontSize: 11)),
            value: _showTooltips,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _showTooltips = v),
          ),
          SwitchListTile(
            title: const Text('Auto-save Workspace Edits', style: TextStyle(fontSize: 12.5)),
            subtitle: const Text('Preserve modified annotations in persistent cache', style: TextStyle(fontSize: 11)),
            value: _autoSaveEdits,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _autoSaveEdits = v),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerTab(bool isDark, Color borderColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Default Zoom Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _defaultZoom,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'Fit Width', child: Text('Fit to Width (Recommended)')),
              DropdownMenuItem(value: 'Fit Page', child: Text('Fit entire Page')),
              DropdownMenuItem(value: '100%', child: Text('Actual Size (100%)')),
              DropdownMenuItem(value: '125%', child: Text('125%')),
              DropdownMenuItem(value: '150%', child: Text('150%')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _defaultZoom = v);
            },
          ),
          const SizedBox(height: 18),
          const Text('Navigation & Scrolling', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SwitchListTile(
            title: const Text('Mouse Wheel Page Navigation', style: TextStyle(fontSize: 12.5)),
            subtitle: const Text('Spinning mouse wheel down/up navigates between pages', style: TextStyle(fontSize: 11)),
            value: _smoothScroll,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _smoothScroll = v),
          ),
          const Divider(height: 24),
          const Text('Document History', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Clear all recent files history', style: TextStyle(fontSize: 12)),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                label: const Text('Clear Recent', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () async {
                  await widget.appState.clearRecent();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recent files history cleared.')),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              const FetchPdfLogo(size: 48, borderRadius: 12),
              const SizedBox(height: 10),
              const Text(
                'FetchPDF Desktop Professional',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Version 2.4.0 (Windows x64)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141724) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: const Column(
            children: [
              _InfoRow(label: 'Rendering Core', value: 'pdfrx High-DPI Engine'),
              SizedBox(height: 8),
              _InfoRow(label: 'Security & PDF Spec', value: 'Syncfusion PDF 128-bit AES Core'),
              SizedBox(height: 8),
              _InfoRow(label: 'Architecture', value: 'Flutter Native Windows x64'),
              SizedBox(height: 8),
              _InfoRow(label: 'License Status', value: 'Active Desktop License'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
