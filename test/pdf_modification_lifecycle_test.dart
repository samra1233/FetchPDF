import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fetchpdf/models/annotation_model.dart';
import 'package:fetchpdf/services/pdf_document_service.dart';
import 'package:fetchpdf/services/pdf_modifier_service.dart';
import 'package:fetchpdf/services/sample_pdf_generator.dart';

void main() {
  test('Complete End-to-End PDF modification lifecycle: annotate, rotate, delete, reorder, undo/redo, bake & verify', () async {
    // 1. Generate base 3-page sample PDF bytes
    final baseBytes = SamplePdfGenerator.createSampleDocument();
    final tab = PdfDocumentService.parseDocument(baseBytes, fileName: 'TestDoc.pdf');

    expect(tab.pages.length, 3);
    expect(tab.isModified, false);

    // 2. Add Text Box Annotation
    final textBox = EditorAnnotation.createTextBox(
      id: 'ann-1',
      pageNumber: 1,
      normX: 0.1,
      normY: 0.2,
      normWidth: 0.4,
      normHeight: 0.05,
      text: 'Verified Text Box',
      fontSize: 14.0,
      color: Colors.blue,
      fillColor: const Color(0x33FFFF00),
    );
    tab.addAnnotation(textBox);
    expect(tab.annotations.length, 1);
    expect(tab.isModified, true);
    expect(tab.undoRedo.canUndo, true);

    // 3. Add Highlight Annotation
    final highlight = EditorAnnotation.createHighlight(
      id: 'ann-2',
      pageNumber: 1,
      normX: 0.1,
      normY: 0.3,
      normWidth: 0.5,
      normHeight: 0.03,
      color: const Color(0x66FFEB3B),
    );
    tab.addAnnotation(highlight);

    // 4. Add Underline Annotation
    final underline = EditorAnnotation.createUnderline(
      id: 'ann-3',
      pageNumber: 1,
      normX: 0.1,
      normY: 0.35,
      normWidth: 0.5,
      normHeight: 0.01,
      color: Colors.red,
    );
    tab.addAnnotation(underline);

    // 5. Add Freehand Ink Drawing Annotation
    final drawing = EditorAnnotation.createDrawing(
      id: 'ann-4',
      pageNumber: 1,
      normalizedPoints: [
        const Offset(0.1, 0.4),
        const Offset(0.2, 0.45),
        const Offset(0.3, 0.4),
      ],
      color: Colors.green,
      strokeWidth: 3.0,
    );
    tab.addAnnotation(drawing);

    // 6. Add Rectangle Annotation
    final rect = EditorAnnotation.createRectangle(
      id: 'ann-5',
      pageNumber: 1,
      normX: 0.1,
      normY: 0.5,
      normWidth: 0.3,
      normHeight: 0.1,
      color: Colors.purple,
    );
    tab.addAnnotation(rect);
    expect(tab.annotations.length, 5);

    // 7. Rotate Page 2 by 90 degrees
    tab.rotatePage(1, 90);
    expect(tab.pages[1].rotationAngle, 90);

    // 8. Delete Page 3
    tab.deletePage(2);
    expect(tab.pages.length, 2);

    // 9. Reorder Pages: Move Page 2 to index 0
    tab.reorderPage(1, 0);
    expect(tab.pages.length, 2);

    // 10. Test Undo and Redo
    tab.undoRedo.undo(); // Undo reorder
    expect(tab.pages[1].rotationAngle, 90);

    tab.undoRedo.redo(); // Redo reorder
    expect(tab.pages[0].rotationAngle, 90);

    // 11. Bake modifications into valid PDF bytes
    final modifiedBytes = await PdfModifierService.applyModifications(tab);
    expect(modifiedBytes.isNotEmpty, true);

    // 12. Re-open saved bytes and verify persistence
    final verifiedTab = PdfDocumentService.parseDocument(modifiedBytes, fileName: 'TestDoc_Saved.pdf');
    expect(verifiedTab.pages.length, 2);
    expect(verifiedTab.pages[0].rotationAngle, 90);

    tab.dispose();
    verifiedTab.dispose();
  });
}
