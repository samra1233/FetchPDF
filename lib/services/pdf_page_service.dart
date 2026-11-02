import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfPageService {
  /// Rotates specific pages in the PDF by 90 degrees clockwise or counter-clockwise
  static Uint8List rotatePages({
    required Uint8List pdfBytes,
    required List<int> pageIndices,
    bool clockwise = true,
  }) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final count = document.pages.count;

    for (final index in pageIndices) {
      if (index >= 0 && index < count) {
        final page = document.pages[index];
        final currentRot = page.rotation;
        if (clockwise) {
          switch (currentRot) {
            case PdfPageRotateAngle.rotateAngle0:
              page.rotation = PdfPageRotateAngle.rotateAngle90;
              break;
            case PdfPageRotateAngle.rotateAngle90:
              page.rotation = PdfPageRotateAngle.rotateAngle180;
              break;
            case PdfPageRotateAngle.rotateAngle180:
              page.rotation = PdfPageRotateAngle.rotateAngle270;
              break;
            case PdfPageRotateAngle.rotateAngle270:
              page.rotation = PdfPageRotateAngle.rotateAngle0;
              break;
          }
        } else {
          switch (currentRot) {
            case PdfPageRotateAngle.rotateAngle0:
              page.rotation = PdfPageRotateAngle.rotateAngle270;
              break;
            case PdfPageRotateAngle.rotateAngle90:
              page.rotation = PdfPageRotateAngle.rotateAngle0;
              break;
            case PdfPageRotateAngle.rotateAngle180:
              page.rotation = PdfPageRotateAngle.rotateAngle90;
              break;
            case PdfPageRotateAngle.rotateAngle270:
              page.rotation = PdfPageRotateAngle.rotateAngle180;
              break;
          }
        }
      }
    }

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }

  /// Deletes multiple pages by index (sorted descending to maintain index validity)
  static Uint8List deletePages({
    required Uint8List pdfBytes,
    required List<int> pageIndices,
  }) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final sortedIndices = List<int>.from(pageIndices)..sort((a, b) => b.compareTo(a));

    for (final index in sortedIndices) {
      if (index >= 0 && index < document.pages.count && document.pages.count > 1) {
        document.pages.removeAt(index);
      }
    }

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }

  /// Duplicates a single page at index and inserts it right after
  static Uint8List duplicatePage({
    required Uint8List pdfBytes,
    required int pageIndex,
  }) {
    final document = PdfDocument(inputBytes: pdfBytes);
    if (pageIndex >= 0 && pageIndex < document.pages.count) {
      final template = document.pages[pageIndex].createTemplate();
      final originalSize = document.pages[pageIndex].size;
      final newPage = document.pages.insert(pageIndex + 1, originalSize);
      newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
    }

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }

  /// Reorders pages according to the provided index order
  static Uint8List reorderPages({
    required Uint8List pdfBytes,
    required List<int> newOrder,
  }) {
    final source = PdfDocument(inputBytes: pdfBytes);
    final output = PdfDocument();

    for (final oldIndex in newOrder) {
      if (oldIndex >= 0 && oldIndex < source.pages.count) {
        final srcPage = source.pages[oldIndex];
        final template = srcPage.createTemplate();
        final newPage = output.pages.add();
        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
        newPage.rotation = srcPage.rotation;
      }
    }

    final out = Uint8List.fromList(output.saveSync());
    source.dispose();
    output.dispose();
    return out;
  }

  /// Extracts specified pages into a brand new PDF document
  static Uint8List extractPages({
    required Uint8List pdfBytes,
    required List<int> pageIndices,
  }) {
    final source = PdfDocument(inputBytes: pdfBytes);
    final output = PdfDocument();

    for (final index in pageIndices) {
      if (index >= 0 && index < source.pages.count) {
        final srcPage = source.pages[index];
        final template = srcPage.createTemplate();
        final newPage = output.pages.add();
        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
        newPage.rotation = srcPage.rotation;
      }
    }

    final out = Uint8List.fromList(output.saveSync());
    source.dispose();
    output.dispose();
    return out;
  }

  /// Inserts a blank page at the given index
  static Uint8List insertBlankPage({
    required Uint8List pdfBytes,
    required int atIndex,
  }) {
    final document = PdfDocument(inputBytes: pdfBytes);
    final validIndex = atIndex.clamp(0, document.pages.count);
    document.pages.insert(validIndex);

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }

  /// Merges multiple PDF byte arrays in sequential order into a single PDF
  static Uint8List mergeDocuments(List<Uint8List> documents) {
    final output = PdfDocument();

    for (final docBytes in documents) {
      final inputDoc = PdfDocument(inputBytes: docBytes);
      for (int i = 0; i < inputDoc.pages.count; i++) {
        final srcPage = inputDoc.pages[i];
        final template = srcPage.createTemplate();
        final newPage = output.pages.add();
        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
        newPage.rotation = srcPage.rotation;
      }
      inputDoc.dispose();
    }

    final out = Uint8List.fromList(output.saveSync());
    output.dispose();
    return out;
  }

  /// Splits a document into multiple parts based on page ranges (e.g., [[0, 2], [3, 5]])
  static List<Uint8List> splitDocument({
    required Uint8List pdfBytes,
    required List<List<int>> ranges,
  }) {
    final List<Uint8List> results = [];
    final source = PdfDocument(inputBytes: pdfBytes);

    for (final range in ranges) {
      final part = PdfDocument();
      for (final pageIndex in range) {
        if (pageIndex >= 0 && pageIndex < source.pages.count) {
          final srcPage = source.pages[pageIndex];
          final template = srcPage.createTemplate();
          final newPage = part.pages.add();
          newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));
          newPage.rotation = srcPage.rotation;
        }
      }
      if (part.pages.count > 0) {
        results.add(Uint8List.fromList(part.saveSync()));
      }
      part.dispose();
    }

    source.dispose();
    return results;
  }
}
