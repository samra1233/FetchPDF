import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';

enum PageSizePreset {
  a4('A4 (210 × 297 mm)', 595.28, 841.89),
  letter('Letter (8.5 × 11 in)', 612.0, 792.0),
  legal('Legal (8.5 × 14 in)', 612.0, 1008.0),
  a3('A3 (297 × 420 mm)', 841.89, 1190.55);

  final String label;
  final double widthPt;
  final double heightPt;

  const PageSizePreset(this.label, this.widthPt, this.heightPt);
}

enum PageOrientationPreset {
  portrait('Portrait'),
  landscape('Landscape');

  final String label;
  const PageOrientationPreset(this.label);
}

enum PagePatternPreset {
  blank('Blank'),
  grid('Grid Paper'),
  lined('Lined / Ruled');

  final String label;
  const PagePatternPreset(this.label);
}

class DocumentCreationService {
  /// Generates a valid new PDF document with custom page setup
  static Uint8List createNewDocument({
    PageSizePreset size = PageSizePreset.a4,
    PageOrientationPreset orientation = PageOrientationPreset.portrait,
    PagePatternPreset pattern = PagePatternPreset.blank,
    int pageCount = 1,
    String? title,
  }) {
    final document = PdfDocument();

    final width = orientation == PageOrientationPreset.portrait ? size.widthPt : size.heightPt;
    final height = orientation == PageOrientationPreset.portrait ? size.heightPt : size.widthPt;

    document.pageSettings.size = Size(width, height);
    document.pageSettings.orientation = orientation == PageOrientationPreset.portrait
        ? PdfPageOrientation.portrait
        : PdfPageOrientation.landscape;
    document.pageSettings.margins.all = 0;

    // Document Information
    document.documentInformation.title = title ?? 'Untitled Document';
    document.documentInformation.author = 'FetchPDF Desktop';
    document.documentInformation.creationDate = DateTime.now();

    for (int i = 0; i < pageCount; i++) {
      final page = document.pages.add();
      final graphics = page.graphics;

      if (pattern == PagePatternPreset.grid) {
        final pen = PdfPen(PdfColor(220, 226, 235), width: 0.5);
        for (double x = 20; x < width - 20; x += 20) {
          graphics.drawLine(pen, Offset(x, 20), Offset(x, height - 20));
        }
        for (double y = 20; y < height - 20; y += 20) {
          graphics.drawLine(pen, Offset(20, y), Offset(width - 20, y));
        }
      } else if (pattern == PagePatternPreset.lined) {
        final pen = PdfPen(PdfColor(220, 226, 235), width: 0.5);
        for (double y = 40; y < height - 20; y += 24) {
          graphics.drawLine(pen, Offset(30, y), Offset(width - 30, y));
        }
      }
    }

    final bytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return bytes;
  }
}
