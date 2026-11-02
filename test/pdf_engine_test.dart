import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('Syncfusion PDF modifications: text, highlights, underlines, drawings, rotation, deletion, and save', () {
    // 1. Create a 3-page PDF
    final document = PdfDocument();
    final page1 = document.pages.add();
    final page2 = document.pages.add();
    final page3 = document.pages.add();

    // Draw some base text
    page1.graphics.drawString(
      'Page 1: Welcome to FetchPDF',
      PdfStandardFont(PdfFontFamily.helvetica, 18),
      bounds: const Rect.fromLTWH(50, 50, 400, 30),
    );

    page2.graphics.drawString(
      'Page 2: Original Content',
      PdfStandardFont(PdfFontFamily.helvetica, 18),
      bounds: const Rect.fromLTWH(50, 50, 400, 30),
    );

    page3.graphics.drawString(
      'Page 3: To Be Deleted',
      PdfStandardFont(PdfFontFamily.helvetica, 18),
      bounds: const Rect.fromLTWH(50, 50, 400, 30),
    );

    // Initial save
    final initialBytes = document.saveSync();
    document.dispose();

    // 2. Open the PDF again (simulating opening a real user PDF)
    final editDoc = PdfDocument(inputBytes: Uint8List.fromList(initialBytes));
    expect(editDoc.pages.count, 3);

    // 3. Insert new text on Page 1
    final editPage1 = editDoc.pages[0];
    editPage1.graphics.drawString(
      'Inserted Text Box Annotation',
      PdfStandardFont(PdfFontFamily.helvetica, 14),
      brush: PdfSolidBrush(PdfColor(0, 102, 204)),
      bounds: const Rect.fromLTWH(60, 120, 250, 25),
    );

    // 4. Add Highlight Annotation on Page 1
    final highlight = PdfTextMarkupAnnotation(
      const Rect.fromLTWH(50, 50, 300, 25),
      'Highlighted',
      PdfColor(255, 255, 0),
    );
    highlight.textMarkupAnnotationType = PdfTextMarkupAnnotationType.highlight;
    editPage1.annotations.add(highlight);

    // 5. Add Underline Annotation on Page 1
    final underline = PdfTextMarkupAnnotation(
      const Rect.fromLTWH(60, 120, 200, 20),
      'Underlined',
      PdfColor(255, 0, 0),
    );
    underline.textMarkupAnnotationType = PdfTextMarkupAnnotationType.underline;
    editPage1.annotations.add(underline);

    // 6. Add Polygon / Freehand Drawing Annotation on Page 1
    final drawing = PdfPolygonAnnotation(
      <int>[100, 200, 120, 220, 150, 210, 180, 240, 200, 200],
      'Ink Path',
      color: PdfColor(0, 180, 50),
    );
    editPage1.annotations.add(drawing);

    // 7. Add Rectangle Annotation on Page 1
    final rect = PdfRectangleAnnotation(
      const Rect.fromLTWH(50, 300, 200, 100),
      'Box Annotation',
      color: PdfColor(0, 120, 215),
    );
    editPage1.annotations.add(rect);

    // 8. Rotate Page 2
    editDoc.pages[1].rotation = PdfPageRotateAngle.rotateAngle90;

    // 9. Delete Page 3
    editDoc.pages.removeAt(2);

    expect(editDoc.pages.count, 2);

    // 10. Save modified PDF
    final modifiedBytes = editDoc.saveSync();
    editDoc.dispose();

    // 11. Reopen and verify persistence
    final verifiedDoc = PdfDocument(inputBytes: Uint8List.fromList(modifiedBytes));
    expect(verifiedDoc.pages.count, 2);
    expect(verifiedDoc.pages[1].rotation, PdfPageRotateAngle.rotateAngle90);
    expect(verifiedDoc.pages[0].annotations.count, 4);

    verifiedDoc.dispose();
  });
}
