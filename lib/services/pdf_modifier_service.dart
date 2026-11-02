import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/annotation_model.dart';
import '../models/document_tab.dart';

class PdfModifierService {
  /// Bakes all tab modifications (page rotations, reordering, deletions, and annotations)
  /// into a standard, fully compliant PDF file byte array.
  static Future<Uint8List> applyModifications(DocumentTab tab) async {
    // 1. Open the original base document
    PdfDocument sourceDoc;
    if (tab.password != null && tab.password!.isNotEmpty) {
      sourceDoc = PdfDocument(inputBytes: tab.pdfBytes, password: tab.password);
    } else {
      sourceDoc = PdfDocument(inputBytes: tab.pdfBytes);
    }

    try {
      // Create destination document
      final destDoc = PdfDocument();
      // Copy metadata
      destDoc.documentInformation.title = tab.metadata.title;
      destDoc.documentInformation.author = tab.metadata.author;
      destDoc.documentInformation.subject = tab.metadata.subject;
      destDoc.documentInformation.keywords = tab.metadata.keywords;

      // 2. Build pages according to tab.pages
      for (var targetPageIndex = 0; targetPageIndex < tab.pages.length; targetPageIndex++) {
        final pageInfo = tab.pages[targetPageIndex];
        final originalPageNum = pageInfo.pageNumber; // 1-indexed

        // Ensure original page exists in sourceDoc
        if (originalPageNum > sourceDoc.pages.count) continue;
        final srcPage = sourceDoc.pages[originalPageNum - 1];

        // Create template from source page
        final template = srcPage.createTemplate();
        final section = destDoc.sections!.add();
        section.pageSettings.size = srcPage.size;
        section.pageSettings.margins.all = 0;

        switch (pageInfo.rotationAngle) {
          case 90:
            section.pageSettings.rotate = PdfPageRotateAngle.rotateAngle90;
            break;
          case 180:
            section.pageSettings.rotate = PdfPageRotateAngle.rotateAngle180;
            break;
          case 270:
            section.pageSettings.rotate = PdfPageRotateAngle.rotateAngle270;
            break;
          case 0:
          default:
            section.pageSettings.rotate = PdfPageRotateAngle.rotateAngle0;
            break;
        }

        final newPage = section.pages.add();
        newPage.rotation = section.pageSettings.rotate;

        // Draw original content template onto new page
        newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));

        // 3. Bake annotations for this page (targetPageIndex + 1)
        final pageNumForAnnotations = targetPageIndex + 1;
        final pageAnnotations = tab.annotations.where((a) => a.pageNumber == pageNumForAnnotations);

        for (final annotation in pageAnnotations) {
          _bakeAnnotation(newPage, annotation);
        }
      }

      // Preserve password protection if original document had security
      if (tab.password != null && tab.password!.isNotEmpty) {
        destDoc.security.userPassword = tab.password!;
        destDoc.security.algorithm = PdfEncryptionAlgorithm.aesx128Bit;
      }

