import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/signature_service.dart';

class SignatureDialog extends StatefulWidget {
  const SignatureDialog({super.key});

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Draw Tab state
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  Color _drawColor = const Color(0xFF1E293B);
  final double _drawStrokeWidth = 2.5;

  // Type Tab state
  final TextEditingController _typeController = TextEditingController(text: 'John Doe');
  Color _typeColor = const Color(0xFF1E293B);
  int _selectedFontStyleIndex = 0;

  // Upload Tab state
  Uint8List? _uploadedBytes;
  String? _uploadedFileName;

  final List<String> _fontStyleNames = [
    'Elegant Script',
    'Brush Cursive',
    'Formal Calligraphy',
    'Modern Clean',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  TextStyle _getTypeTextStyle(int index, Color color) {
    switch (index) {
      case 0: // Elegant Script
        return TextStyle(
          fontSize: 32,
          fontFamily: 'Segoe Script',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          color: color,
        );
      case 1: // Brush Cursive
        return TextStyle(
          fontSize: 32,
          fontFamily: 'Segoe Print',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w700,
          color: color,
        );
      case 2: // Formal Calligraphy
        return TextStyle(
          fontSize: 30,
          fontFamily: 'Times New Roman',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: color,
        );
      case 3: // Modern Clean
      default:
        return TextStyle(
          fontSize: 28,
          fontFamily: 'Segoe UI',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
          letterSpacing: 2.0,
          color: color,
        );
    }
  }

  Future<void> _handleConfirm() async {
    Uint8List? signaturePng;

    if (_tabController.index == 0) {
      // Draw tab
      if (_strokes.isNotEmpty) {
        signaturePng = await SignatureService.renderSignatureToPng(
          strokes: _strokes,
          canvasSize: const Size(400, 160),
          strokeColor: _drawColor,
          strokeWidth: _drawStrokeWidth,
        );
      }
    } else if (_tabController.index == 1) {
      // Type tab
      final name = _typeController.text.trim();
      if (name.isNotEmpty) {
        final style = _getTypeTextStyle(_selectedFontStyleIndex, _typeColor);
        signaturePng = await SignatureService.renderTypedSignatureToPng(
          name: name,
          textStyle: style,
          canvasSize: const Size(400, 140),
        );
      }
    } else {
      // Upload tab
      signaturePng = _uploadedBytes;
    }

    if (mounted) {
      Navigator.of(context).pop(signaturePng);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1E2130) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E344E) : AppColors.borderLight;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Close Button
            Row(
              children: [
                const Icon(Icons.draw_rounded, color: AppColors.brandPrimary, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Add Signature',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  splashRadius: 18,
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262A3D) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white60 : AppColors.textSecondary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(icon: Icon(Icons.gesture, size: 16), text: 'Draw'),
                  Tab(icon: Icon(Icons.text_fields, size: 16), text: 'Type'),
                  Tab(icon: Icon(Icons.upload_file, size: 16), text: 'Upload'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Views Container
            SizedBox(
              height: 220,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDrawTab(borderColor, isDark),
                  _buildTypeTab(borderColor, isDark),
                  _buildUploadTab(borderColor, isDark),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Bottom Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Insert Signature'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _handleConfirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- DRAW TAB ---
  Widget _buildDrawTab(Color borderColor, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = [details.localPosition];
                    _strokes.add(_currentStroke);
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentStroke.add(details.localPosition);
                  });
                },
                child: CustomPaint(
                  painter: _SignaturePadPainter(
                    strokes: _strokes,
                    strokeColor: _drawColor,
                    strokeWidth: _drawStrokeWidth,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text('Ink: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            _buildColorDot(const Color(0xFF1E293B), _drawColor, (c) => setState(() => _drawColor = c)),
            _buildColorDot(const Color(0xFF1D4ED8), _drawColor, (c) => setState(() => _drawColor = c)),
            _buildColorDot(const Color(0xFF374151), _drawColor, (c) => setState(() => _drawColor = c)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear'),
              onPressed: () {
                setState(() {
                  _strokes.clear();
                  _currentStroke = [];
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // --- TYPE TAB ---
  Widget _buildTypeTab(Color borderColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _typeController,
                decoration: InputDecoration(
                  labelText: 'Your Full Name',
                  hintText: 'Enter name to sign...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                _buildColorDot(const Color(0xFF1E293B), _typeColor, (c) => setState(() => _typeColor = c)),
                _buildColorDot(const Color(0xFF1D4ED8), _typeColor, (c) => setState(() => _typeColor = c)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Style Options
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(_fontStyleNames.length, (idx) {
                  final isSelected = _selectedFontStyleIndex == idx;
                  return InkWell(
                    onTap: () => setState(() => _selectedFontStyleIndex = idx),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brandPrimary.withAlpha(20) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _typeController.text.isNotEmpty ? _typeController.text : 'John Doe',
                              style: _getTypeTextStyle(idx, _typeColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _fontStyleNames[idx],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? AppColors.brandPrimary : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- UPLOAD TAB ---
  Widget _buildUploadTab(Color borderColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262A3D) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: _uploadedBytes != null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Image.memory(_uploadedBytes!, fit: BoxFit.contain),
                ),
                const SizedBox(height: 8),
                Text(_uploadedFileName ?? 'Signature Image', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Choose Another Image'),
                  onPressed: _pickImage,
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.brandPrimary),
                const SizedBox(height: 8),
                const Text('Upload an image of your signature', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Supports PNG (with transparency), JPG', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('Browse Device'),
                  onPressed: _pickImage,
                ),
              ],
            ),
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result.isNotEmpty) {
      final bytes = await result.first.xFile.readAsBytes();
      setState(() {
        _uploadedBytes = bytes;
        _uploadedFileName = result.first.name;
      });
    }
  }

  Widget _buildColorDot(Color color, Color currentColor, ValueChanged<Color> onSelect) {
    final isSelected = currentColor == color;
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : Colors.grey.shade400,
            width: isSelected ? 2.5 : 1.0,
          ),
        ),
      ),
    );
  }
}

class _SignaturePadPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color strokeColor;
  final double strokeWidth;

  _SignaturePadPainter({
    required this.strokes,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
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
  bool shouldRepaint(covariant _SignaturePadPainter oldDelegate) => true;
}
