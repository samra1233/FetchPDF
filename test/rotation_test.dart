import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('Test rotation on section vs page', () {
    final doc = PdfDocument();
    final sec = doc.sections!.add();
    sec.pageSettings.rotate = PdfPageRotateAngle.rotateAngle90;
    final page = sec.pages.add();
    page.graphics.drawString('Rotated Page', PdfStandardFont(PdfFontFamily.helvetica, 12));

    final bytes = doc.saveSync();
    doc.dispose();

    final loaded = PdfDocument(inputBytes: Uint8List.fromList(bytes));
    expect(loaded.pages[0].rotation, PdfPageRotateAngle.rotateAngle90);
    loaded.dispose();
  });
}
