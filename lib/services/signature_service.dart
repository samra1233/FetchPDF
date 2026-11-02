import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class SignatureService {
  /// Converts a series of stroke points into a transparent PNG byte array
  static Future<Uint8List?> renderSignatureToPng({
    required List<List<Offset>> strokes,
    required Size canvasSize,
    Color strokeColor = Colors.black,
    double strokeWidth = 3.0,
  }) async {
    if (strokes.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height));

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

    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasSize.width.toInt(), canvasSize.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// Converts typed text into a transparent signature PNG with authentic calligraphy styling
  static Future<Uint8List?> renderTypedSignatureToPng({
    required String name,
    required TextStyle textStyle,
    required Size canvasSize,
  }) async {
    if (name.trim().isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height));

    final textSpan = TextSpan(text: name, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: canvasSize.width - 20);

    final offset = Offset(
      ((canvasSize.width - textPainter.width) / 2).clamp(10.0, canvasSize.width),
      ((canvasSize.height - textPainter.height) / 2).clamp(10.0, canvasSize.height),
    );
    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasSize.width.toInt(), canvasSize.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// Bakes a signature PNG onto a specific page of a PDF document
  static Uint8List bakeSignatureOnPdf({
    required Uint8List pdfBytes,
    required Uint8List signaturePngBytes,
    required int pageIndex,
    required Rect bounds,
    double opacity = 1.0,
  }) {
    final document = PdfDocument(inputBytes: pdfBytes);
    if (pageIndex >= 0 && pageIndex < document.pages.count) {
      final page = document.pages[pageIndex];
      final graphics = page.graphics;
      final state = graphics.save();

      if (opacity < 1.0) {
        graphics.setTransparency(opacity);
      }

      final bitmap = PdfBitmap(signaturePngBytes);
      graphics.drawImage(bitmap, bounds);
      graphics.restore(state);
    }

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }
}
