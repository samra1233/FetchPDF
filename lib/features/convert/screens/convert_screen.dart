import 'dart:io';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/conversion_service.dart';
import '../../../services/pdf_document_service.dart';
import '../../../state/app_state.dart';

enum ConversionFormat {
  pdfToWord('PDF to Word', Icons.description_outlined, Color(0xFF2563EB)),
  pdfToExcel('PDF to Excel', Icons.table_chart_outlined, Color(0xFF059669)),
  pdfToPpt('PDF to PowerPoint', Icons.slideshow_outlined, Color(0xFFEA580C)),
  pdfToImage('PDF to Image', Icons.image_outlined, Color(0xFF9333EA)),
  pdfToText('PDF to Text', Icons.text_snippet_outlined, Color(0xFF475569)),
  imageToPdf('Image to PDF', Icons.photo_library_outlined, Color(0xFF0284C7)),
  wordToPdf('Word to PDF', Icons.article_outlined, Color(0xFF2563EB));

  final String label;
  final IconData icon;
  final Color color;

  const ConversionFormat(this.label, this.icon, this.color);
}

class ConvertFileItem {
  final String path;
  final String name;
  final int pageCount;
  final int sizeBytes;
  final Uint8List bytes;
  bool isSelected;

  ConvertFileItem({
    required this.path,
    required this.name,
    required this.pageCount,
    required this.sizeBytes,
    required this.bytes,
    this.isSelected = true,
  });
}

class ConvertScreen extends StatefulWidget {
  final AppState appState;

