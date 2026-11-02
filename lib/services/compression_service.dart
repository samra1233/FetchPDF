import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class CompressionResult {
  final Uint8List bytes;
  final int originalSizeBytes;
  final int compressedSizeBytes;

  const CompressionResult({
    required this.bytes,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
  });

  double get reductionPercentage {
    if (originalSizeBytes <= 0) return 0.0;
    final diff = originalSizeBytes - compressedSizeBytes;
    if (diff <= 0) return 0.0;
    return (diff / originalSizeBytes) * 100.0;
  }
}

enum CompressionLevel {
  low('Low (High Quality)'),
  medium('Balanced (Recommended)'),
  high('High (Maximum Compression)');

  final String label;
  const CompressionLevel(this.label);
}

class CompressionService {
  /// Compresses and optimizes a PDF document stream
  static CompressionResult compressPdf({
    required Uint8List pdfBytes,
    String? password,
    CompressionLevel level = CompressionLevel.medium,
  }) {
    final originalSize = pdfBytes.length;
    final document = password != null && password.isNotEmpty
        ? PdfDocument(inputBytes: pdfBytes, password: password)
        : PdfDocument(inputBytes: pdfBytes);

    // Set compression level on document settings
    document.compressionLevel = PdfCompressionLevel.best;

    // Save with highest compression
    final compressed = Uint8List.fromList(document.saveSync());
    document.dispose();

    final compressedSize = compressed.length;

    return CompressionResult(
      bytes: compressed,
      originalSizeBytes: originalSize,
      compressedSizeBytes: compressedSize,
    );
  }
}
