import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../state/app_state.dart';
import '../../../ui/widgets/create_pdf_dialog.dart';

class HomeHeroBanner extends StatefulWidget {
  final AppState appState;

  const HomeHeroBanner({required this.appState, super.key});

  @override
  State<HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<HomeHeroBanner> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2135), const Color(0xFF28243D)]
              : [const Color(0xFFEFF4FF), const Color(0xFFF5F3FF), const Color(0xFFFAF5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF333852) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background subtle decorative wave/glow
            Positioned(
              right: -40,
              top: -40,
              bottom: -40,
              width: 480,
              child: CustomPaint(
                painter: _HeroIllustrationPainter(isDark: isDark),
              ),
            ),

            // Foreground Content
            Row(
              children: [
                // Left Text & Actions
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'WELCOME TO FETCHPDF',
                          style: AppTypography.heroTag.copyWith(
                            color: isDark ? const Color(0xFF818CF8) : AppColors.brandPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Every PDF. Every Possibility.',
                          style: AppTypography.heroHeadline.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Edit, convert, organize, sign, and manage your PDFs with a\nbeautifully simple experience.',
                          style: AppTypography.heroSubtitle.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            // Primary Open PDF
                            ElevatedButton.icon(
                              onPressed: () => widget.appState.openFile(),
                              icon: const Icon(Icons.folder_open_rounded, size: 18),
                              label: const Text('Open PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => CreatePdfDialog(
                                    onCreated: ({
                                      required size,
                                      required orientation,
                                      required pattern,
                                      required pageCount,
                                      required fileName,
                                    }) {
                                      widget.appState.openNewDocument(
                                        size: size,
                                        orientation: orientation,
                                        pattern: pattern,
                                        pageCount: pageCount,
                                        fileName: fileName,
                                      );
                                    },
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.note_add_outlined,
                                size: 18,
                                color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                              ),
                              label: Text(
                                'Create PDF',
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF242736) : Colors.white,
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF3B4058) : const Color(0xFFE2E8F0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Dropzone with 3D Document Illustration
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32, top: 24, bottom: 24),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: DropTarget(
                        onDragEntered: (detail) => setState(() => _isDragging = true),
                        onDragExited: (detail) => setState(() => _isDragging = false),
                        onDragDone: (detail) {
                          setState(() => _isDragging = false);
                          if (detail.files.isNotEmpty) {
                            final firstFile = detail.files.first;
                            if (firstFile.path.toLowerCase().endsWith('.pdf')) {
                              widget.appState.openFile(explicitPath: firstFile.path);
                            }
                          }
                        },
                        child: InkWell(
                          onTap: () => widget.appState.openFile(),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 320,
                            height: 120,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? (_isDragging
                                      ? const Color(0xFF312E81).withAlpha(180)
                                      : const Color(0xFF1E2135).withAlpha(220))
                                  : (_isDragging
                                      ? const Color(0xFFEEF2FF)
                                      : Colors.white.withAlpha(210)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isDragging
                                    ? const Color(0xFF4F46E5)
                                    : (isDark ? const Color(0xFF474F72) : const Color(0xFF818CF8)),
                                width: _isDragging ? 2.0 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isDragging
                                      ? const Color(0xFF4F46E5).withAlpha(80)
                                      : Colors.black.withAlpha(isDark ? 40 : 15),
                                  blurRadius: _isDragging ? 20 : 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF312E81).withAlpha(100)
                                        : const Color(0xFFEEF2FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 28,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Drop your PDF here',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'or browse files',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                                          decoration: TextDecoration.underline,
                                          decorationColor: isDark
                                              ? const Color(0xFF818CF8)
                                              : const Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIllustrationPainter extends CustomPainter {
  final bool isDark;

  _HeroIllustrationPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft glowing pastel ribbon
    final ribbonPaint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [
                const Color(0xFF6366F1).withAlpha(40),
                const Color(0xFF8B5CF6).withAlpha(20),
                Colors.transparent,
              ]
            : [
                const Color(0xFFC7D2FE).withAlpha(120),
                const Color(0xFFDDD6FE).withAlpha(80),
                Colors.transparent,
              ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.1, size.height)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.5,
        size.width * 0.7,
        size.height * 0.8,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, ribbonPaint);

    // 2. Translucent Back PDF Document
    final doc2Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.12, 110, 140),
      const Radius.circular(8),
    );
    final doc2Paint = Paint()
      ..color = isDark ? Colors.white.withAlpha(12) : Colors.white.withAlpha(140)
      ..style = PaintingStyle.fill;
    final doc2Stroke = Paint()
      ..color = isDark ? Colors.white.withAlpha(25) : const Color(0xFFC7D2FE).withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(doc2Rect, doc2Paint);
    canvas.drawRRect(doc2Rect, doc2Stroke);

    // 3. Translucent Front PDF Document
    final doc1Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.38, size.height * 0.18, 120, 150),
      const Radius.circular(10),
    );
    final doc1Paint = Paint()
      ..color = isDark ? const Color(0xFF2E3456).withAlpha(180) : Colors.white.withAlpha(210)
      ..style = PaintingStyle.fill;
    final doc1Stroke = Paint()
      ..color = isDark ? const Color(0xFF6366F1).withAlpha(90) : const Color(0xFFA5B4FC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(doc1Rect, doc1Paint);
    canvas.drawRRect(doc1Rect, doc1Stroke);

    // Skeleton lines on front doc
    final linePaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(40) : const Color(0xFFCBD5E1)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.38 + 14, size.height * 0.18 + 26),
      Offset(size.width * 0.38 + 70, size.height * 0.18 + 26),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.38 + 14, size.height * 0.18 + 42),
      Offset(size.width * 0.38 + 95, size.height * 0.18 + 42),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.38 + 14, size.height * 0.18 + 58),
      Offset(size.width * 0.38 + 80, size.height * 0.18 + 58),
      linePaint,
    );

    // 4. Glossy Red 3D "PDF" badge
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.38 + 22, size.height * 0.18 + 78, 48, 22),
      const Radius.circular(5),
    );
    final badgePaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(badgeRect, badgePaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'PDF',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(size.width * 0.38 + 36, size.height * 0.18 + 83),
    );

    // 5. Stylized Blue Pointer Cursor
    final cursorPaint = Paint()..color = const Color(0xFF3B82F6);
    final cursorPath = Path()
      ..moveTo(size.width * 0.38 + 76, size.height * 0.18 + 86)
      ..lineTo(size.width * 0.38 + 86, size.height * 0.18 + 106)
      ..lineTo(size.width * 0.38 + 81, size.height * 0.18 + 107)
      ..lineTo(size.width * 0.38 + 85, size.height * 0.18 + 116)
      ..lineTo(size.width * 0.38 + 81, size.height * 0.18 + 118)
      ..lineTo(size.width * 0.38 + 77, size.height * 0.18 + 109)
      ..lineTo(size.width * 0.38 + 72, size.height * 0.18 + 113)
      ..close();
    canvas.drawPath(cursorPath, cursorPaint);
  }

  @override
  bool shouldRepaint(covariant _HeroIllustrationPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
