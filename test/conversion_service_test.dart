import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fetchpdf/services/conversion_service.dart';
import 'package:fetchpdf/services/sample_pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List samplePdfBytes;
  late Directory tempDir;

  setUpAll(() async {
    samplePdfBytes = SamplePdfGenerator.createSampleDocument();
    tempDir = await Directory.systemTemp.createTemp('fetchpdf_conv_test_');
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('extractText extracts readable text from sample PDF', () {
    final text = ConversionService.extractText(samplePdfBytes);
    expect(text.isNotEmpty, isTrue);
    expect(text.contains('FetchPDF'), isTrue);
  });

  test('pdfToDocx converts PDF to valid .docx archive bytes', () {
    final docxBytes = ConversionService.pdfToDocx(samplePdfBytes);
    expect(docxBytes.isNotEmpty, isTrue);
    // Standard ZIP magic bytes PK\x03\x04
    expect(docxBytes[0], 0x50);
    expect(docxBytes[1], 0x4B);
  });

  test('pdfToExcel converts PDF to valid .xlsx archive bytes', () {
    final xlsxBytes = ConversionService.pdfToExcel(samplePdfBytes);
    expect(xlsxBytes.isNotEmpty, isTrue);
    // Standard ZIP magic bytes PK\x03\x04
    expect(xlsxBytes[0], 0x50);
    expect(xlsxBytes[1], 0x4B);
  });

  test('pdfToPpt converts PDF to valid .pptx archive bytes', () {
    final pptxBytes = ConversionService.pdfToPpt(samplePdfBytes);
    expect(pptxBytes.isNotEmpty, isTrue);
    // Standard ZIP magic bytes PK\x03\x04
    expect(pptxBytes[0], 0x50);
    expect(pptxBytes[1], 0x4B);
  });

  test('pdfToImages renders PDF pages to PNG files', () async {
    final paths = await ConversionService.pdfToImages(
      samplePdfBytes,
      outputDir: tempDir.path,
      baseName: 'test_doc',
    );
    expect(paths.isNotEmpty, isTrue);
    for (final p in paths) {
      final f = File(p);
      expect(f.existsSync(), isTrue);
      expect(f.lengthSync(), greaterThan(100));
    }
  });

  test('docxToPdf converts docx bytes to PDF', () {
    final docxBytes = ConversionService.pdfToDocx(samplePdfBytes);
    final pdfBytes = ConversionService.docxToPdf(docxBytes);
    expect(pdfBytes.isNotEmpty, isTrue);
    // PDF magic bytes %PDF
    expect(pdfBytes[0], 0x25); // %
    expect(pdfBytes[1], 0x50); // P
    expect(pdfBytes[2], 0x44); // D
    expect(pdfBytes[3], 0x46); // F
  });
}
