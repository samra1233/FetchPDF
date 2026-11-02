import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:fetchpdf/services/document_creation_service.dart';
import 'package:fetchpdf/services/pdf_page_service.dart';

void main() {
  late Uint8List testPdfBytes;

  setUpAll(() {
    testPdfBytes = DocumentCreationService.createNewDocument(
      size: PageSizePreset.a4,
      orientation: PageOrientationPreset.portrait,
      pattern: PagePatternPreset.blank,
      pageCount: 3,
      title: 'TestDocument.pdf',
    );
  });

  test('PdfPageService: duplicatePage increases page count', () {
    final duplicated = PdfPageService.duplicatePage(
      pdfBytes: testPdfBytes,
      pageIndex: 0,
    );
    final doc = PdfDocument(inputBytes: duplicated);
    expect(doc.pages.count, 4);
    doc.dispose();
  });

  test('PdfPageService: deletePages removes selected pages', () {
    final remaining = PdfPageService.deletePages(
      pdfBytes: testPdfBytes,
      pageIndices: [1],
    );
    final doc = PdfDocument(inputBytes: remaining);
    expect(doc.pages.count, 2);
    doc.dispose();
  });

  test('PdfPageService: insertBlankPage adds a new blank page', () {
    final withBlank = PdfPageService.insertBlankPage(
      pdfBytes: testPdfBytes,
      atIndex: 0,
    );
    final doc = PdfDocument(inputBytes: withBlank);
    expect(doc.pages.count, 4);
    doc.dispose();
  });

  test('PdfPageService: extractPages extracts selected page subset', () {
    final extracted = PdfPageService.extractPages(
      pdfBytes: testPdfBytes,
      pageIndices: [0, 2],
    );
    final doc = PdfDocument(inputBytes: extracted);
    expect(doc.pages.count, 2);
    doc.dispose();
  });

  test('PdfPageService: rotatePages rotates specific pages', () {
    final rotated = PdfPageService.rotatePages(
      pdfBytes: testPdfBytes,
      pageIndices: [0],
      clockwise: true,
    );
    final doc = PdfDocument(inputBytes: rotated);
    expect(doc.pages[0].rotation, PdfPageRotateAngle.rotateAngle90);
    doc.dispose();
  });

  test('PdfPageService: mergeDocuments joins multiple documents', () {
    final merged = PdfPageService.mergeDocuments([testPdfBytes, testPdfBytes]);
    final doc = PdfDocument(inputBytes: merged);
    expect(doc.pages.count, 6);
    doc.dispose();
  });

  test('PdfPageService: splitDocument splits by page ranges', () {
    final parts = PdfPageService.splitDocument(
      pdfBytes: testPdfBytes,
      ranges: [
        [0, 1],
        [2],
      ],
    );
    expect(parts.length, 2);
    final doc1 = PdfDocument(inputBytes: parts[0]);
    final doc2 = PdfDocument(inputBytes: parts[1]);
    expect(doc1.pages.count, 2);
    expect(doc2.pages.count, 1);
    doc1.dispose();
    doc2.dispose();
  });
}
