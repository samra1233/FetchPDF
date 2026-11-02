import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/document_metadata.dart';
import '../models/document_tab.dart';
import '../models/page_info.dart';

class PdfPasswordRequiredException implements Exception {
  final String message;
  PdfPasswordRequiredException([this.message = 'Document is password protected']);
  @override
  String toString() => message;
}

class PdfDocumentService {
  /// Loads a PDF from a disk file path
  static Future<DocumentTab> loadFromFile(String filePath, {String? password}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', filePath);
    }
    final bytes = await file.readAsBytes();
    final fileName = p.basename(filePath);
    return parseDocument(bytes, fileName: fileName, filePath: filePath, password: password);
  }

  /// Parses raw PDF bytes into a DocumentTab model
  static DocumentTab parseDocument(
    Uint8List bytes, {
    required String fileName,
    String? filePath,
    String? password,
  }) {
    PdfDocument? document;
    try {
      if (password != null && password.isNotEmpty) {
        document = PdfDocument(inputBytes: bytes, password: password);
      } else {
        document = PdfDocument(inputBytes: bytes);
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('password') || errStr.contains('encrypted')) {
        throw PdfPasswordRequiredException();
      }
      rethrow;
    }

    try {
      final docInfo = document.documentInformation;
      final pageCount = document.pages.count;
      final fileSizeBytes = bytes.length;

      final metadata = DocumentMetadata(
        fileName: fileName,
        filePath: filePath ?? '',
        fileSizeBytes: fileSizeBytes,
        pageCount: pageCount,
        title: docInfo.title,
        author: docInfo.author,
        subject: docInfo.subject,
        keywords: docInfo.keywords,
        creator: docInfo.creator,
        producer: docInfo.producer,
        creationDate: docInfo.creationDate,
        modificationDate: docInfo.modificationDate,
        isEncrypted: password != null && password.isNotEmpty,
      );

      final pages = <PageInfo>[];
      for (var i = 0; i < pageCount; i++) {
        final page = document.pages[i];
        final size = Size(page.size.width, page.size.height);
        int angle = 0;
        switch (page.rotation) {
          case PdfPageRotateAngle.rotateAngle90:
            angle = 90;
            break;
          case PdfPageRotateAngle.rotateAngle180:
            angle = 180;
            break;
          case PdfPageRotateAngle.rotateAngle270:
            angle = 270;
            break;
          case PdfPageRotateAngle.rotateAngle0:
            angle = 0;
            break;
        }

        pages.add(PageInfo(
          pageNumber: i + 1,
          sizeInPoints: size,
          rotationAngle: angle,
        ));
      }

      final id = DateTime.now().microsecondsSinceEpoch.toString();
      return DocumentTab(
        id: id,
        fileName: fileName,
        filePath: filePath,
        pdfBytes: bytes,
        metadata: metadata,
        pages: pages,
        password: password,
      );
    } finally {
      document.dispose();
    }
  }
}
