import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/document_tab.dart';
import '../../../services/compression_service.dart';
import '../../../services/pdf_security_service.dart';
import '../../../state/app_state.dart';

class ProtectScreen extends StatefulWidget {
  final AppState appState;

  const ProtectScreen({required this.appState, super.key});

  @override
  State<ProtectScreen> createState() => _ProtectScreenState();
}

class _ProtectScreenState extends State<ProtectScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Password fields
  final _userPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _ownerPassController = TextEditingController();
  bool _obscureUserPass = true;
  bool _obscureConfirmPass = true;
  bool _obscureOwnerPass = true;
  bool _allowPrint = true;
  bool _allowCopy = false;
  bool _allowAnnotate = true;
  bool _allowFormEditing = true;

  // Watermark fields
  final _watermarkController = TextEditingController(text: 'CONFIDENTIAL');
  double _watermarkOpacity = 0.28;
  double _watermarkAngle = 45.0;
  double _watermarkFontSize = 46.0;
  Color _watermarkColor = const Color(0xFFEF4444);

  // Compression
  CompressionResult? _compressionResult;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final activeTab = widget.appState.activeTab;
    if (activeTab != null && activeTab.password != null) {
      _userPassController.text = activeTab.password!;
      _confirmPassController.text = activeTab.password!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userPassController.dispose();
    _confirmPassController.dispose();
    _ownerPassController.dispose();
    _watermarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = widget.appState.activeTab;
    final isDark = widget.appState.isDarkMode;

    final bgColor = isDark ? const Color(0xFF13151F) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E3456) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header Bar
          _buildTopBar(context, activeTab, isDark, surfaceColor, borderColor),

          // Main Content Workspace
          Expanded(
            child: activeTab == null
                ? _buildEmptyState(context, isDark, surfaceColor, borderColor)
                : _buildActiveWorkspace(context, activeTab, isDark, surfaceColor, borderColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    DocumentTab? activeTab,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.brandPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Protect & Secure PDF',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                activeTab != null
                    ? '${activeTab.fileName} • ${activeTab.isEncrypted ? 'Password Protected' : 'Unprotected'}'
                    : 'Bank-grade 128-bit AES encryption, permissions, watermarks & optimization',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (activeTab != null) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.save_as_rounded, size: 16),
              label: const Text('Save Protected As...'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: _saveProtectedAs,
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to Edit'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => widget.appState.setActiveNav(AppNavDestination.edit),
            ),
          ] else ...[
            FilledButton.icon(
              icon: const Icon(Icons.file_open_rounded, size: 16),
              label: const Text('Open PDF to Protect'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
              onPressed: () => widget.appState.openFile(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return DropTarget(
      onDragDone: (details) async {
        if (details.files.isNotEmpty) {
          final first = details.files.first;
          if (first.path.toLowerCase().endsWith('.pdf')) {
            await widget.appState.openFile(explicitPath: first.path);
          }
        }
      },
      child: Center(
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 50 : 15),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 38,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Protect & Secure PDF Documents',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Open an existing PDF document to encrypt it with a password, configure restrictions, stamp watermarks, or optimize file size.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.file_open_rounded, size: 18),
                    label: const Text('Open PDF File'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => widget.appState.openFile(),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Use Sample PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () => widget.appState.openSample(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveWorkspace(
    BuildContext context,
    DocumentTab activeTab,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Row(
      children: [
        // Left Column: Live Interactive PDF Preview
        Expanded(
          flex: 6,
          child: Container(
            color: isDark ? const Color(0xFF0F111A) : const Color(0xFFE2E8F0),
            child: Stack(
              children: [
                Center(
                  child: PdfViewer.data(
                    activeTab.pdfBytes,
                    sourceName: activeTab.fileName,
                    key: ValueKey('protect_${activeTab.id}_${activeTab.pdfBytes.length}'),
                    passwordProvider: activeTab.password != null ? () => activeTab.password : null,
                    params: PdfViewerParams(
                      backgroundColor: isDark ? const Color(0xFF0F111A) : const Color(0xFFE2E8F0),
                      margin: 16.0,
                    ),
                  ),
                ),
                // Security status pill at top-left
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: activeTab.isEncrypted
                          ? const Color(0xFF10B981).withAlpha(30)
                          : const Color(0xFFF59E0B).withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: activeTab.isEncrypted
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activeTab.isEncrypted ? Icons.lock_rounded : Icons.lock_open_rounded,
                          size: 14,
                          color: activeTab.isEncrypted
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeTab.isEncrypted
                              ? 'Password Protected (AES-128)'
                              : 'Unencrypted Document',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: activeTab.isEncrypted
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Column: Controls & Settings
        Container(
          width: 440,
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(left: BorderSide(color: borderColor)),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.brandPrimary,
                unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                indicatorColor: AppColors.brandPrimary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.lock_rounded, size: 18), text: 'Password'),
                  Tab(icon: Icon(Icons.branding_watermark_rounded, size: 18), text: 'Watermark'),
                  Tab(icon: Icon(Icons.compress_rounded, size: 18), text: 'Compress'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPasswordTab(activeTab, isDark),
                    _buildWatermarkTab(activeTab, isDark),
                    _buildCompressTab(activeTab, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTab(DocumentTab activeTab, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Open Password',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Users must enter this password to view or open the PDF.',
            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _userPassController,
            obscureText: _obscureUserPass,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: 'Enter user open password...',
              suffixIcon: IconButton(
                icon: Icon(_obscureUserPass ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscureUserPass = !_obscureUserPass),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Confirm Password',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _confirmPassController,
            obscureText: _obscureConfirmPass,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: 'Re-enter open password...',
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Permissions & Restrictions',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Control what actions recipients can perform on this document.',
            style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Allow Printing', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Allow recipients to print hard copies', style: TextStyle(fontSize: 11)),
            value: _allowPrint,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _allowPrint = v),
          ),
          SwitchListTile(
            title: const Text('Allow Content Copying', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Allow selecting and copying text or graphics', style: TextStyle(fontSize: 11)),
            value: _allowCopy,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _allowCopy = v),
          ),
          SwitchListTile(
            title: const Text('Allow Annotations & Comments', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Allow drawing, highlighting, and sticky notes', style: TextStyle(fontSize: 11)),
            value: _allowAnnotate,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _allowAnnotate = v),
          ),
          SwitchListTile(
            title: const Text('Allow Form Filling', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Allow completing existing interactive PDF forms', style: TextStyle(fontSize: 11)),
            value: _allowFormEditing,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _allowFormEditing = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'Master / Permissions Password (Optional)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _ownerPassController,
            obscureText: _obscureOwnerPass,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: 'Enter master password to edit permissions...',
              suffixIcon: IconButton(
                icon: Icon(_obscureOwnerPass ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscureOwnerPass = !_obscureOwnerPass),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _isProcessing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.lock_rounded, size: 18),
              label: Text(_isProcessing ? 'Encrypting...' : 'Apply Password & Encryption'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: _isProcessing ? null : () => _applyPassword(activeTab),
            ),
          ),
          if (activeTab.isEncrypted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lock_open_rounded, size: 18, color: Color(0xFFEF4444)),
                label: const Text('Remove Password Protection', style: TextStyle(color: Color(0xFFEF4444))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: _isProcessing ? null : () => _removePassword(activeTab),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWatermarkTab(DocumentTab activeTab, bool isDark) {
    const presets = ['CONFIDENTIAL', 'DRAFT', 'DO NOT COPY', 'SAMPLE', 'APPROVED'];
    const colors = [
      Color(0xFFEF4444), // Red
      Color(0xFF2563EB), // Blue
      Color(0xFF059669), // Green
      Color(0xFF475569), // Slate
      Color(0xFF1E293B), // Charcoal
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Watermark Text', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _watermarkController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: 'e.g. CONFIDENTIAL, DRAFT, COPY',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: presets.map((preset) {
              return ActionChip(
                label: Text(preset, style: const TextStyle(fontSize: 11)),
                onPressed: () => setState(() => _watermarkController.text = preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          const Text('Watermark Color', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: colors.map((c) {
              final isSelected = _watermarkColor == c;
              return GestureDetector(
                onTap: () => setState(() => _watermarkColor = c),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(color: c.withAlpha(160), blurRadius: 6, spreadRadius: 1),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Opacity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text('${(_watermarkOpacity * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _watermarkOpacity,
            min: 0.1,
            max: 0.8,
            onChanged: (v) => setState(() => _watermarkOpacity = v),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Angle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text('${_watermarkAngle.toInt()}°', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _watermarkAngle,
            min: 0,
            max: 90,
            divisions: 18,
            onChanged: (v) => setState(() => _watermarkAngle = v),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Font Size', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text('${_watermarkFontSize.toInt()} pt', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _watermarkFontSize,
            min: 24,
            max: 72,
            divisions: 12,
            onChanged: (v) => setState(() => _watermarkFontSize = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _isProcessing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.branding_watermark_rounded, size: 18),
              label: Text(_isProcessing ? 'Stamping Watermark...' : 'Apply Watermark Across All Pages'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: _isProcessing ? null : () => _applyWatermark(activeTab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompressTab(DocumentTab activeTab, bool isDark) {
    final currentMb = activeTab.documentBytes.length / (1024 * 1024);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PDF Compression & Optimization',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Stream compression and metadata optimization reduce file size while preserving high visual quality.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141724) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF2E3456) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current File Size:', style: TextStyle(fontSize: 12.5)),
                    Text(
                      currentMb >= 1.0 ? '${currentMb.toStringAsFixed(2)} MB' : '${(currentMb * 1024).toStringAsFixed(1)} KB',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                if (_compressionResult != null) ...[
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Optimized Size:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      Text(
                        '${(_compressionResult!.compressedSizeBytes / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Reduction:', style: TextStyle(fontSize: 12)),
                      Text(
                        '${_compressionResult!.reductionPercentage.toStringAsFixed(1)}% smaller',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _isProcessing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.compress_rounded, size: 18),
              label: Text(_isProcessing ? 'Optimizing...' : 'Optimize & Compress Document'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: _isProcessing ? null : () => _runCompression(activeTab),
            ),
          ),
        ],
      ),
    );
  }

  void _applyPassword(DocumentTab tab) async {
    final userPass = _userPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();
    final ownerPass = _ownerPassController.text.trim();

    if (userPass.isEmpty && ownerPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least an open password or owner password.')),
      );
      return;
    }

    if (userPass.isNotEmpty && userPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match! Please check your entry.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final encrypted = PdfSecurityService.protectPdf(
        pdfBytes: tab.documentBytes,
        existingPassword: tab.password,
        userPassword: userPass,
        ownerPassword: ownerPass,
        allowPrinting: _allowPrint,
        allowCopy: _allowCopy,
        allowAnnotations: _allowAnnotate,
        allowFormEditing: _allowFormEditing,
      );

      tab.updateDocumentBytes(encrypted, newPassword: userPass, isEncrypted: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document successfully encrypted with 128-bit AES password protection!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to protect document: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _removePassword(DocumentTab tab) async {
    final currentPass = tab.password ?? _userPassController.text.trim();
    if (currentPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the current password to decrypt.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final decrypted = PdfSecurityService.removePassword(
        pdfBytes: tab.documentBytes,
        password: currentPass,
      );

      tab.updateDocumentBytes(decrypted, newPassword: '', isEncrypted: false);
      _userPassController.clear();
      _confirmPassController.clear();
      _ownerPassController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password removed! Document is now unencrypted.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove password: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _applyWatermark(DocumentTab tab) async {
    final text = _watermarkController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter watermark text.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final updated = PdfSecurityService.addWatermark(
        pdfBytes: tab.documentBytes,
        password: tab.password,
        text: text,
        angle: _watermarkAngle,
        opacity: _watermarkOpacity,
        fontSize: _watermarkFontSize,
        color: _watermarkColor,
      );

      tab.updateDocumentBytes(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Watermark applied across all pages!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply watermark: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _runCompression(DocumentTab tab) async {
    setState(() => _isProcessing = true);
    try {
      final result = CompressionService.compressPdf(
        pdfBytes: tab.documentBytes,
        password: tab.password,
      );
      setState(() => _compressionResult = result);
      tab.updateDocumentBytes(result.bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Optimized! Saved ${result.reductionPercentage.toStringAsFixed(1)}% of file size.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to optimize: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _saveProtectedAs() async {
    final activeTab = widget.appState.activeTab;
    if (activeTab == null) return;

    var suggestedName = activeTab.fileName;
    if (!suggestedName.toLowerCase().endsWith('.pdf')) {
      suggestedName = '$suggestedName.pdf';
    }
    if (!suggestedName.startsWith('Protected_')) {
      suggestedName = 'Protected_$suggestedName';
    }

    final uri = await FilePicker.saveFile(
      dialogTitle: 'Save Protected PDF File',
      fileName: suggestedName,
      bytes: activeTab.documentBytes,
      mimeType: 'application/pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (uri != null && mounted) {
      final savedPath = uri.toFilePath();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Protected PDF saved to $savedPath'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }
}
