import 'package:flutter/material.dart';
import '../../models/document_tab.dart';
import 'app_logo.dart';

class DocumentPropertiesDialog extends StatelessWidget {
  final DocumentTab tab;

  const DocumentPropertiesDialog({required this.tab, super.key});

  static void show(BuildContext context, DocumentTab tab) {
    showDialog(
      context: context,
      builder: (context) => DocumentPropertiesDialog(tab: tab),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = tab.metadata;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activePage = tab.pages.isNotEmpty && tab.activePageIndex <= tab.pages.length
        ? tab.pages[tab.activePageIndex - 1]
        : null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      title: const Row(
        children: [
          FetchPdfLogo(size: 24, borderRadius: 6),
          SizedBox(width: 10),
          Text('Document Properties', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('File Information'),
              _buildRow('File Name', meta.fileName),
              _buildRow('Location', meta.filePath.isEmpty ? 'In-Memory / Unsaved' : meta.filePath),
              _buildRow('File Size', meta.formattedFileSize),
              _buildRow('Page Count', '${tab.pages.length} pages'),
              _buildRow('Status', tab.isModified ? 'Unsaved edits present' : 'Saved / Clean'),
              const Divider(height: 24),
              _buildSectionHeader('Description & Metadata'),
              _buildRow('Title', meta.title.isEmpty ? '—' : meta.title),
              _buildRow('Author', meta.author.isEmpty ? '—' : meta.author),
              _buildRow('Subject', meta.subject.isEmpty ? '—' : meta.subject),
              _buildRow('Keywords', meta.keywords.isEmpty ? '—' : meta.keywords),
              _buildRow('Created', meta.formattedCreationDate),
              _buildRow('Modified', meta.formattedModificationDate),
              _buildRow('Producer', meta.producer.isEmpty ? '—' : meta.producer),
              if (activePage != null) ...[
                const Divider(height: 24),
                _buildSectionHeader('Active Page Specifications (Page ${tab.activePageIndex})'),
                _buildRow('Standard Size', activePage.standardSizeName),
                _buildRow('Dimensions (Points)',
                    '${activePage.sizeInPoints.width.toStringAsFixed(1)} × ${activePage.sizeInPoints.height.toStringAsFixed(1)} pt'),
                _buildRow('Dimensions (Inches)',
                    '${activePage.widthInInches.toStringAsFixed(2)} × ${activePage.heightInInches.toStringAsFixed(2)} in'),
                _buildRow('Dimensions (mm)',
                    '${activePage.widthInMm.toStringAsFixed(1)} × ${activePage.heightInMm.toStringAsFixed(1)} mm'),
                _buildRow('Orientation', activePage.orientation),
                _buildRow('Rotation', '${activePage.rotationAngle}°'),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0078D4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0078D4)),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
