import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:fetchpdf/models/annotation_model.dart';
import 'package:fetchpdf/services/pdf_document_service.dart';
import 'package:fetchpdf/services/pdf_modifier_service.dart';
import 'package:fetchpdf/services/signature_service.dart';
import 'package:fetchpdf/state/editor_tab_controller.dart';
import 'package:fetchpdf/ui/widgets/status_bar.dart';

void main() {
  group('FetchPDF Professional Edit, Zoom & Signature Engine Tests', () {
    late Uint8List testPdfBytes;

    setUpAll(() {
      final doc = PdfDocument();
      doc.pages.add().graphics.drawString('FetchPDF Verification Document', PdfStandardFont(PdfFontFamily.helvetica, 12));
      testPdfBytes = Uint8List.fromList(doc.saveSync());
      doc.dispose();
    });

    test('SignatureService renders typed cursive signature to transparent PNG bytes', () async {
      final pngBytes = await SignatureService.renderTypedSignatureToPng(
        name: 'John Doe',
        textStyle: const TextStyle(fontSize: 32, fontStyle: FontStyle.italic, color: Color(0xFF1E293B)),
        canvasSize: const Size(360, 120),
      );

      expect(pngBytes, isNotNull);
      expect(pngBytes!.length, greaterThan(100));
      // First 8 bytes of PNG format: [137, 80, 78, 71, 13, 10, 26, 10]
      expect(pngBytes.sublist(0, 4), equals([137, 80, 78, 71]));
    });

    test('SignatureService renders drawn strokes to transparent PNG bytes', () async {
      final strokes = [
        [const Offset(10, 20), const Offset(50, 60), const Offset(100, 30)],
        [const Offset(20, 80), const Offset(90, 85)],
      ];

      final pngBytes = await SignatureService.renderSignatureToPng(
        strokes: strokes,
        canvasSize: const Size(300, 100),
        strokeColor: const Color(0xFF1D4ED8),
        strokeWidth: 3.0,
      );

      expect(pngBytes, isNotNull);
      expect(pngBytes!.length, greaterThan(100));
      expect(pngBytes.sublist(0, 4), equals([137, 80, 78, 71]));
    });

    test('addSignature places signature onto tab annotations and bakes into PDF', () async {
      final tab = PdfDocumentService.parseDocument(testPdfBytes, fileName: 'sign_test.pdf');
      final controller = EditorTabController(tab: tab);

      final pngBytes = await SignatureService.renderTypedSignatureToPng(
        name: 'Sarah Connor',
        textStyle: const TextStyle(fontSize: 28, fontStyle: FontStyle.italic),
        canvasSize: const Size(200, 80),
      );
      expect(pngBytes, isNotNull);

      controller.addSignature(pngBytes!);

      expect(tab.annotations.length, equals(1));
      final sigAnn = tab.annotations.first;
      expect(sigAnn.type, equals(AnnotationType.image));
      expect(sigAnn.imageBytes, isNotNull);
      expect(controller.selectedAnnotation?.id, equals(sigAnn.id));

      // Bake into PDF bytes
      final baked = await PdfModifierService.applyModifications(tab);
      expect(baked.length, greaterThan(testPdfBytes.length));

      controller.dispose();
    });

    test('EditorTabController Zoom In/Out/Set updates smoothly', () {
      final tab = PdfDocumentService.parseDocument(testPdfBytes, fileName: 'zoom_test.pdf');
      final controller = EditorTabController(tab: tab);

      expect(controller.zoomScale, equals(1.0));

      controller.setZoom(1.5);
      expect(controller.zoomScale, closeTo(1.5, 0.001));

      controller.setZoom(2.0);
      expect(controller.zoomScale, closeTo(2.0, 0.001));

      controller.setZoom(0.75);
      expect(controller.zoomScale, closeTo(0.75, 0.001));

      controller.resetZoom();
      expect(controller.zoomScale, closeTo(1.0, 0.001));

      controller.dispose();
    });

    testWidgets('BottomStatusBar rebuilds reactively on controller zoom and page changes', (tester) async {
      final tab = PdfDocumentService.parseDocument(testPdfBytes, fileName: 'bar_test.pdf');
      final controller = EditorTabController(tab: tab);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomStatusBar(tab: tab, controller: controller),
          ),
        ),
      );

      // Initially at 100%
      expect(find.text('100%'), findsOneWidget);

      // Update zoom via controller
      controller.setZoom(1.5);
      await tester.pumpAndSettle();

      // Bottom bar must now display 150%
      expect(find.text('150%'), findsOneWidget);

      controller.dispose();
    });

    test('Inline Text Box creation, moving, resizing, and typography changes', () {
      final tab = PdfDocumentService.parseDocument(testPdfBytes, fileName: 'text_test.pdf');
      final controller = EditorTabController(tab: tab);

      final textBox = EditorAnnotation.createTextBox(
        id: 'box_1',
        pageNumber: 1,
        normX: 0.1,
        normY: 0.1,
        normWidth: 0.3,
        normHeight: 0.05,
        text: 'Initial text block',
        fontSize: 14.0,
      );
      tab.addAnnotation(textBox);
      controller.selectAnnotation(textBox);

      // Verify initial selection
      expect(controller.selectedAnnotation?.text, equals('Initial text block'));

      // Move text box
      final moved = textBox.copyWith(normalizedX: 0.25, normalizedY: 0.35);
      tab.updateAnnotation(moved);
      controller.selectAnnotation(moved);
      expect(tab.annotations.first.normalizedX, closeTo(0.25, 0.001));
      expect(tab.annotations.first.normalizedY, closeTo(0.35, 0.001));

      // Resize text box
      final resized = moved.copyWith(normalizedWidth: 0.5, normalizedHeight: 0.1);
      tab.updateAnnotation(resized);
      controller.selectAnnotation(resized);
      expect(tab.annotations.first.normalizedWidth, closeTo(0.5, 0.001));
      expect(tab.annotations.first.normalizedHeight, closeTo(0.1, 0.001));

      // Update typography
      controller.setActiveFontSize(20.0);
      controller.setActiveFontFamily('Times');
      controller.toggleBold();

      expect(tab.annotations.first.fontSize, equals(20.0));
      expect(tab.annotations.first.fontFamily, equals('Times'));
      expect(tab.annotations.first.isBold, isTrue);

      // Delete text box
      controller.deleteSelectedAnnotation();
      expect(tab.annotations, isEmpty);
      expect(controller.selectedAnnotation, isNull);

      controller.dispose();
    });

    test('ToolMode selectText allows selection and deleteAnnotation helper works by ID', () {
      final tab = PdfDocumentService.parseDocument(testPdfBytes, fileName: 'select_test.pdf');
      final controller = EditorTabController(tab: tab);

      controller.setToolMode(EditorToolMode.selectText);
      expect(controller.toolMode, equals(EditorToolMode.selectText));

      final ann = EditorAnnotation.createTextBox(
        id: 'tb_test_99',
        pageNumber: 1,
        normX: 0.2,
        normY: 0.3,
        normWidth: 0.25,
        normHeight: 0.05,
        text: 'Hello FetchPDF',
      );
      tab.addAnnotation(ann);
      expect(tab.annotations.length, equals(1));

      tab.deleteAnnotation('tb_test_99');
      expect(tab.annotations.isEmpty, isTrue);

      controller.dispose();
    });
  });
}
