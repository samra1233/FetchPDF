import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/annotation_model.dart';
import '../../../models/document_tab.dart';
import '../../../services/form_service.dart';
import '../../../services/pdf_modifier_service.dart';
import '../../../services/signature_service.dart';
import '../../../state/app_state.dart';
import '../../../ui/widgets/signature_dialog.dart';

class FillSignScreen extends StatefulWidget {
  final AppState appState;

  const FillSignScreen({required this.appState, super.key});

  @override
  State<FillSignScreen> createState() => _FillSignScreenState();
}

class _FillSignScreenState extends State<FillSignScreen> {
  final List<List<Offset>> _signatureStrokes = [];
  List<Offset> _currentStroke = [];
  int _targetPage = 1;
  double _signatureX = 100;
  double _signatureY = 400;
  final double _sigWidth = 160;
  final double _sigHeight = 60;
  Uint8List? _activeSignaturePng;

  List<FormFieldInfo> _detectedFields = [];
  final Map<String, String> _formValues = {};

  @override
  void initState() {
    super.initState();
    _detectFormFields();
  }

  void _detectFormFields() {
    final activeTab = widget.appState.activeTab;
    if (activeTab != null) {
      try {
        _detectedFields = FormService.extractFormFields(activeTab.documentBytes);
        for (final f in _detectedFields) {
          _formValues[f.name] = f.value;
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = widget.appState.activeTab;
    final isDark = widget.appState.isDarkMode;

    if (activeTab == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.draw_outlined, size: 56, color: AppColors.brandPrimary),
            const SizedBox(height: 16),
            const Text('No Document Open', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Open a PDF document to fill form fields and place signatures.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Open PDF'),
              onPressed: () => widget.appState.openFile(),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Left Side: Signature Pad & Form Field List
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1E2B) : Colors.white,
            border: Border(right: BorderSide(color: isDark ? const Color(0xFF2E3245) : AppColors.borderLight)),
          ),
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Signature Tools', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                FilledButton.icon(
                  icon: const Icon(Icons.draw_rounded, size: 16),
                  label: const Text('Open Signature Dialog (Type/Draw)'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                  onPressed: _openSignatureDialog,
                ),
                const SizedBox(height: 12),

                // Signature Canvas Pad
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _currentStroke = [details.localPosition];
                          _signatureStrokes.add(_currentStroke);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _currentStroke.add(details.localPosition);
                        });
                      },
                      child: CustomPaint(
                        painter: _SignatureCanvasPainter(strokes: _signatureStrokes),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                      onPressed: () => setState(() {
                        _signatureStrokes.clear();
                        _activeSignaturePng = null;
                      }),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _signatureStrokes.isEmpty ? null : _saveDrawnSignature,
                      child: const Text('Use Signature'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Upload Signature Image'),
                  onPressed: _uploadSignatureImage,
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // Form Fields Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Form Fields', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('${_detectedFields.length} detected', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),

                if (_detectedFields.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No fillable form fields detected in this document. You can still place your electronic signature anywhere on any page.',
                      style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey),
                    ),
                  )
                else
                  ..._detectedFields.map((f) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: f.name,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        controller: TextEditingController(text: _formValues[f.name] ?? ''),
                        onChanged: (val) => _formValues[f.name] = val,
                      ),
                    );
                  }),

                const SizedBox(height: 14),

                if (_detectedFields.isNotEmpty)
                  FilledButton.icon(
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Apply Form Values'),
                    onPressed: () => _applyFormValues(activeTab),
                  ),
              ],
            ),
          ),
        ),

        // Center / Right: Live Interactive PDF View with draggable signature placement
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF13151F) : AppColors.appBackground,
            child: Stack(
              children: [
                // PDF Viewer
                Positioned.fill(
                  child: FutureBuilder<PdfDocument>(
                    future: PdfDocument.openData(activeTab.documentBytes),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return PdfPageView(
                        document: snapshot.data!,
                        pageNumber: _targetPage.clamp(1, activeTab.pageCount),
                      );
                    },
                  ),
                ),

                // Interactive Draggable Signature Box
                if (_activeSignaturePng != null)
                  Positioned(
                    left: _signatureX,
                    top: _signatureY,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _signatureX += details.delta.dx;
                          _signatureY += details.delta.dy;
                        });
                      },
                      child: Container(
                        width: _sigWidth,
                        height: _sigHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.brandPrimary, width: 2),
                          borderRadius: BorderRadius.circular(4),
                          color: AppColors.brandPrimary.withAlpha(20),
                        ),
                        child: Stack(
                          children: [
                            Image.memory(_activeSignaturePng!, fit: BoxFit.contain, width: _sigWidth, height: _sigHeight),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => setState(() => _activeSignaturePng = null),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Floating Action Bar at Top
                Positioned(
                  top: 14,
                  right: 20,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2135) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            const Text('Page: ', style: TextStyle(fontSize: 12)),
                            DropdownButton<int>(
                              value: _targetPage,
                              underline: const SizedBox(),
                              items: List.generate(activeTab.pageCount, (i) => i + 1).map((p) {
                                return DropdownMenuItem(value: p, child: Text('$p', style: const TextStyle(fontSize: 12)));
                              }).toList(),
                              onChanged: (p) {
                                if (p != null) setState(() => _targetPage = p);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_activeSignaturePng != null)
                        FilledButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Bake Signature on PDF'),
                          onPressed: () => _bakeSignature(activeTab),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _saveDrawnSignature() async {
    final png = await SignatureService.renderSignatureToPng(
      strokes: _signatureStrokes,
      canvasSize: const Size(280, 140),
    );
    if (png != null) {
      setState(() {
        _activeSignaturePng = png;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature ready! Drag to position on the PDF page.')),
      );
    }
  }

  void _uploadSignatureImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result.isNotEmpty) {
      final bytes = await result.first.xFile.readAsBytes();
      setState(() => _activeSignaturePng = bytes);
    }
  }

  void _openSignatureDialog() async {
    final bytes = await showDialog<Uint8List>(
      context: context,
      builder: (ctx) => const SignatureDialog(),
    );
    if (bytes != null) {
      setState(() => _activeSignaturePng = bytes);
    }
  }

  void _bakeSignature(DocumentTab tab) async {
    if (_activeSignaturePng == null) return;

    final normX = (_signatureX / 600.0).clamp(0.05, 0.75);
    final normY = (_signatureY / 800.0).clamp(0.05, 0.85);

    final ann = EditorAnnotation(
      id: 'sig_${DateTime.now().microsecondsSinceEpoch}',
      pageNumber: _targetPage,
      type: AnnotationType.image,
      imageBytes: _activeSignaturePng!,
      normalizedX: normX,
      normalizedY: normY,
      normalizedWidth: 0.28,
      normalizedHeight: 0.09,
    );
    tab.addAnnotation(ann);

    final bakedBytes = await PdfModifierService.applyModifications(tab);
    tab.updateDocumentBytes(bakedBytes);

    setState(() => _activeSignaturePng = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature successfully placed and baked into document!')),
      );
    }
  }

  void _applyFormValues(DocumentTab tab) {
    final updated = FormService.fillFormFields(
      pdfBytes: tab.documentBytes,
      values: _formValues,
    );
    tab.updateDocumentBytes(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form values saved to document!')),
    );
  }
}

class _SignatureCanvasPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignatureCanvasPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignatureCanvasPainter oldDelegate) => true;
}
