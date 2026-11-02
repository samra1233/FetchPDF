import 'package:intl/intl.dart';

class DocumentMetadata {
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final int pageCount;
  final String title;
  final String author;
  final String subject;
  final String keywords;
  final String creator;
  final String producer;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final double pdfVersion;
  final bool isEncrypted;

  const DocumentMetadata({
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.pageCount,
    this.title = '',
    this.author = '',
    this.subject = '',
    this.keywords = '',
    this.creator = '',
    this.producer = '',
    this.creationDate,
    this.modificationDate,
    this.pdfVersion = 1.7,
    this.isEncrypted = false,
  });

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedCreationDate {
    if (creationDate == null) return 'Unknown';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(creationDate!);
  }

  String get formattedModificationDate {
    if (modificationDate == null) return 'Unknown';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(modificationDate!);
  }

  DocumentMetadata copyWith({
    String? fileName,
    String? filePath,
    int? fileSizeBytes,
    int? pageCount,
    String? title,
    String? author,
    String? subject,
    String? keywords,
    String? creator,
    String? producer,
    DateTime? creationDate,
    DateTime? modificationDate,
    double? pdfVersion,
    bool? isEncrypted,
  }) {
    return DocumentMetadata(
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      pageCount: pageCount ?? this.pageCount,
      title: title ?? this.title,
      author: author ?? this.author,
      subject: subject ?? this.subject,
      keywords: keywords ?? this.keywords,
      creator: creator ?? this.creator,
      producer: producer ?? this.producer,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      pdfVersion: pdfVersion ?? this.pdfVersion,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }
}
