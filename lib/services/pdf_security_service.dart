import 'dart:typed_data';
import 'dart:ui';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfSecurityService {
  /// Encrypts a PDF with User password, Owner password, and permission flags
  static Uint8List protectPdf({
    required Uint8List pdfBytes,
    String? existingPassword,
    String? userPassword,
    String? ownerPassword,
    bool allowPrinting = true,
    bool allowCopy = true,
    bool allowAnnotations = true,
    bool allowFormEditing = true,
  }) {
    final document = existingPassword != null && existingPassword.isNotEmpty
        ? PdfDocument(inputBytes: pdfBytes, password: existingPassword)
        : PdfDocument(inputBytes: pdfBytes);
    final security = document.security;

    if (userPassword != null && userPassword.isNotEmpty) {
      security.userPassword = userPassword;
    }

    if (ownerPassword != null && ownerPassword.isNotEmpty) {
      security.ownerPassword = ownerPassword;
    }

    security.permissions.clear();
    if (allowPrinting) {
      security.permissions.add(PdfPermissionsFlags.print);
    }
    if (allowCopy) {
      security.permissions.add(PdfPermissionsFlags.copyContent);
    }
    if (allowAnnotations) {
      security.permissions.add(PdfPermissionsFlags.editAnnotations);
    }
    if (allowFormEditing) {
      security.permissions.add(PdfPermissionsFlags.fillFields);
    }

    security.algorithm = PdfEncryptionAlgorithm.aesx128Bit;

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }

  /// Removes passwords and security from a PDF (requires password if protected)
  static Uint8List removePassword({
    required Uint8List pdfBytes,
    required String password,
  }) {
    final document = PdfDocument(inputBytes: pdfBytes, password: password);
    document.security.userPassword = '';
    document.security.ownerPassword = '';
    document.security.permissions.clear();

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }

  /// Adds a text watermark across all pages in the PDF
  static Uint8List addWatermark({
    required Uint8List pdfBytes,
    String? password,
    required String text,
    double angle = 45.0,
    double opacity = 0.3,
    Color color = const Color(0xFFEF4444),
    double fontSize = 42.0,
  }) {
    final document = password != null && password.isNotEmpty
        ? PdfDocument(inputBytes: pdfBytes, password: password)
        : PdfDocument(inputBytes: pdfBytes);
    final font = PdfStandardFont(PdfFontFamily.helvetica, fontSize, style: PdfFontStyle.bold);
    final brush = PdfSolidBrush(PdfColor(
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
    ));

    for (int i = 0; i < document.pages.count; i++) {
      final page = document.pages[i];
      final graphics = page.graphics;
      final state = graphics.save();

      graphics.setTransparency(opacity);
      final size = page.size;
      graphics.translateTransform(size.width / 2, size.height / 2);
      graphics.rotateTransform(angle);

      final textSize = font.measureString(text);
      graphics.drawString(
        text,
        font,
        brush: brush,
        bounds: Rect.fromLTWH(-textSize.width / 2, -textSize.height / 2, textSize.width, textSize.height),
      );

      graphics.restore(state);
    }

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }

  /// Updates document metadata (Title, Author, Subject, Keywords)
  static Uint8List updateMetadata({
    required Uint8List pdfBytes,
    String? password,
    String? title,
    String? author,
    String? subject,
    String? keywords,
  }) {
    final document = password != null && password.isNotEmpty
        ? PdfDocument(inputBytes: pdfBytes, password: password)
        : PdfDocument(inputBytes: pdfBytes);

    if (title != null) document.documentInformation.title = title;
    if (author != null) document.documentInformation.author = author;
    if (subject != null) document.documentInformation.subject = subject;
    if (keywords != null) document.documentInformation.keywords = keywords;
    document.documentInformation.modificationDate = DateTime.now();

    final out = Uint8List.fromList(document.saveSync());
    document.dispose();
    return out;
  }
}
