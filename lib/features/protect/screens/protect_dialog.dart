import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/document_tab.dart';
import '../../../services/compression_service.dart';
import '../../../services/pdf_security_service.dart';

class ProtectDialog extends StatefulWidget {
  final DocumentTab tab;

  const ProtectDialog({required this.tab, super.key});

  @override
  State<ProtectDialog> createState() => _ProtectDialogState();
}

class _ProtectDialogState extends State<ProtectDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Password fields
  final _userPassController = TextEditingController();
  final _ownerPassController = TextEditingController();
  bool _allowPrint = true;
  bool _allowCopy = true;
  bool _allowAnnotate = true;

  // Watermark fields
  final _watermarkController = TextEditingController(text: 'CONFIDENTIAL');
  double _watermarkOpacity = 0.25;

  // Compression
  CompressionResult? _compressionResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userPassController.dispose();
    _ownerPassController.dispose();
    _watermarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.brandPrimary),
          SizedBox(width: 8),
          Text('Protect & Optimize Document', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 380,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppColors.brandPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.brandPrimary,
              tabs: const [
                Tab(text: 'Encrypt / Password'),
                Tab(text: 'Watermark'),
                Tab(text: 'Compress'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Password Encryption
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Set Document Password (to Open)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _userPassController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            hintText: 'Enter user password...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Owner / Permission Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _ownerPassController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            hintText: 'Enter owner password...',
                          ),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          title: const Text('Allow Printing', style: TextStyle(fontSize: 12)),
                          value: _allowPrint,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() => _allowPrint = v ?? true),
                        ),
                        CheckboxListTile(
                          title: const Text('Allow Text Copying', style: TextStyle(fontSize: 12)),
                          value: _allowCopy,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() => _allowCopy = v ?? true),
                        ),
                        CheckboxListTile(
                          title: const Text('Allow Annotations & Markup', style: TextStyle(fontSize: 12)),
                          value: _allowAnnotate,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() => _allowAnnotate = v ?? true),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          icon: const Icon(Icons.lock, size: 16),
                          label: const Text('Apply Password & Encryption'),
                          onPressed: _applyPassword,
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Watermark
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Watermark Text', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _watermarkController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            hintText: 'e.g. CONFIDENTIAL, DRAFT, COPY',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Opacity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text('${(_watermarkOpacity * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _watermarkOpacity,
                          min: 0.1,
                          max: 0.8,
                          onChanged: (v) => setState(() => _watermarkOpacity = v),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.branding_watermark_outlined, size: 16),
                          label: const Text('Apply Watermark'),
                          onPressed: _applyWatermark,
                        ),
                      ],
                    ),
                  ),

                  // Tab 3: Compress
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PDF File Size Optimization',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Compresses streams, downsamples embedded images, and cleans unused objects without compromising readability.',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current File Size: ${(widget.tab.documentBytes.length / (1024 * 1024)).toStringAsFixed(2)} MB',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (_compressionResult != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Optimized Size: ${(_compressionResult!.compressedSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB (${_compressionResult!.reductionPercentage.toStringAsFixed(1)}% reduction)',
                                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.compress_rounded, size: 16),
                          label: const Text('Optimize & Compress Now'),
                          onPressed: _runCompression,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  void _applyPassword() {
    final userPass = _userPassController.text.trim();
    final ownerPass = _ownerPassController.text.trim();
    if (userPass.isEmpty && ownerPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify at least one password.')),
      );
      return;
    }

    final encrypted = PdfSecurityService.protectPdf(
      pdfBytes: widget.tab.documentBytes,
      existingPassword: widget.tab.password,
      userPassword: userPass,
      ownerPassword: ownerPass,
      allowPrinting: _allowPrint,
      allowCopy: _allowCopy,
      allowAnnotations: _allowAnnotate,
    );

    widget.tab.updateDocumentBytes(encrypted, newPassword: userPass, isEncrypted: true);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document encrypted and password-protected!')),
    );
  }

  void _applyWatermark() {
    final text = _watermarkController.text.trim();
    if (text.isEmpty) return;

    final updated = PdfSecurityService.addWatermark(
      pdfBytes: widget.tab.documentBytes,
      password: widget.tab.password,
      text: text,
      opacity: _watermarkOpacity,
    );

    widget.tab.updateDocumentBytes(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Watermark applied across all pages!')),
    );
  }

  void _runCompression() {
    final result = CompressionService.compressPdf(
      pdfBytes: widget.tab.documentBytes,
      password: widget.tab.password,
    );
    setState(() => _compressionResult = result);
    widget.tab.updateDocumentBytes(result.bytes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Optimized! New size: ${(result.compressedSizeBytes / 1024).toStringAsFixed(1)} KB')),
    );
  }
}