      final List<int> savedBytes = destDoc.saveSync();
      destDoc.dispose();
      return Uint8List.fromList(savedBytes);
    } finally {
      sourceDoc.dispose();
    }
  }

  static PdfColor _toPdfColor(Color c) {
    return PdfColor(
      (c.r * 255.0).round().clamp(0, 255),
      (c.g * 255.0).round().clamp(0, 255),
      (c.b * 255.0).round().clamp(0, 255),
      (c.a * 255.0).round().clamp(0, 255),
    );
  }

  static void _bakeAnnotation(PdfPage page, EditorAnnotation annotation) {
    final pageSize = page.size;
    final rect = annotation.toActualRect(Size(pageSize.width, pageSize.height));

    switch (annotation.type) {
      case AnnotationType.textBox:
        // Draw optional background if specified
        if (annotation.fillColor != null && annotation.fillColor!.a > 0.05) {
          page.graphics.drawRectangle(
            brush: PdfSolidBrush(_toPdfColor(annotation.fillColor!)),
            bounds: rect,
          );
        }

        // Draw text with accurate font, style, alignment and word wrapping
        if (annotation.text.isNotEmpty) {
          PdfFontFamily family = PdfFontFamily.helvetica;
          if (annotation.fontFamily.toLowerCase().contains('times')) {
            family = PdfFontFamily.timesRoman;
          } else if (annotation.fontFamily.toLowerCase().contains('courier')) {
            family = PdfFontFamily.courier;
          }

          PdfStandardFont font;
          if (annotation.isBold && annotation.isItalic) {
            font = PdfStandardFont(family, annotation.fontSize,
                multiStyle: <PdfFontStyle>[PdfFontStyle.bold, PdfFontStyle.italic]);
          } else if (annotation.isBold) {
            font = PdfStandardFont(family, annotation.fontSize, style: PdfFontStyle.bold);
          } else if (annotation.isItalic) {
            font = PdfStandardFont(family, annotation.fontSize, style: PdfFontStyle.italic);
          } else {
            font = PdfStandardFont(family, annotation.fontSize, style: PdfFontStyle.regular);
          }

          PdfTextAlignment alignment = PdfTextAlignment.left;
          if (annotation.alignment == TextAlign.center) {
            alignment = PdfTextAlignment.center;
          } else if (annotation.alignment == TextAlign.right) {
            alignment = PdfTextAlignment.right;
          }

          final format = PdfStringFormat(
            alignment: alignment,
            lineAlignment: PdfVerticalAlignment.top,
            wordWrap: PdfWordWrapType.word,
          );

          final textBounds = Rect.fromLTWH(
            rect.left + 2,
            rect.top + 2,
            rect.width > 4 ? rect.width - 4 : rect.width,
            rect.height > 4 ? rect.height - 4 : rect.height,
          );

          page.graphics.drawString(
            annotation.text,
            font,
            brush: PdfSolidBrush(_toPdfColor(annotation.color)),
            bounds: textBounds,
            format: format,
          );
        }
        break;

      case AnnotationType.existingText:
        // Whiteout original area
        page.graphics.drawRectangle(
          brush: PdfSolidBrush(PdfColor(255, 255, 255)),
          bounds: rect,
        );
        if (annotation.text.isNotEmpty) {
          PdfFontFamily family = PdfFontFamily.helvetica;
          if (annotation.fontFamily.toLowerCase().contains('times')) {
            family = PdfFontFamily.timesRoman;
          } else if (annotation.fontFamily.toLowerCase().contains('courier')) {
            family = PdfFontFamily.courier;
          }

          PdfStandardFont font;
          if (annotation.isBold && annotation.isItalic) {
            font = PdfStandardFont(family, annotation.fontSize,
                multiStyle: <PdfFontStyle>[PdfFontStyle.bold, PdfFontStyle.italic]);
          } else if (annotation.isBold) {
            font = PdfStandardFont(family, annotation.fontSize, style: PdfFontStyle.bold);
          } else if (annotation.isItalic) {
            font = PdfStandardFont(family, annotation.fontSize, style: PdfFontStyle.italic);
          } else {
            font = PdfStandardFont(family, annotation.fontSize, style: PdfFontStyle.regular);
          }

          PdfTextAlignment alignment = PdfTextAlignment.left;
          if (annotation.alignment == TextAlign.center) {
            alignment = PdfTextAlignment.center;
          } else if (annotation.alignment == TextAlign.right) {
            alignment = PdfTextAlignment.right;
          }

          final format = PdfStringFormat(
            alignment: alignment,
            lineAlignment: PdfVerticalAlignment.top,
            wordWrap: PdfWordWrapType.word,
          );

          final textBounds = Rect.fromLTWH(
            rect.left + 2,
            rect.top + 2,
            rect.width > 4 ? rect.width - 4 : rect.width,
            rect.height > 4 ? rect.height - 4 : rect.height,
          );

          page.graphics.drawString(
            annotation.text,
            font,
            brush: PdfSolidBrush(_toPdfColor(annotation.color)),
            bounds: textBounds,
            format: format,
          );
        }
        break;

      case AnnotationType.highlight:
        final markup = PdfTextMarkupAnnotation(
          rect,
          'Highlight',
          _toPdfColor(annotation.color),
        );
        markup.textMarkupAnnotationType = PdfTextMarkupAnnotationType.highlight;
        page.annotations.add(markup);
        break;

      case AnnotationType.underline:
        final markup = PdfTextMarkupAnnotation(
          rect,
          'Underline',
          _toPdfColor(annotation.color),
        );
        markup.textMarkupAnnotationType = PdfTextMarkupAnnotationType.underline;
        page.annotations.add(markup);
        break;

      case AnnotationType.strikethrough:
        final markup = PdfTextMarkupAnnotation(
          rect,
          'Strikethrough',
          _toPdfColor(annotation.color),
        );
        markup.textMarkupAnnotationType = PdfTextMarkupAnnotationType.strikethrough;
        page.annotations.add(markup);
        break;

      case AnnotationType.drawing:
        if (annotation.normalizedPoints.length >= 2) {
          final pen = PdfPen(
            _toPdfColor(annotation.color),
            width: annotation.strokeWidth,
          );
          for (var i = 0; i < annotation.normalizedPoints.length - 1; i++) {
            final p1 = Offset(
              annotation.normalizedPoints[i].dx * pageSize.width,
              annotation.normalizedPoints[i].dy * pageSize.height,
            );
            final p2 = Offset(
              annotation.normalizedPoints[i + 1].dx * pageSize.width,
              annotation.normalizedPoints[i + 1].dy * pageSize.height,
            );
            page.graphics.drawLine(pen, p1, p2);
          }
        }
        break;

      case AnnotationType.line:
        final pen = PdfPen(
          _toPdfColor(annotation.color),
          width: annotation.strokeWidth,
        );
        page.graphics.drawLine(pen, rect.topLeft, rect.bottomRight);
        break;

      case AnnotationType.arrow:
        final pen = PdfPen(
          _toPdfColor(annotation.color),
          width: annotation.strokeWidth,
        );
        page.graphics.drawLine(pen, rect.topLeft, rect.bottomRight);
        // Draw arrow head wings
        final dx = rect.bottomRight.dx - rect.topLeft.dx;
        final dy = rect.bottomRight.dy - rect.topLeft.dy;
        final angle = math.atan2(dy, dx);
        const arrowLength = 12.0;
        final wing1 = Offset(
          rect.bottomRight.dx - arrowLength * math.cos(angle - math.pi / 6),
          rect.bottomRight.dy - arrowLength * math.sin(angle - math.pi / 6),
        );
        final wing2 = Offset(
          rect.bottomRight.dx - arrowLength * math.cos(angle + math.pi / 6),
          rect.bottomRight.dy - arrowLength * math.sin(angle + math.pi / 6),
        );
        page.graphics.drawLine(pen, rect.bottomRight, wing1);
        page.graphics.drawLine(pen, rect.bottomRight, wing2);
        break;

      case AnnotationType.rectangle:
        final pen = PdfPen(
          _toPdfColor(annotation.color),
          width: annotation.strokeWidth,
        );
        PdfBrush? brush;
        if (annotation.fillColor != null && annotation.fillColor!.a > 0) {
          brush = PdfSolidBrush(_toPdfColor(annotation.fillColor!));
        }
        page.graphics.drawRectangle(pen: pen, brush: brush, bounds: rect);
        break;

      case AnnotationType.ellipse:
        final pen = PdfPen(
          _toPdfColor(annotation.color),
          width: annotation.strokeWidth,
        );
        PdfBrush? brush;
        if (annotation.fillColor != null && annotation.fillColor!.a > 0) {
          brush = PdfSolidBrush(_toPdfColor(annotation.fillColor!));
        }
        page.graphics.drawEllipse(rect, pen: pen, brush: brush);
        break;

      case AnnotationType.stickyNote:
        final noteBrush = PdfSolidBrush(PdfColor(255, 238, 140));
        final notePen = PdfPen(PdfColor(220, 180, 50), width: 1);
        page.graphics.drawRectangle(pen: notePen, brush: noteBrush, bounds: rect);
        if (annotation.text.isNotEmpty) {
          final font = PdfStandardFont(PdfFontFamily.helvetica, 9);
          final textBounds = Rect.fromLTWH(rect.left + 3, rect.top + 3, rect.width - 6, rect.height - 6);
          page.graphics.drawString(
            annotation.text,
            font,
            brush: PdfSolidBrush(PdfColor(40, 40, 40)),
            bounds: textBounds,
          );
        }
        break;

      case AnnotationType.stamp:
        final stampColor = _toPdfColor(annotation.color);
        final pen = PdfPen(stampColor, width: 2.5);
        page.graphics.drawRectangle(pen: pen, bounds: rect);
        final stampText = annotation.stampText.isNotEmpty ? annotation.stampText : (annotation.text.isNotEmpty ? annotation.text : 'APPROVED');
        final font = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
        final textBounds = Rect.fromLTWH(rect.left + 4, rect.top + (rect.height - 20) / 2, rect.width - 8, 20);
        page.graphics.drawString(
          stampText,
          font,
          brush: PdfSolidBrush(stampColor),
          bounds: textBounds,
        );
        break;

      case AnnotationType.image:
        final img = annotation.imageBytes;
        if (img != null && img.isNotEmpty) {
          try {
            final image = PdfBitmap(img);
            page.graphics.drawImage(image, rect);
          } catch (_) {}
        }
        break;
    }
  }
}
