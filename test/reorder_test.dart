import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('Page reordering test with sections', () {
    final doc = PdfDocument();
    final p1 = doc.pages.add();
    p1.graphics.drawString('Page 1', PdfStandardFont(PdfFontFamily.helvetica, 12));
    final p2 = doc.pages.add();
    p2.graphics.drawString('Page 2', PdfStandardFont(PdfFontFamily.helvetica, 12));
    final p3 = doc.pages.add();
    p3.graphics.drawString('Page 3', PdfStandardFont(PdfFontFamily.helvetica, 12));

    final bytes = doc.saveSync();
    doc.dispose();

    final original = PdfDocument(inputBytes: Uint8List.fromList(bytes));
    final reordered = PdfDocument();
    
    // Desired page order: [2, 0, 1]
    final order = [2, 0, 1];
    for (final idx in order) {
      final page = original.pages[idx];
      final template = page.createTemplate();
      final section = reordered.sections!.add();
      section.pageSettings.size = page.size;
      section.pageSettings.margins.all = 0;
      final newPage = section.pages.add();
      newPage.rotation = page.rotation;
      newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
    }
    
    final reorderedBytes = reordered.saveSync();
    original.dispose();
    reordered.dispose();

    final verify = PdfDocument(inputBytes: Uint8List.fromList(reorderedBytes));
    expect(verify.pages.count, 3);
    verify.dispose();
  });
}