  const ConvertScreen({required this.appState, super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  ConversionFormat _selectedFormat = ConversionFormat.pdfToWord;
  final List<ConvertFileItem> _selectedFiles = [];
  int _activePreviewIndex = 0;
  int _previewPage = 1;
  bool _isDragging = false;
  bool _isConverting = false;
  String _outputPath = '';
  bool _openAfterConversion = true;

  @override
  void initState() {
    super.initState();
    _initDefaultFolder();
    _syncActiveTab();
  }

  Future<void> _initDefaultFolder() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${docsDir.path}\\FetchPDF\\Converted');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    setState(() => _outputPath = outDir.path);
  }

  void _syncActiveTab() {
    final activeTab = widget.appState.activeTab;
    if (activeTab != null && _selectedFiles.isEmpty) {
      _selectedFiles.add(
        ConvertFileItem(
          path: activeTab.filePath ?? activeTab.title,
          name: activeTab.title,
          pageCount: activeTab.pageCount,
          sizeBytes: activeTab.documentBytes.length,
          bytes: activeTab.documentBytes,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Left Format Rail
        _buildFormatSidebar(isDark),

        // 2. Center Conversion Workspace
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF13151F) : AppColors.appBackground,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner
                  _buildConversionBanner(isDark),

                  const SizedBox(height: 20),

                  // Selected Files Section & Drop Zone
                  _buildFilesSection(isDark),

                  const SizedBox(height: 20),

                  // Conversion Settings
                  _buildSettingsSection(isDark),
                ],
              ),
            ),
          ),
        ),

        // 3. Right Preview & File Info Panel
        _buildRightPreviewPanel(isDark),
      ],
    );
  }

  Widget _buildFormatSidebar(bool isDark) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E2B) : Colors.white,
        border: Border(right: BorderSide(color: isDark ? const Color(0xFF2E3245) : AppColors.borderLight)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              'Convert PDF',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: ConversionFormat.values.map((fmt) {
                final isSelected = _selectedFormat == fmt;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedFormat = fmt),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? const Color(0xFF2E3456) : AppColors.activeNavBg)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: fmt.color.withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(fmt.icon, size: 15, color: fmt.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                fmt.label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.brandPrimary
                                      : (isDark ? Colors.white70 : AppColors.textPrimary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2135), const Color(0xFF28243D)]
              : [const Color(0xFFEFF4FF), const Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: isDark ? const Color(0xFF333852) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFormat.label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Convert your documents into genuine, editable files while preserving layout and structure.',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _selectedFormat.color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_selectedFormat.icon, size: 30, color: _selectedFormat.color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2135) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF333852) : AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Selected Files (${_selectedFiles.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Files'),
                onPressed: _pickFiles,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.remove, size: 16),
                label: const Text('Remove'),
                onPressed: _selectedFiles.any((f) => f.isSelected)
                    ? () => setState(() => _selectedFiles.removeWhere((f) => f.isSelected))
                    : null,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                onPressed: _selectedFiles.isNotEmpty ? () => setState(() => _selectedFiles.clear()) : null,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // File List Table
          if (_selectedFiles.isEmpty)
            DropTarget(
              onDragEntered: (_) => setState(() => _isDragging = true),
              onDragExited: (_) => setState(() => _isDragging = false),
              onDragDone: (detail) async {
                setState(() => _isDragging = false);
                for (final file in detail.files) {
                  await _addFileFromPath(file.path);
                }
              },
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF25293E) : const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isDragging ? AppColors.brandPrimary : const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 28, color: AppColors.brandPrimary),
                      SizedBox(height: 6),
                      Text('Drag and drop PDF files here, or click Add Files', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedFiles.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final file = _selectedFiles[index];
                final sizeMb = (file.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: file.isSelected,
                    onChanged: (val) => setState(() => file.isSelected = val ?? true),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('PDF', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(file.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    ],
                  ),
                  subtitle: Text(file.path, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${file.pageCount} pages | $sizeMb MB', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Ready', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  onTap: () => setState(() => _activePreviewIndex = index),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2135) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF333852) : AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Conversion Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),

          // Output Folder
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Output Folder',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: _outputPath,
                  ),
                  controller: TextEditingController(text: _outputPath),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Browse'),
                onPressed: _browseOutputFolder,
              ),
            ],
          ),

          const SizedBox(height: 12),

          CheckboxListTile(
            title: const Text('Open output file after conversion', style: TextStyle(fontSize: 12)),
            value: _openAfterConversion,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _openAfterConversion = val ?? true),
          ),

          const SizedBox(height: 16),

          // Primary Convert Button
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedFiles.isEmpty || _isConverting ? null : _executeConversion,
              icon: _isConverting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync_rounded),
              label: Text(
                _isConverting ? 'Converting...' : 'Convert to ${_selectedFormat.label.split(' to ').last}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPreviewPanel(bool isDark) {
    ConvertFileItem? previewDoc;
    if (_selectedFiles.isNotEmpty && _activePreviewIndex < _selectedFiles.length) {
      previewDoc = _selectedFiles[_activePreviewIndex];
    }

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E2B) : Colors.white,
        border: Border(left: BorderSide(color: isDark ? const Color(0xFF2E3245) : AppColors.borderLight)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Preview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            if (previewDoc == null)
              Container(
                height: 220,
                color: isDark ? const Color(0xFF25293E) : const Color(0xFFF8FAFD),
                child: const Center(
                  child: Text('No file selected', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              )
            else ...[
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: FutureBuilder<PdfDocument>(
                    future: PdfDocument.openData(previewDoc.bytes),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || _previewPage > snapshot.data!.pages.length) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      return PdfPageView(
                        document: snapshot.data!,
                        pageNumber: _previewPage,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 18),
                    onPressed: _previewPage > 1 ? () => setState(() => _previewPage--) : null,
                  ),
                  Text('$_previewPage / ${previewDoc.pageCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 18),
                    onPressed: _previewPage < previewDoc.pageCount ? () => setState(() => _previewPage++) : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('File Information', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildInfoRow('Name', previewDoc.name),
              _buildInfoRow('Pages', '${previewDoc.pageCount}'),
              _buildInfoRow('Size', '${(previewDoc.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB'),
              _buildInfoRow('Format', 'PDF 1.7'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    List<String> exts;
    if (_selectedFormat == ConversionFormat.imageToPdf) {
      exts = ['png', 'jpg', 'jpeg', 'bmp', 'webp'];
    } else if (_selectedFormat == ConversionFormat.wordToPdf) {
      exts = ['docx'];
    } else {
      exts = ['pdf', 'png', 'jpg', 'jpeg', 'docx'];
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: exts,
    );
    for (final file in result) {
      if (file.path != null) await _addFileFromPath(file.path!);
    }
  }

  Future<void> _addFileFromPath(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    final bytes = await file.readAsBytes();
    int count = 1;
    if (path.toLowerCase().endsWith('.pdf')) {
      try {
        final doc = await PdfDocumentService.loadFromFile(path);
        count = doc.pageCount;
      } catch (_) {}
    }

    setState(() {
      _selectedFiles.add(
        ConvertFileItem(
          path: path,
          name: file.uri.pathSegments.last,
          pageCount: count,
          sizeBytes: bytes.length,
          bytes: bytes,
        ),
      );
    });
  }

  Future<void> _browseOutputFolder() async {
    final selectedDir = await FilePicker.getDirectoryPath();
    if (selectedDir != null) {
      setState(() => _outputPath = selectedDir);
    }
  }

  Future<void> _executeConversion() async {
    setState(() => _isConverting = true);
    final List<String> generatedFiles = [];

    try {
      final targetFiles = _selectedFiles.where((f) => f.isSelected).toList();

      for (final fileItem in targetFiles) {
        final baseName = fileItem.name.replaceAll(RegExp(r'\.[^.]+$'), '');

        if (_selectedFormat == ConversionFormat.pdfToWord) {
          final docxBytes = ConversionService.pdfToDocx(fileItem.bytes);
          final outPath = '$_outputPath\\$baseName.docx';
          await File(outPath).writeAsBytes(docxBytes);
          generatedFiles.add(outPath);
        } else if (_selectedFormat == ConversionFormat.pdfToExcel) {
          final xlsxBytes = ConversionService.pdfToExcel(fileItem.bytes);
          final outPath = '$_outputPath\\$baseName.xlsx';
          await File(outPath).writeAsBytes(xlsxBytes);
          generatedFiles.add(outPath);
        } else if (_selectedFormat == ConversionFormat.pdfToPpt) {
          final pptxBytes = ConversionService.pdfToPpt(fileItem.bytes);
          final outPath = '$_outputPath\\$baseName.pptx';
          await File(outPath).writeAsBytes(pptxBytes);
          generatedFiles.add(outPath);
        } else if (_selectedFormat == ConversionFormat.pdfToImage) {
          final imagePaths = await ConversionService.pdfToImages(
            fileItem.bytes,
            outputDir: _outputPath,
            baseName: baseName,
          );
          generatedFiles.addAll(imagePaths);
        } else if (_selectedFormat == ConversionFormat.pdfToText) {
          final text = ConversionService.extractText(fileItem.bytes);
          final outPath = '$_outputPath\\$baseName.txt';
          await File(outPath).writeAsString(text);
          generatedFiles.add(outPath);
        } else if (_selectedFormat == ConversionFormat.imageToPdf) {
          final pdfBytes = ConversionService.imagesToPdf([fileItem.bytes]);
          final outPath = '$_outputPath\\$baseName.pdf';
          await File(outPath).writeAsBytes(pdfBytes);
          generatedFiles.add(outPath);
        } else if (_selectedFormat == ConversionFormat.wordToPdf) {
          final pdfBytes = ConversionService.docxToPdf(fileItem.bytes);
          final outPath = '$_outputPath\\$baseName.pdf';
          await File(outPath).writeAsBytes(pdfBytes);
          generatedFiles.add(outPath);
        }
      }

      setState(() => _isConverting = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Text('Conversion Completed'),
              ],
            ),
            content: Text('Successfully converted ${generatedFiles.length} file(s) to:\n$_outputPath'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (generatedFiles.isNotEmpty && _openAfterConversion) {
                    Process.run('explorer.exe', ['/select,', generatedFiles.first]);
                  }
                },
                child: const Text('Open in Explorer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isConverting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversion failed: $e')),
        );
      }
    }
  }
}
