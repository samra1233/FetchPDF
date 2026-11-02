import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:fetchpdf/models/annotation_model.dart';
import 'package:fetchpdf/services/pdf_document_service.dart';
import 'package:fetchpdf/services/pdf_modifier_service.dart';
import 'package:fetchpdf/state/editor_tab_controller.dart';

void main() {
  group('Extended Annotations, Viewport and Layering Tests', () {
    late Uint8List testPdfBytes;

    setUpAll(() {
      final doc = PdfDocument();
      doc.pages.add().graphics.drawString('Base Page for Extended Tests', PdfStandardFont(PdfFontFamily.helvetica, 12));
      testPdfBytes = Uint8List.fromList(doc.saveSync());
      doc.dispose();
    });

    test('All new annotation types bake cleanly into PDF bytes', () async {
      final tab = PdfDocumentService.parseDocument(testPdfBytes, fileName: 'extended_test.pdf');

      // Create dummy 1x1 image bytes
      final imgDoc = PdfDocument();
      imgDoc.pages.add();
      final dummyImgBytes = Uint8List.fromList(imgDoc.saveSync());
      imgDoc.dispose();

      // Add all new annotation types
      tab.addAnnotation(EditorAnnotation.createStrikethrough(
        id: 'ann_strike',
        pageNumber: 1,
        normX: 0.1,
        normY: 0.1,
        normWidth: 0.4,
        normHeight: 0.01,
      ));

      tab.addAnnotation(EditorAnnotation.createLine(
        id: 'ann_line',
        pageNumber: 1,
        normX: 0.1,
        normY: 0.2,
        normWidth: 0.5,
        normHeight: 0.1,
        strokeWidth: 3.0,
      ));

      tab.addAnnotation(EditorAnnotation.createArrow(
        id: 'ann_arrow',
        pageNumber: 1,
        normX: 0.1,
        normY: 0.35,
        normWidth: 0.4,
        normHeight: 0.05,
      ));

      tab.addAnnotation(EditorAnnotation.createEllipse(
        id: 'ann_ellipse',
        pageNumber: 1,
        normX: 0.2,
        normY: 0.5,
        normWidth: 0.3,
        normHeight: 0.15,
        fillColor: const Color(0x3300FF00),
      ));

      tab.addAnnotation(EditorAnnotation.createStickyNote(
        id: 'ann_note',
        pageNumber: 1,
        normX: 0.7,
        normY: 0.2,
        text: 'Review this section promptly',
        author: 'Lead Auditor',
      ));

      tab.addAnnotation(EditorAnnotation.createStamp(
        id: 'ann_stamp',
        pageNumber: 1,
        normX: 0.3,
        normY: 0.7,
        normWidth: 0.35,
        normHeight: 0.08,
        stampText: 'CONFIDENTIAL',
        color: const Color(0xFFD83B01),
      ));

      tab.addAnnotation(EditorAnnotation(
        id: 'ann_existing_text',
        pageNumber: 1,
        type: AnnotationType.existingText,
        normalizedX: 0.1,
        normalizedY: 0.85,
        normalizedWidth: 0.4,
        normalizedHeight: 0.05,
        text: 'Redacted and replaced text',
        color: Colors.black,
        fillColor: Colors.white,
        fontSize: 12,
      ));

      tab.addAnnotation(EditorAnnotation.createImage(
        id: 'ann_img',
        pageNumber: 1,
        normX: 0.5,
        normY: 0.5,
        normWidth: 0.2,
        normHeight: 0.2,
        imageBytes: dummyImgBytes,
      ));

      expect(tab.annotations.length, equals(8));

      // Bake into PDF stream
      final bakedBytes = await PdfModifierService.applyModifications(tab);
      expect(bakedBytes, isNotNull);
      expect(bakedBytes.length, greaterThan(testPdfBytes.length));

      // Re-open saved PDF with Syncfusion engine to verify compliance
      final reloaded = PdfDocument(inputBytes: bakedBytes);
      expect(reloaded.pages.count, equals(1));
      reloaded.dispose();
    });

    test('Layer ordering (bring forward / send backward) reorders annotations correctly', () {
      final tab = PdfDocumentService.parseDocument(testPdfBytes, fileName: 'ordering_test.pdf');

      final ann1 = EditorAnnotation.createTextBox(
        id: 'ann_1',
        pageNumber: 1,
        normX: 0.1,
        normY: 0.1,
        normWidth: 0.2,
        normHeight: 0.05,
        text: 'First',
      );
      final ann2 = EditorAnnotation.createTextBox(
        id: 'ann_2',
        pageNumber: 1,
        normX: 0.1,
        normY: 0.2,
        normWidth: 0.2,
        normHeight: 0.05,
        text: 'Second',
      );
      final ann3 = EditorAnnotation.createTextBox(
        id: 'ann_3',
        pageNumber: 1,
        normX: 0.1,
        normY: 0.3,
        normWidth: 0.2,
        normHeight: 0.05,
        text: 'Third',
      );

      tab.addAnnotation(ann1);
      tab.addAnnotation(ann2);
      tab.addAnnotation(ann3);

      expect(tab.annotations.map((a) => a.id).toList(), equals(['ann_1', 'ann_2', 'ann_3']));

      // Bring ann1 forward
      tab.bringAnnotationForward(ann1);
      expect(tab.annotations.map((a) => a.id).toList(), equals(['ann_2', 'ann_1', 'ann_3']));

      // Send ann3 backward
      tab.sendAnnotationBackward(ann3);
      expect(tab.annotations.map((a) => a.id).toList(), equals(['ann_2', 'ann_3', 'ann_1']));
    });

    test('EditorTabController tool modes and typography controls update smoothly', () {
      final tab = PdfDocumentService.parseDocument(testPdfBytes, fileName: 'ctrl_test.pdf');
      final controller = EditorTabController(tab: tab);

      // Verify default state
      expect(controller.toolMode, equals(EditorToolMode.hand));

      // Switch tool modes
      controller.setToolMode(EditorToolMode.strikethrough);
      expect(controller.toolMode, equals(EditorToolMode.strikethrough));

      controller.setToolMode(EditorToolMode.stamp);
      expect(controller.toolMode, equals(EditorToolMode.stamp));

      controller.setToolMode(EditorToolMode.eraser);
      expect(controller.toolMode, equals(EditorToolMode.eraser));

      // Typography controls
      controller.setActiveFontFamily('Courier');
      expect(controller.activeFontFamily, equals('Courier'));

      controller.toggleBold();
      expect(controller.activeIsBold, isTrue);

      controller.toggleItalic();
      expect(controller.activeIsItalic, isTrue);

      controller.setActiveAlignment(TextAlign.center);
      expect(controller.activeAlignment, equals(TextAlign.center));

      controller.setActiveStampText('DRAFT');
      expect(controller.activeStampText, equals('DRAFT'));

      controller.dispose();
    });
  });
}
