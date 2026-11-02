import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class SamplePdfGenerator {
  /// Generates a clean 3-page professional PDF document for immediate testing
  static Uint8List createSampleDocument() {
    final document = PdfDocument();
    document.documentInformation.title = 'FetchPDF Sample Document';
    document.documentInformation.author = 'FetchPDF Team';
    document.documentInformation.subject = 'Desktop PDF Editor Demonstration';
    document.documentInformation.keywords = 'FetchPDF, Windows, PDF, Editor';

    // Page 1: Welcome & Overview
    final page1 = document.pages.add();
    final fontTitle = PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
    final fontHeading = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final fontBody = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final fontItalic = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.italic);

    final brushPrimary = PdfSolidBrush(PdfColor(0, 120, 215));
    final brushDark = PdfSolidBrush(PdfColor(33, 33, 33));
    final brushGray = PdfSolidBrush(PdfColor(100, 100, 100));

    // Decorative top header bar
    page1.graphics.drawRectangle(
      brush: brushPrimary,
      bounds: const Rect.fromLTWH(0, 0, 500, 6),
    );

    page1.graphics.drawString(
      'FetchPDF Desktop',
      fontTitle,
      brush: brushPrimary,
      bounds: const Rect.fromLTWH(0, 25, 500, 35),
    );

    page1.graphics.drawString(
      'Phase 1 Core PDF Editor — Windows Desktop Platform',
      fontItalic,
      brush: brushGray,
      bounds: const Rect.fromLTWH(0, 60, 500, 20),
    );

    page1.graphics.drawString(
      '1. Overview & Capabilities',
      fontHeading,
      brush: brushDark,
      bounds: const Rect.fromLTWH(0, 95, 500, 25),
    );

    const bodyText1 =
        'Welcome to FetchPDF, a modern desktop PDF editor engineered specifically for Windows 10 and 11.\n\n'
        'This Phase 1 release includes high-performance vector rendering, multipage navigation, smooth continuous scrolling and zooming, and full document page manipulation.\n\n'
        'You can test the following features directly on this document:\n'
        '  • Select any text and copy it to the clipboard.\n'
        '  • Use the search tool in the toolbar to find terms.\n'
        '  • Add text box annotations with customizable font sizes and colors.\n'
        '  • Draw highlight and underline annotations over text.\n'
        '  • Use the pen tool to add freehand vector drawings.\n'
        '  • Rotate, reorder, or delete pages in the left thumbnail panel.\n'
        '  • Save your modifications and reopen to verify standard PDF persistence.';

    page1.graphics.drawString(
      bodyText1,
      fontBody,
      brush: brushDark,
      bounds: const Rect.fromLTWH(0, 125, 480, 220),
    );

    // Callout box
    page1.graphics.drawRectangle(
      brush: PdfSolidBrush(PdfColor(240, 246, 255)),
      pen: PdfPen(PdfColor(180, 210, 245), width: 1),
      bounds: const Rect.fromLTWH(0, 370, 480, 75),
    );

    page1.graphics.drawString(
      'Reliability & Document Integrity Guarantee',
      PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
      brush: brushPrimary,
      bounds: const Rect.fromLTWH(15, 382, 450, 20),
    );

    page1.graphics.drawString(
      'Your original documents are never modified until you explicitly choose "Save". '
      'FetchPDF implements full Undo/Redo tracking and warns you before closing unsaved tabs.',
      fontBody,
      brush: brushDark,
      bounds: const Rect.fromLTWH(15, 405, 450, 35),
    );

    // Page 2: Features & Architecture
    final page2 = document.pages.add();
    page2.graphics.drawString(
      '2. Feature Matrix & Tools',
      fontHeading,
      brush: brushPrimary,
      bounds: const Rect.fromLTWH(0, 25, 500, 25),
    );

    const bodyText2 =
        'Explore the rich toolbar at the top of the window:\n\n'
        '  1. Hand / Selection Tool: Select text or pan the canvas freely.\n'
        '  2. Text Box Tool: Click and drag or tap to insert standard FreeText annotations.\n'
        '  3. Highlight Tool: Highlight key phrases with semi-transparent markers.\n'
        '  4. Underline Tool: Underline critical passages and contracts.\n'
        '  5. Freehand Pen: Draw signatures, circles, and handwritten sketches.\n'
        '  6. Rectangle Tool: Draw bordered and filled boxes for emphasis.\n'
        '  7. Search Tool: Search full document text with occurrence counts and navigation.\n'
        '  8. Page Management: Reorder or rotate pages right from the sidebar.\n\n'
        'All annotations created in FetchPDF adhere strictly to standard PDF specifications, '
        'meaning they will appear identically in Adobe Acrobat, Microsoft Edge, and Chrome.';

    page2.graphics.drawString(
      bodyText2,
      fontBody,
      brush: brushDark,
      bounds: const Rect.fromLTWH(0, 60, 480, 250),
    );

    // Page 3: Summary & Verification
    final page3 = document.pages.add();
    page3.graphics.drawString(
      '3. Verification & Notes',
      fontHeading,
      brush: brushPrimary,
      bounds: const Rect.fromLTWH(0, 25, 500, 25),
    );

    const bodyText3 =
        'This third page is intentionally placed to allow testing:\n\n'
        '  • Page Deletion: Click the trash icon on this thumbnail to delete Page 3.\n'
        '  • Page Rotation: Rotate Page 3 by 90 degrees clockwise.\n'
        '  • Page Reordering: Move Page 3 up to become Page 1 or 2.\n'
        '  • Undo/Redo: Press Ctrl+Z to undo your change, and Ctrl+Y to redo it.\n\n'
        'Thank you for using FetchPDF!';

    page3.graphics.drawString(
      bodyText3,
      fontBody,
      brush: brushDark,
      bounds: const Rect.fromLTWH(0, 60, 480, 200),
    );

    final bytes = document.saveSync();
    document.dispose();
    return Uint8List.fromList(bytes);
  }
}
