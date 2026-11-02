import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:fetchpdf/services/document_creation_service.dart';

void main() {
  test('DocumentCreationService: creates valid A4, Letter, Legal, and A3 documents', () {
    for (final sizePreset in PageSizePreset.values) {
      final bytes = DocumentCreationService.createNewDocument(
        size: sizePreset,
        orientation: PageOrientationPreset.portrait,
        pattern: PagePatternPreset.blank,
        pageCount: 2,
        title: 'Test_${sizePreset.name}.pdf',
      );

      final doc = PdfDocument(inputBytes: bytes);
      expect(doc.pages.count, 2);
      expect(doc.pages[0].size.width, closeTo(sizePreset.widthPt, 0.1));
      expect(doc.pages[0].size.height, closeTo(sizePreset.heightPt, 0.1));
      doc.dispose();
    }
  });

  test('DocumentCreationService: supports landscape orientation', () {
    final bytes = DocumentCreationService.createNewDocument(
      size: PageSizePreset.a4,
      orientation: PageOrientationPreset.landscape,
      pattern: PagePatternPreset.lined,
      pageCount: 1,
      title: 'Landscape.pdf',
    );

    final doc = PdfDocument(inputBytes: bytes);
    expect(doc.pages[0].size.width, greaterThan(doc.pages[0].size.height));
    doc.dispose();
  });
}
