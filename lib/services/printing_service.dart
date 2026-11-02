import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

class PrintingService {
  /// Opens the native Windows Print dialog for the given PDF bytes.
  static Future<bool> printPdf(
    Uint8List pdfBytes, {
    String jobName = 'FetchPDF Document',
  }) async {
    try {
      return await Printing.layoutPdf(
        name: jobName,
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      debugPrint('Printing error: $e');
      return false;
    }
  }

  /// Direct print to a chosen printer if supported
  static Future<bool> directPrintPdf({
    required Printer printer,
    required Uint8List pdfBytes,
    String jobName = 'FetchPDF Document',
  }) async {
    try {
      return await Printing.directPrintPdf(
        printer: printer,
        name: jobName,
        onLayout: (format) async => pdfBytes,
      );
    } catch (e) {
      debugPrint('Direct print error: $e');
      return false;
    }
  }

  /// Lists available system printers
  static Future<List<Printer>> listPrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (_) {
      return [];
    }
  }
}
