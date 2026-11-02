import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:fetchpdf/services/compression_service.dart';
import 'package:fetchpdf/services/document_creation_service.dart';
import 'package:fetchpdf/services/pdf_security_service.dart';

void main() {
  test('PdfSecurityService: protectPdf encrypts PDF requiring password', () {
    final pdfBytes = DocumentCreationService.createNewDocument(
      size: PageSizePreset.a4,
      orientation: PageOrientationPreset.portrait,
      pattern: PagePatternPreset.blank,
      pageCount: 1,
      title: 'SecurityTest.pdf',
    );

    final protectedBytes = PdfSecurityService.protectPdf(
      pdfBytes: pdfBytes,
      userPassword: 'SecretPassword123',
    );

    // Opening without password throws an ArgumentError
    expect(
      () => PdfDocument(inputBytes: protectedBytes),
      throwsA(isA<ArgumentError>()),
    );

    // Opening with password succeeds
    final openedDoc = PdfDocument(inputBytes: protectedBytes, password: 'SecretPassword123');
    expect(openedDoc.pages.count, 1);
    openedDoc.dispose();

    // Remove password
    final decryptedBytes = PdfSecurityService.removePassword(
      pdfBytes: protectedBytes,
      password: 'SecretPassword123',
    );
    final decryptedDoc = PdfDocument(inputBytes: decryptedBytes);
    expect(decryptedDoc.pages.count, 1);
    decryptedDoc.dispose();

    // Re-encrypting with existing password succeeds
    final reProtectedBytes = PdfSecurityService.protectPdf(
      pdfBytes: protectedBytes,
      existingPassword: 'SecretPassword123',
      userPassword: 'NewPassword456',
    );
    final reOpenedDoc = PdfDocument(inputBytes: reProtectedBytes, password: 'NewPassword456');
    expect(reOpenedDoc.pages.count, 1);
    reOpenedDoc.dispose();
  });

  test('PdfSecurityService: addWatermark stamps text onto pages', () {
    final pdfBytes = DocumentCreationService.createNewDocument(
      size: PageSizePreset.a4,
      orientation: PageOrientationPreset.portrait,
      pattern: PagePatternPreset.blank,
      pageCount: 2,
      title: 'WatermarkTest.pdf',
    );

    final watermarkedBytes = PdfSecurityService.addWatermark(
      pdfBytes: pdfBytes,
      text: 'CONFIDENTIAL',
    );

    expect(watermarkedBytes.isNotEmpty, true);
    final doc = PdfDocument(inputBytes: watermarkedBytes);
    expect(doc.pages.count, 2);
    doc.dispose();
  });

  test('CompressionService: compressPdf executes stream compression and returns stats', () {
    final pdfBytes = DocumentCreationService.createNewDocument(
      size: PageSizePreset.a4,
      orientation: PageOrientationPreset.portrait,
      pattern: PagePatternPreset.grid,
      pageCount: 3,
      title: 'CompressTest.pdf',
    );

    final result = CompressionService.compressPdf(
      pdfBytes: pdfBytes,
      level: CompressionLevel.medium,
    );

    expect(result.originalSizeBytes, greaterThan(0));
    expect(result.bytes.isNotEmpty, true);
    expect(result.compressedSizeBytes, greaterThan(0));
  });
}
