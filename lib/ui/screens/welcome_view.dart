import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../widgets/app_logo.dart';

class WelcomeView extends StatelessWidget {
  final AppState appState;

  const WelcomeView({required this.appState, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF282828) : Colors.white;
    final borderColor = isDark ? const Color(0xFF383838) : const Color(0xFFE0E0E0);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo & App Name
              const FetchPdfLogo(size: 76, borderRadius: 18),
              const SizedBox(height: 20),
              const Text(
                'FetchPDF',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(
                'Professional Windows Desktop PDF Editor — Phase 1',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 36),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPrimaryActionButton(
                    icon: Icons.folder_open_rounded,
                    title: 'Open PDF Document',
                    subtitle: 'Browse files from your PC',
                    onTap: () => appState.openFile(),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 20),
                  _buildPrimaryActionButton(
                    icon: Icons.note_add_outlined,
                    title: 'Create Blank PDF',
                    subtitle: 'Start with blank document',
                    onTap: () => appState.openNewDocument(),
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Two Column: Recent Files & Shortcuts
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recent Files
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history_rounded, size: 18, color: Color(0xFF0078D4)),
                              SizedBox(width: 8),
                              Text('Recent Documents',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (appState.recentFiles.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('No recently opened files',
                                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                            )
                          else
                            ...appState.recentFiles.map((entry) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.picture_as_pdf_outlined,
                                    size: 20, color: Color(0xFFE53935)),
                                title: Text(entry.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                subtitle: Text(entry.path,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                onTap: () => appState.openFile(explicitPath: entry.path),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Keyboard Shortcuts
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.keyboard_outlined, size: 18, color: Color(0xFF0078D4)),
                              SizedBox(width: 8),
                              Text('Keyboard Shortcuts',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildShortcutRow('Open PDF', 'Ctrl + O'),
                          _buildShortcutRow('Save', 'Ctrl + S'),
                          _buildShortcutRow('Save As', 'Ctrl + Shift + S'),
                          _buildShortcutRow('Undo / Redo', 'Ctrl + Z / Ctrl + Y'),
                          _buildShortcutRow('Find in Document', 'Ctrl + F'),
                          _buildShortcutRow('Zoom In / Out', 'Ctrl + / Ctrl -'),
                          _buildShortcutRow('Hand / Pan Tool', 'H'),
                          _buildShortcutRow('Insert Text Box', 'T'),
                          _buildShortcutRow('Freehand Pen', 'P'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF282828) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF383838) : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0078D4).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF0078D4), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _buildShortcutRow(String action, String keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0078D4).withAlpha(20),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF0078D4).withAlpha(60)),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0078D4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
